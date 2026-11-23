import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

/// Solo transporte y errores. No conoce widgets ni estado de formularios.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? bearerToken,
  }) => _send(
    path,
    bearerToken,
    (uri, headers) =>
        _client.post(uri, headers: headers, body: jsonEncode(body)),
  );

  Future<Map<String, dynamic>> get(String path, {String? bearerToken}) =>
      _send(path, bearerToken, (uri, headers) => _client.get(uri, headers: headers));

  Future<Map<String, dynamic>> _send(
    String path,
    String? bearerToken,
    Future<http.Response> Function(Uri uri, Map<String, String> headers) send,
  ) async {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        !base.hasAuthority ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.scheme != 'http' && base.scheme != 'https')) {
      throw const ApiFailure('Configura una dirección válida para la API.');
    }
    if (const bool.fromEnvironment('dart.vm.product') &&
        base.scheme != 'https') {
      throw const ApiFailure(
        'La versión de producción requiere una API HTTPS.',
      );
    }
    final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/$path');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
    };
    http.Response response;
    try {
      response = await send(uri, headers).timeout(timeout);
    } on TimeoutException {
      throw const ApiFailure(
        'El servidor tardó demasiado. Comprueba la conexión y vuelve a intentarlo.',
      );
    } on http.ClientException {
      throw const ApiFailure(
        'No se pudo conectar con el backend. Comprueba que esté iniciado y que la dirección de la API sea correcta.',
      );
    }

    final success = response.statusCode >= 200 && response.statusCode < 300;
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } on FormatException {
      // Un proxy o servidor también puede responder HTML en un fallo.
    }
    if (!success) {
      String? message;
      final serverMessage = data?['message'];
      if (serverMessage is String) message = serverMessage;
      if (serverMessage is List) {
        message = serverMessage.whereType<String>().join('\n');
      }
      // No mostrar detalles internos de errores de servidor al usuario.
      if (response.statusCode >= 500) {
        message = 'El backend no pudo procesar la solicitud. Revisa su conexión a la base de datos con tu compañero.';
      }
      throw ApiFailure(
        message?.isNotEmpty == true
            ? message!
            : 'La solicitud fue rechazada (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    if (data == null) {
      throw const ApiFailure(
        'La respuesta del backend no tiene el formato esperado.',
      );
    }
    return data;
  }

  void close() => _client.close();
}
