import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phishwarden_movil/core/network/api_client.dart';
import 'package:phishwarden_movil/core/theme/app_theme.dart';
import 'package:phishwarden_movil/features/auth/data/models/link_models.dart';
import 'package:phishwarden_movil/features/training/data/training_repository.dart';
import 'package:phishwarden_movil/features/training/presentation/training_lesson_screen.dart';
import 'package:phishwarden_movil/features/training/presentation/training_lesson_view_model.dart';
import 'package:phishwarden_movil/features/training/presentation/training_screen.dart';

const lessonJson = {
  'id': 17,
  'titulo': 'Detecta un correo falso',
  'metodoAtaque': 'phishing',
  'duracionMinutos': 2,
  'estado': 'pendiente',
  'contenidoMultimedia': null,
  'preguntas': [
    {
      'id': 31,
      'enunciado': '¿Qué deberías hacer antes de actuar sobre este correo?',
      'opcionA': 'Abrir el enlace y confirmar mi cuenta cuanto antes.',
      'opcionB': 'Verificar con TI por un canal conocido, sin abrir el enlace.',
      'opcionC': 'Responder al remitente con mis datos para pedir ayuda.',
      'opcionD': '',
    },
  ],
};
const resultJson = {
  'aprobado': true,
  'correctas': 1,
  'totalPreguntas': 1,
  'puntosGanados': 10,
  'puntosTotales': 50,
  'scoreRiesgoActualizado': 28,
  'nuevasMedallasDesbloqueadas': <Map<String, Object>>[],
};

class FakeTraining implements TrainingRepository {
  bool multipleQuestions = false;
  bool failLoad = false, failSubmit = false;
  int submissions = 0;
  Completer<TrainingResult>? pending;
  @override
  Future<List<TrainingLesson>> load() async {
    if (failLoad) throw Exception('offline');
    return [
      TrainingLesson.fromJson(lessonJson),
      TrainingLesson.fromJson({
        ...lessonJson,
        'id': 18,
        'titulo': 'Lección completada',
        'estado': 'completada',
      }),
    ];
  }

  @override
  Future<TrainingLesson> detail(int id) async {
    if (failLoad) throw Exception('offline');
    return TrainingLesson.fromJson({
      ...lessonJson,
      if (multipleQuestions)
        'preguntas': [
          ...(lessonJson['preguntas'] as List),
          {
            'id': 32,
            'enunciado': 'Segunda pregunta',
            'opcionA': 'Opción siguiente',
            'opcionB': 'Otra opción',
          },
        ],
    });
  }

  @override
  Future<TrainingResult> evaluate(int id, Map<int, String> answers) async {
    submissions++;
    if (failSubmit) throw const ApiFailure('offline');
    if (pending != null) return pending!.future;
    return TrainingResult.fromJson({
      ...resultJson,
      'aprobado': answers[31] == 'B',
      'correctas': answers[31] == 'B' ? 1 : 0,
    });
  }
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/qa').create(recursive: true);
    await File('build/qa/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> loadQaFonts() async {
  final configFile = File('.dart_tool/package_config.json');
  final config =
      jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
  final flutter = (config['packages'] as List)
      .cast<Map<String, dynamic>>()
      .singleWhere((p) => p['name'] == 'flutter');
  final fontRoot = Directory.fromUri(
    configFile.absolute.uri.resolve(flutter['rootUri'] as String),
  ).uri.resolve('../../bin/cache/artifacts/material_fonts/');
  for (final family in {
    'Roboto': ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf'],
    'MaterialIcons': ['materialicons-regular.otf'],
  }.entries) {
    final loader = FontLoader(family.key);
    for (final name in family.value) {
      loader.addFont(
        File.fromUri(fontRoot.resolve(name))
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      );
    }
    await loader.load();
  }
}

void main() {
  test(
    'Contrato real: grupos, JWT, preguntas y envío de alternativas',
    () async {
      final requests = <http.Request>[];
      final api = ApiClient(
        baseUrl: 'https://api.example',
        client: MockClient((req) async {
          requests.add(req);
          expect(req.headers['Authorization'], 'Bearer employee-token');
          final Object data = switch (req.url.path) {
            '/mobile/lecciones' => {
              'asignadasPendientes': [lessonJson],
              'catalogoDisponible': [],
              'completadas': [],
            },
            '/mobile/lecciones/17' => {
              ...lessonJson,
              'estadoUsuario': 'pendiente',
            },
            '/mobile/lecciones/17/evaluar' => resultJson,
            _ => throw StateError('Unexpected route'),
          };
          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      final repo = HttpTrainingRepository(
        api,
        const LinkResult(
          companyCode: 'test',
          email: 'test@example.com',
          isDemo: false,
          accessToken: 'employee-token',
        ),
      );
      expect((await repo.load()).single.id, 17);
      expect((await repo.detail(17)).questions.single.options.keys, [
        'A',
        'B',
        'C',
      ]);
      final result = await repo.evaluate(17, {31: 'B'});
      expect(result.points, 10);
      expect(result.risk, 28);
      expect(requests.last.method, 'POST');
      expect(jsonDecode(requests.last.body), {
        'respuestas': [
          {'preguntaId': 31, 'respuestaSeleccionada': 'B'},
        ],
      });
    },
  );

  test(
    'No envía incompleto, bloquea doble envío y conserva respuestas tras error',
    () async {
      final repo = FakeTraining();
      final vm = TrainingLessonViewModel(repo, 17);
      addTearDown(vm.dispose);
      await vm.load();
      expect(await vm.submit(), false);
      expect(repo.submissions, 0);
      vm.select(99, 'B');
      vm.select(31, 'D');
      expect(vm.answers, isEmpty);
      vm.select(31, 'B');
      repo.failSubmit = true;
      expect(await vm.submit(), false);
      expect(vm.answers[31], 'B');
      expect(vm.result, isNull);
      repo.failSubmit = false;
      repo.pending = Completer<TrainingResult>();
      final first = vm.submit();
      expect(await vm.submit(), false);
      vm.select(31, 'A');
      expect(vm.answers[31], 'B');
      repo.pending!.complete(TrainingResult.fromJson(resultJson));
      expect(await first, true);
      expect(repo.submissions, 2);
      expect(await vm.submit(), false);
    },
  );

  test('Carga terminada después de dispose no notifica', () async {
    final vm = TrainingLessonViewModel(FakeTraining(), 17);
    final loading = vm.load();
    vm.dispose();
    await loading;
  });

  for (final dark in [false, true]) {
    testWidgets('Recorrido phishing y capturas ${dark ? 'oscuro' : 'claro'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadQaFonts);
      final key = GlobalKey();
      var evaluated = 0, profile = 0;
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: TrainingLessonScreen(
              id: 17,
              repository: FakeTraining(),
              onEvaluated: () => evaluated++,
              onProfile: () => profile++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Detecta un correo falso'), findsOneWidget);
      await capture(tester, key, 'phishing_lesson_${dark ? 'dark' : 'light'}');
      await tester.scrollUntilVisible(find.text('Ir al quiz de refuerzo'), 250);
      await tapVisible(tester, find.text('Ir al quiz de refuerzo'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Comprobar respuesta'),
            )
            .onPressed,
        isNull,
      );
      await tapVisible(
        tester,
        find.text(
          'B. Verificar con TI por un canal conocido, sin abrir el enlace.',
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, key, 'phishing_quiz_${dark ? 'dark' : 'light'}');
      await tester.ensureVisible(find.text('Comprobar respuesta'));
      await tapVisible(tester, find.text('Comprobar respuesta'));
      await tester.pumpAndSettle();
      expect(evaluated, 1);
      expect(find.text('+10 puntos'), findsOneWidget);
      expect(find.text('28 /100 · Bajo'), findsOneWidget);
      await capture(tester, key, 'phishing_result_${dark ? 'dark' : 'light'}');
      await tester.ensureVisible(find.text('Volver a mi perfil'));
      await tapVisible(tester, find.text('Volver a mi perfil'));
      expect(profile, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Centro filtra lecciones, reintenta y abre el ID correcto', (
    tester,
  ) async {
    final repo = FakeTraining()..failLoad = true;
    int? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TrainingScreen(repository: repo, onLesson: (id) => opened = id),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tus microlecciones.'), findsOneWidget);
    repo.failLoad = false;
    await tapVisible(tester, find.text('Reintentar'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Completadas'));
    await tester.pumpAndSettle();
    expect(find.text('Detecta un correo falso'), findsNothing);
    await tapVisible(tester, find.text('Pendientes · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Lección completada'), findsNothing);
    await tapVisible(tester, find.text('Detecta un correo falso'));
    expect(opened, 17);
  });

  testWidgets('Fallo de evaluación permite reintentar sin perder selección', (
    tester,
  ) async {
    final repo = FakeTraining()..failSubmit = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TrainingLessonScreen(
          id: 17,
          repository: repo,
          onEvaluated: () {},
          onProfile: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ir al quiz de refuerzo'), 250);
    await tapVisible(tester, find.text('Ir al quiz de refuerzo'));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.text('A. Abrir el enlace y confirmar mi cuenta cuanto antes.'),
    );
    await tester.ensureVisible(find.text('Comprobar respuesta'));
    await tapVisible(tester, find.text('Comprobar respuesta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tus respuestas se conservan'), findsOneWidget);
    expect(find.text('Seleccionada'), findsOneWidget);
    repo.failSubmit = false;
    await tester.ensureVisible(find.text('Comprobar respuesta'));
    await tapVisible(tester, find.text('Comprobar respuesta'));
    await tester.pumpAndSettle();
    expect(find.text('Sigamos aprendiendo'), findsOneWidget);
    await tester.ensureVisible(find.text('Repasar y volver a intentar'));
    await tapVisible(tester, find.text('Repasar y volver a intentar'));
    await tester.pumpAndSettle();
    expect(find.text('Microlección'), findsOneWidget);
  });

  testWidgets('Varias preguntas en pantalla pequeña con texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeTraining()..multipleQuestions = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: TrainingLessonScreen(
          id: 17,
          repository: repo,
          onEvaluated: () {},
          onProfile: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ir al quiz de refuerzo'), 250);
    await tapVisible(tester, find.text('Ir al quiz de refuerzo'));
    await tester.pumpAndSettle();
    final answer = find.text(
      'B. Verificar con TI por un canal conocido, sin abrir el enlace.',
    );
    await tester.scrollUntilVisible(answer, 200);
    await tapVisible(tester, answer);
    await tester.scrollUntilVisible(find.text('Siguiente pregunta'), 200);
    await tapVisible(tester, find.text('Siguiente pregunta'));
    await tester.pumpAndSettle();
    expect(find.text('Pregunta 2 de 2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('A. Opción siguiente'), 200);
    await tapVisible(tester, find.text('A. Opción siguiente'));
    await tester.scrollUntilVisible(find.text('Comprobar respuesta'), 200);
    await tapVisible(tester, find.text('Comprobar respuesta'));
    await tester.pumpAndSettle();
    expect(repo.submissions, 1);
    expect(tester.takeException(), isNull);
  });
}
