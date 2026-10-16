import 'dart:io';

import 'package:phishwarden_movil/core/network/api_client.dart';
import 'package:phishwarden_movil/features/auth/data/api_auth_repository.dart';
import 'package:phishwarden_movil/features/auth/data/auth_repository.dart';
import 'package:phishwarden_movil/features/auth/data/models/link_models.dart';

/// Comprueba el mismo repositorio que usa Flutter, sin necesitar un emulador.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'Uso: dart run tool/check_login.dart URL_API CODIGO_EMPRESA CORREO',
    );
    exitCode = 64;
    return;
  }
  final api = ApiClient(baseUrl: arguments[0]);
  try {
    final result = await ApiAuthRepository(
      api,
    ).linkDevice(LinkRequest(companyCode: arguments[1], email: arguments[2]));
    stdout.writeln(
      'Ingreso confirmado por NestJS. Empresa: ${result.companyName}.',
    );
    stdout.writeln(
      'Respuesta válida con usuario identificado. No se recibió un token de sesión.',
    );
  } on LinkFailure catch (failure) {
    stderr.writeln(failure.message);
    exitCode = 1;
  } finally {
    api.close();
  }
}
