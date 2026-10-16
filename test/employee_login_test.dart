import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phishwarden_movil/app/app.dart';
import 'package:phishwarden_movil/core/network/api_client.dart';
import 'package:phishwarden_movil/features/auth/data/api_auth_repository.dart';

void main() {
  testWidgets(
    'Ingreso exitoso muestra la empresa y Salir limpia el formulario',
    (tester) async {
      final api = ApiClient(
        baseUrl: 'http://localhost:3000',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'empresa': 'Empresa prueba',
              'user': {'id': 'user-1', 'email': 'alumna@example.com'},
            }),
            201,
          ),
        ),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        PhishWardenApp(repository: ApiAuthRepository(api)),
      );
      await tester.enterText(find.byKey(const Key('companyCode')), 'SALA2026');
      await tester.enterText(
        find.byKey(const Key('corporateEmail')),
        'alumna@example.com',
      );
      await tester.ensureVisible(find.byKey(const Key('linkButton')));
      await tester.tap(find.byKey(const Key('linkButton')));
      await tester.pumpAndSettle();
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Empresa prueba'), findsOneWidget);
      expect(find.text('alumna@example.com'), findsOneWidget);
      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Mi perfil'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('corporateEmail')))
            .controller!
            .text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ingreso rechazado conserva el formulario y muestra el error', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'El correo no pertenece a esta empresa o no es un empleado válido',
          }),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(api.close);
    await tester.pumpWidget(PhishWardenApp(repository: ApiAuthRepository(api)));
    await tester.enterText(find.byKey(const Key('companyCode')), 'SALA2026');
    await tester.enterText(
      find.byKey(const Key('corporateEmail')),
      'alumna@example.com',
    );
    await tester.ensureVisible(find.byKey(const Key('linkButton')));
    await tester.tap(find.byKey(const Key('linkButton')));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsNothing);
    expect(
      find.text(
        'El correo no pertenece a esta empresa o no es un empleado válido',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('companyCode')))
          .controller!
          .text,
      'SALA2026',
    );
  });
}
