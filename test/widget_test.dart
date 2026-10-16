import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phishwarden_movil/app/app.dart';
import 'package:phishwarden_movil/features/auth/data/mock_auth_repository.dart';

void main() {
  testWidgets('Valida campos y completa una vinculación de demostración', (
    tester,
  ) async {
    await tester.pumpWidget(
      PhishWardenApp(repository: MockAuthRepository(delay: Duration.zero)),
    );
    final button = find.byKey(const Key('linkButton'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(
      find.text('Ingresa el código de tu sala o empresa.'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('companyCode')), 'NOVA-2026');
    await tester.enterText(
      find.byKey(const Key('corporateEmail')),
      'lucia@nova.example',
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('¡Prueba completada!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cambiar de tema conserva el formulario', (tester) async {
    await tester.pumpWidget(const PhishWardenApp());
    await tester.enterText(find.byKey(const Key('companyCode')), 'NOVA-2026');
    await tester.ensureVisible(find.byTooltip('Cambiar apariencia'));
    await tester.tap(find.byTooltip('Cambiar apariencia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscuro').last);
    await tester.pumpAndSettle();
    expect(find.text('NOVA-2026'), findsWidgets);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
