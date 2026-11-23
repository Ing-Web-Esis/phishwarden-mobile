import '../../../core/network/api_client.dart';
import '../../auth/data/models/link_models.dart';

/// Un null significa que el dato todavía no está disponible, nunca cero.
class EmployeeProfile {
  const EmployeeProfile({
    required this.email,
    required this.companyName,
    this.name,
    this.department,
    this.riskScore,
    this.riskLabel,
    this.learningPoints,
    this.safeDays,
    this.simulationsReceived,
    this.simulationsWithInteraction,
    this.simulationsWithoutInteraction,
  });
  final String email;
  final String companyName;
  final String? name;
  final String? department;
  final int? riskScore;
  final String? riskLabel;
  final int? learningPoints;
  final int? safeDays;
  final int? simulationsReceived;
  final int? simulationsWithInteraction;
  final int? simulationsWithoutInteraction;
}

abstract interface class ProfileRepository {
  Future<EmployeeProfile> load();
}

/// Perfil real desde GET /mobile/perfil (requiere el JWT de colaborador).
class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository(this._api, this._access);
  final ApiClient _api;
  final LinkResult _access;

  @override
  Future<EmployeeProfile> load() async {
    final token = _access.accessToken;
    if (token == null) {
      throw const ApiFailure('Sesión móvil sin token de acceso.');
    }
    final data = await _api.get('mobile/perfil', bearerToken: token);
    final empresa = data['empresa'];
    return EmployeeProfile(
      email: data['correoCorporativo'] as String? ?? _access.email,
      companyName: empresa is Map<String, dynamic>
          ? empresa['nombre'] as String? ?? 'Empresa'
          : _access.companyName ?? 'Empresa',
      name: data['nombre'] as String?,
      department: data['departamento'] as String?,
      riskScore: data['scoreRiesgo'] as int?,
      safeDays: data['rachaDiasSeguros'] as int?,
      learningPoints: data['puntosTotales'] as int?,
    );
  }
}

/// Datos confirmados por el login. No consulta rutas inventadas ni Supabase.
/// Sustituir por un repositorio HTTP cuando exista el contrato de perfil.
class SessionProfileRepository implements ProfileRepository {
  SessionProfileRepository(this._access);
  final LinkResult _access;

  @override
  Future<EmployeeProfile> load() async => EmployeeProfile(
    email: _access.email,
    companyName: _access.companyName ?? 'Empresa',
  );
}
