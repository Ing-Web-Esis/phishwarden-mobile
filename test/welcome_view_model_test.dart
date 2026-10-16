import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:phishwarden_movil/features/auth/data/auth_repository.dart';
import 'package:phishwarden_movil/features/auth/data/mock_auth_repository.dart';
import 'package:phishwarden_movil/features/auth/data/models/link_models.dart';
import 'package:phishwarden_movil/features/auth/presentation/welcome_view_model.dart';

class PendingRepository implements AuthRepository {
  final completer = Completer<LinkResult>();
  int calls = 0;
  @override
  Future<LinkResult> linkDevice(LinkRequest request) {
    calls++;
    return completer.future;
  }
}

void main() {
  test('No acepta correos inválidos ni códigos vacíos', () {
    expect(WelcomeViewModel.validateEmail('invalido'), isNotNull);
    expect(WelcomeViewModel.validateEmail('a@empresa.com'), isNull);
    expect(WelcomeViewModel.validateCode('  '), isNotNull);
  });
  test('Recupera el estado tras un fallo y permite reintentar', () async {
    final model = WelcomeViewModel(
      MockAuthRepository(delay: Duration.zero, simulateFailure: true),
    );
    addTearDown(model.dispose);
    expect(await model.submit('NOVA', 'a@empresa.com'), isNull);
    expect(model.isLoading, isFalse);
    expect(model.errorMessage, isNotNull);
    expect(await model.submit('NOVA', 'a@empresa.com'), isNull);
    expect(model.isLoading, isFalse);
  });
  test(
    'Impide envíos duplicados y tolera cerrar la pantalla durante la petición',
    () async {
      final repository = PendingRepository();
      final model = WelcomeViewModel(repository);
      final first = model.submit('NOVA', 'a@empresa.com');
      expect(await model.submit('NOVA', 'a@empresa.com'), isNull);
      expect(repository.calls, 1);
      model.dispose();
      repository.completer.complete(
        const LinkResult(
          companyCode: 'NOVA',
          email: 'a@empresa.com',
          isDemo: true,
        ),
      );
      expect((await first)?.isDemo, isTrue);
    },
  );
}
