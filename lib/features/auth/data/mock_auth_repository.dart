import 'auth_repository.dart';
import 'models/link_models.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    this.delay = const Duration(milliseconds: 900),
    this.simulateFailure = false,
  });
  final Duration delay;
  final bool simulateFailure;

  @override
  Future<LinkResult> linkDevice(LinkRequest request) async {
    await Future<void>.delayed(delay);
    if (simulateFailure) {
      throw const LinkFailure(
        'No se pudo completar la vinculación. Inténtalo nuevamente.',
      );
    }
    // No autentica, no registra dispositivos y no almacena datos.
    return LinkResult(
      companyCode: request.companyCode,
      email: request.email,
      isDemo: true,
    );
  }
}
