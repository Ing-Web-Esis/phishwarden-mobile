import '../../../core/network/api_client.dart';
import 'auth_repository.dart';
import 'models/link_models.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);
  final ApiClient _api;

  @override
  Future<LinkResult> linkDevice(LinkRequest request) async {
    try {
      final data = await _api.post('auth/login', {
        'email': request.email.trim().toLowerCase(),
        'codigoEmpresa': request.companyCode.trim(),
      });
      final user = data['user'];
      final company = data['empresa'];
      if (user is! Map<String, dynamic> ||
          user['id'] is! String ||
          (user['id'] as String).isEmpty ||
          user['email'] is! String ||
          (user['email'] as String).isEmpty ||
          company is! String ||
          company.isEmpty) {
        throw const LinkFailure(
          'El backend respondió sin los datos esperados del empleado.',
        );
      }
      return LinkResult(
        companyCode: request.companyCode.trim(),
        email: user['email'] as String,
        isDemo: false,
        userId: user['id'] as String,
        companyName: company,
      );
    } on ApiFailure catch (failure) {
      throw LinkFailure(failure.message);
    }
  }
}
