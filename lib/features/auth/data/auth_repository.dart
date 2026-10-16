import 'models/link_models.dart';

abstract interface class AuthRepository {
  // Nombre conservado del paso 1. Hoy valida correo y código; no registra push.
  Future<LinkResult> linkDevice(LinkRequest request);
}

class LinkFailure implements Exception {
  const LinkFailure(this.message);
  final String message;
}
