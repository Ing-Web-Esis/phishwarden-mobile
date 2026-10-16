import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:phishwarden_movil/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('TEST_EMPLOYEE_EMAIL');
  const code = String.fromEnvironment('TEST_COMPANY_CODE');

  testWidgets('Android valida un empleado con NestJS y permite salir', (
    tester,
  ) async {
    expect(
      email,
      isNotEmpty,
      reason: 'Configura TEST_EMPLOYEE_EMAIL para una cuenta existente.',
    );
    expect(
      code,
      isNotEmpty,
      reason: 'Configura TEST_COMPANY_CODE para su empresa.',
    );
    await tester.pumpWidget(const PhishWardenApp());
    await tester.enterText(find.byKey(const Key('companyCode')), code);
    await tester.enterText(find.byKey(const Key('corporateEmail')), email);
    await tester.ensureVisible(find.byKey(const Key('linkButton')));
    await tester.tap(find.byKey(const Key('linkButton')));
    // La red de Android es real: esperamos el cambio de pantalla con límite.
    for (
      var attempt = 0;
      attempt < 80 && find.text('Mi perfil').evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text(email), findsOneWidget);
    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('companyCode')), findsOneWidget);
    expect(find.text('Mi perfil'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('companyCode')),
      'NO-EXISTE-PW',
    );
    await tester.enterText(find.byKey(const Key('corporateEmail')), email);
    await tester.ensureVisible(find.byKey(const Key('linkButton')));
    await tester.tap(find.byKey(const Key('linkButton')));
    for (
      var attempt = 0;
      attempt < 80 &&
          find.text('Código de empresa o sala inválido').evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
    expect(find.text('Código de empresa o sala inválido'), findsOneWidget);
    expect(find.text('Mi perfil'), findsNothing);
  });
}
