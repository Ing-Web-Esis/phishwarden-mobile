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
