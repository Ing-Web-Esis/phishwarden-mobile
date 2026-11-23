import '../../../core/network/api_client.dart';
import 'auth_repository.dart';
import 'models/link_models.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);
  final ApiClient _api;

  @override
  Future<LinkResult> linkDevice(LinkRequest request) async {
    try {
      final data = await _api.post('mobile/auth/vincular', {
        'correoCorporativo': request.email.trim().toLowerCase(),
        'codigoAcceso': request.companyCode.trim(),
      });
      final user = data['usuario'];
      final company = user is Map<String, dynamic> ? user['empresa'] : null;
      if (user is! Map<String, dynamic> ||
          user['id'] is! String ||
          (user['id'] as String).isEmpty ||
          user['correoCorporativo'] is! String ||
          (user['correoCorporativo'] as String).isEmpty ||
          company is! Map<String, dynamic> ||
          company['nombre'] is! String ||
          (company['nombre'] as String).isEmpty) {
        throw const LinkFailure(
          'El backend respondió sin los datos esperados del empleado.',
        );
      }
      final token = data['accessToken'];
      if (token is! String || token.isEmpty) {
        throw const LinkFailure(
          'El backend no devolvió un token de acceso válido.',
        );
      }
      return LinkResult(
        companyCode: request.companyCode.trim(),
        email: user['correoCorporativo'] as String,
        isDemo: false,
        userId: user['id'] as String,
        companyName: company['nombre'] as String,
        accessToken: token,
      );
    } on ApiFailure catch (failure) {
      throw LinkFailure(failure.message);
    }
  }
}
