import '../../../core/network/api_client.dart';
import '../../auth/data/models/link_models.dart';

class RankingEntry {
  const RankingEntry({
    required this.position,
    required this.name,
    required this.department,
    required this.points,
    required this.medalsCount,
    required this.safeDays,
    required this.isCurrentUser,
  });
  final int position;
  final String name;
  final String? department;
  final int points;
  final int medalsCount;
  final int safeDays;
  final bool isCurrentUser;
}

class RankingData {
  const RankingData({required this.myPosition, required this.entries});
  final int? myPosition;
  final List<RankingEntry> entries;
}

abstract interface class RankingRepository {
  Future<RankingData> load();
}

/// Ranking interno de la empresa desde GET /mobile/ranking (requiere el JWT).
class HttpRankingRepository implements RankingRepository {
  HttpRankingRepository(this._api, this._access);
  final ApiClient _api;
  final LinkResult _access;

  @override
  Future<RankingData> load() async {
    final token = _access.accessToken;
    if (token == null) {
      throw const ApiFailure('Sesión móvil sin token de acceso.');
    }
    final data = await _api.get('mobile/ranking', bearerToken: token);
    final lista = (data['ranking'] as List?) ?? const [];
    return RankingData(
      myPosition: data['miPosicion'] as int?,
      entries: [
        for (final item in lista.cast<Map<String, dynamic>>())
          RankingEntry(
            position: item['posicion'] as int? ?? 0,
            name: item['nombre'] as String? ?? 'Colaborador',
            department: item['departamento'] as String?,
            points: item['puntosTotales'] as int? ?? 0,
            medalsCount: item['medallasCount'] as int? ?? 0,
            safeDays: item['rachaDiasSeguros'] as int? ?? 0,
            isCurrentUser: item['esUsuarioActual'] as bool? ?? false,
          ),
      ],
    );
  }
}
