import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phishwarden_movil/core/network/api_client.dart';
import 'package:phishwarden_movil/features/auth/data/api_auth_repository.dart';
import 'package:phishwarden_movil/features/auth/data/auth_repository.dart';
import 'package:phishwarden_movil/features/auth/data/models/link_models.dart';

const request = LinkRequest(
  companyCode: ' SALA2026 ',
  email: ' Alumna@Example.com ',
);

void main() {
  test('Envía el contrato móvil y convierte una respuesta real 201', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:3000/',
      client: MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/auth/login');
        expect(jsonDecode(req.body), {
          'email': 'alumna@example.com',
          'codigoEmpresa': 'SALA2026',
        });
        return http.Response(
          jsonEncode({
            'empresa': 'Empresa prueba',
            'user': {'id': 'user-1', 'email': 'alumna@example.com'},
          }),
          201,
        );
      }),
    );
    addTearDown(api.close);
    final result = await ApiAuthRepository(api).linkDevice(request);
    expect(result.isDemo, isFalse);
    expect(result.userId, 'user-1');
    expect(result.companyName, 'Empresa prueba');
  });

  test('Propaga el 401 sin convertirlo en ingreso exitoso', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Código de empresa o sala inválido'}),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      ApiAuthRepository(api).linkDevice(request),
      throwsA(
        isA<LinkFailure>().having(
          (error) => error.message,
          'message',
          'Código de empresa o sala inválido',
        ),
      ),
    );
  });

  test(
    'Interpreta errores de validación NestJS y oculta detalles internos 500',
    () async {
      var status = 400;
      final api = ApiClient(
        baseUrl: 'http://localhost:3000',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'message': status == 400
                  ? ['email should not be empty', 'email must be a string']
                  : 'DATABASE_URL secreto',
            }),
            status,
          ),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        ApiAuthRepository(api).linkDevice(request),
        throwsA(
          isA<LinkFailure>().having(
            (error) => error.message,
            'message',
            contains('email should not be empty'),
          ),
        ),
      );
      status = 500;
      await expectLater(
        ApiAuthRepository(api).linkDevice(request),
        throwsA(
          isA<LinkFailure>().having(
            (error) => error.message,
            'message',
            isNot(contains('secreto')),
          ),
        ),
      );
    },
  );

  test('No acepta 2xx sin un usuario y empresa válidos', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:3000',
      client: MockClient((_) async => http.Response('{"message":"ok"}', 200)),
    );
    addTearDown(api.close);
    await expectLater(
      ApiAuthRepository(api).linkDevice(request),
      throwsA(isA<LinkFailure>()),
    );
  });

  test(
    'Distingue desconexión y tiempo de espera, sin reintentar el POST',
    () async {
      final disconnected = ApiClient(
        baseUrl: 'http://localhost:3000',
        client: MockClient((_) async {
          throw http.ClientException('Connection refused');
        }),
      );
      addTearDown(disconnected.close);
      await expectLater(
        ApiAuthRepository(disconnected).linkDevice(request),
        throwsA(
          isA<LinkFailure>().having(
            (error) => error.message,
            'message',
            contains('conectar'),
          ),
        ),
      );
      var calls = 0;
      final slow = ApiClient(
        baseUrl: 'http://localhost:3000',
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return http.Response('{}', 200);
        }),
      );
      addTearDown(slow.close);
      await expectLater(
        ApiAuthRepository(slow).linkDevice(request),
        throwsA(
          isA<LinkFailure>().having(
            (error) => error.message,
            'message',
            contains('tardó demasiado'),
          ),
        ),
      );
      expect(calls, 1);
    },
  );
}
