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
    this.nextLesson,
    this.medals,
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
  final LessonPreview? nextLesson;
  final List<MedalPreview>? medals;
}

class LessonPreview {
  const LessonPreview({
    required this.title,
    required this.durationMinutes,
    required this.points,
  });
  final String title;
  final int durationMinutes;
  final int points;
}

class MedalPreview {
  const MedalPreview({
    required this.name,
    required this.unlocked,
    required this.iconName,
  });
  final String name;
  final bool unlocked;
  final String iconName;
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
    final results = await Future.wait([
      _api.get('mobile/perfil', bearerToken: token),
      _optional(() => _api.get('mobile/lecciones', bearerToken: token)),
      _optional(() => _api.get('mobile/medallas', bearerToken: token)),
    ]);
    final data = results[0]!;
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
      nextLesson: _nextLesson(results[1]),
      medals: _medals(results[2]),
    );
  }

  /// Carga secundaria: si falla, la pantalla muestra "Sin datos" en vez de no abrir.
  Future<Map<String, dynamic>?> _optional(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } catch (_) {
      return null;
    }
  }

  LessonPreview? _nextLesson(Map<String, dynamic>? data) {
    if (data == null) return null;
    final candidatas = [
      ...?(data['asignadasPendientes'] as List?),
      ...?(data['catalogoDisponible'] as List?),
    ];
    if (candidatas.isEmpty) return null;
    final leccion = candidatas.first as Map<String, dynamic>;
    return LessonPreview(
      title: leccion['titulo'] as String? ?? '',
      durationMinutes: leccion['duracionMinutos'] as int? ?? 0,
      points: leccion['puntosRecompensa'] as int? ?? 0,
    );
  }

  List<MedalPreview>? _medals(Map<String, dynamic>? data) {
    final medallas = data?['medallas'];
    if (medallas is! List) return null;
    return [
      for (final medalla in medallas.cast<Map<String, dynamic>>())
        MedalPreview(
          name: medalla['nombre'] as String? ?? '',
          unlocked: medalla['desbloqueada'] as bool? ?? false,
          iconName: medalla['iconoUrl'] as String? ?? '',
        ),
    ];
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
