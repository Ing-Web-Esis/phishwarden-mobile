import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phishwarden_movil/app/app.dart';
import 'package:phishwarden_movil/core/network/api_client.dart';
import 'package:phishwarden_movil/core/notifications/notification_service.dart';

import 'training_test.dart' show lessonJson, resultJson, tapVisible;

void main() {
  for (final fromNotification in [false, true]) {
    testWidgets(
      'Recorrido autenticado y actualización (notificación: $fromNotification)',
      (tester) async {
        var evaluated = false, profileLoads = 0, detailLoads = 0;
        final notifications = NotificationService();
        addTearDown(notifications.pendingLesson.dispose);
        if (fromNotification) notifications.pendingLesson.value = '17';
        final api = ApiClient(
          baseUrl: 'http://localhost:3000',
          client: MockClient((req) async {
            final path = req.url.path;
            if (path != '/mobile/auth/vincular') {
              expect(req.headers['Authorization'], 'Bearer test-token');
            }
            if (path == '/mobile/perfil') profileLoads++;
            if (path == '/mobile/lecciones/17') detailLoads++;
            if (path == '/mobile/lecciones/17/evaluar') evaluated = true;
            final Object data = switch (path) {
              '/mobile/auth/vincular' => {
                'accessToken': 'test-token',
                'usuario': {
                  'id': 'user-1',
                  'correoCorporativo': 'test@example.com',
                  'empresa': {'id': 1, 'nombre': 'Empresa prueba'},
                },
              },
              '/mobile/perfil' => {
                'nombre': 'Colaborador',
                'scoreRiesgo': evaluated ? 28 : 38,
                'puntosTotales': evaluated ? 50 : 40,
                'rachaDiasSeguros': 2,
              },
              '/mobile/lecciones' => {
                'asignadasPendientes': evaluated ? [] : [lessonJson],
                'catalogoDisponible': [],
                'completadas': evaluated
                    ? [
                        {...lessonJson, 'estado': 'completada'},
                      ]
                    : [],
              },
              '/mobile/lecciones/17' => lessonJson,
              '/mobile/lecciones/17/evaluar' => resultJson,
              '/mobile/medallas' => {'puntosTotales': 50, 'medallas': []},
              '/mobile/ranking' => {
                'miPosicion': 1,
                'ranking': [
                  {
                    'posicion': 1,
                    'nombre': 'Colaborador',
                    'puntosTotales': evaluated ? 50 : 40,
                    'medallasCount': 0,
                    'rachaDiasSeguros': 2,
                    'esUsuarioActual': true,
                  },
                ],
              },
              _ => throw StateError('Unexpected $path'),
            };
            return http.Response(
              jsonEncode(data),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        await tester.pumpWidget(
          PhishWardenApp(apiClient: api, notifications: notifications),
        );
        await tester.pumpAndSettle();
        expect(detailLoads, 0);
        await tester.enterText(
          find.byKey(const Key('companyCode')),
          'SALA2026',
        );
        await tester.enterText(
          find.byKey(const Key('corporateEmail')),
          'test@example.com',
        );
        await tapVisible(tester, find.byKey(const Key('linkButton')));
        if (!fromNotification) {
          await tapVisible(tester, find.text('Ranking'));
          await tapVisible(tester, find.text('Capacitación'));
          await tapVisible(
            tester,
            find.text('Detecta un correo falso').hitTestable(),
          );
        }
        expect(detailLoads, 1);
        await tester.scrollUntilVisible(
          find.text('Ir al quiz de refuerzo'),
          250,
        );
        await tapVisible(tester, find.text('Ir al quiz de refuerzo'));
        await tapVisible(
          tester,
          find.text(
            'B. Verificar con TI por un canal conocido, sin abrir el enlace.',
          ),
        );
        await tapVisible(tester, find.text('Comprobar respuesta'));
        expect(evaluated, true);
        await tapVisible(tester, find.text('Volver a mi perfil'));
        expect(find.text('Mi perfil').hitTestable(), findsOneWidget);
        expect(find.text('50 pts'), findsOneWidget);
        expect(profileLoads, 2);
        await tapVisible(tester, find.text('Capacitación'));
        expect(find.text('1 de 1 lecciones completadas'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
