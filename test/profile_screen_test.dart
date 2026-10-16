import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phishwarden_movil/core/theme/app_theme.dart';
import 'package:phishwarden_movil/features/auth/data/models/link_models.dart';
import 'package:phishwarden_movil/features/profile/data/profile_repository.dart';
import 'package:phishwarden_movil/features/profile/presentation/profile_screen.dart';
import 'package:phishwarden_movil/features/profile/presentation/profile_view_model.dart';

const access = LinkResult(
  companyCode: 'PRUEBA',
  email: 'alumna@empresa.example',
  companyName: 'Empresa prueba',
  userId: 'user-1',
  isDemo: false,
);

class RecoveringProfileRepository implements ProfileRepository {
  int calls = 0;
  @override
  Future<EmployeeProfile> load() async {
    if (calls++ == 0) throw Exception('fallo de prueba');
    return const EmployeeProfile(
      email: 'alumna@empresa.example',
      companyName: 'Empresa prueba',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Las pruebas usan Ahem por defecto. Para QA cargamos fuentes reales del SDK.
    final configFile = File('.dart_tool/package_config.json');
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final flutterPackage = (config['packages'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((package) => package['name'] == 'flutter');
    final flutterUri = configFile.absolute.uri.resolve(
      flutterPackage['rootUri'] as String,
    );
    final fontsUri = Directory.fromUri(flutterUri).uri
        .resolve('../../bin/cache/artifacts/material_fonts/');
    for (final family in {
      'Roboto': ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf'],
      'MaterialIcons': ['materialicons-regular.otf'],
    }.entries) {
      final loader = FontLoader(family.key);
      for (final file in family.value) {
        loader.addFont(
          File.fromUri(fontsUri.resolve(file))
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      }
      await loader.load();
    }
  });
  test(
    'El perfil conserva identidad y no inventa riesgo ni resultados',
    () async {
      final result = await SessionProfileRepository(access).load();
      expect(result.email, access.email);
      expect(result.companyName, access.companyName);
      expect(result.name, isNull);
      expect(result.riskScore, isNull);
      expect(result.learningPoints, isNull);
      expect(result.safeDays, isNull);
      expect(result.simulationsReceived, isNull);
    },
  );

  test(
    'El ViewModel recupera el perfil al reintentar después de un fallo',
    () async {
      final model = ProfileViewModel(RecoveringProfileRepository());
      addTearDown(model.dispose);
      await model.load();
      expect(model.errorMessage, isNotNull);
      expect(model.isLoading, isFalse);
      await model.load();
      expect(model.errorMessage, isNull);
      expect(model.profile?.email, access.email);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Perfil ${mode.name}: diseño, acciones y cambio de tema', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final themeMode = ValueNotifier(mode);
      addTearDown(themeMode.dispose);
      var lessons = 0;
      var training = 0;
      var logout = 0;
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('profileCapture'),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (context, value, _) => MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: value,
              debugShowCheckedModeBanner: false,
              home: ProfileScreen(
                repository: SessionProfileRepository(access),
                themeMode: themeMode,
                onThemeChanged: (value) => themeMode.value = value,
                onLesson: () => lessons++,
                onTraining: () => training++,
                onLogout: () => logout++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text(access.email), findsOneWidget);
      expect(find.text('Sin datos'), findsNWidgets(2));
      expect(find.text('42'), findsNothing);
      expect(find.text('850 pts'), findsNothing);
      expect(
        tester
            .widget<NavigationDestination>(
              find.widgetWithText(NavigationDestination, 'Ranking'),
            )
            .enabled,
        isFalse,
      );
      expect(tester.takeException(), isNull);

      // Imágenes de QA: datos ficticios de test, fuera del recorrido real.
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('profileCapture')),
        );
        final capture = await boundary.toImage(pixelRatio: 1);
        final bytes = await capture.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/qa').create(recursive: true);
        await File('build/qa/profile_${mode.name}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        capture.dispose();
      });

      await tester.ensureVisible(find.text('Reconoce un correo de phishing'));
      await tester.tap(find.text('Reconoce un correo de phishing'));
      expect(lessons, 1);
      await tester.tap(find.text('Capacitación'));
      expect(training, 1);
      await tester.ensureVisible(find.byTooltip('Ajustes'));
      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      final target = mode == ThemeMode.light ? 'Oscuro' : 'Claro';
      await tester.tap(find.widgetWithText(ChoiceChip, target));
      await tester.pumpAndSettle();
      expect(
        themeMode.value,
        mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(logout, 1);
    });
  }

  testWidgets(
    'Perfil admite pantalla pequeña y texto ampliado sin desbordarse',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final mode = ValueNotifier(ThemeMode.light);
      addTearDown(mode.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: ProfileScreen(
            repository: SessionProfileRepository(access),
            themeMode: mode,
            onThemeChanged: (_) {},
            onLesson: () {},
            onTraining: () {},
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tus medallas'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
