import '../../../core/network/api_client.dart';
import '../../auth/data/models/link_models.dart';

class TrainingLesson {
  const TrainingLesson({
    required this.id,
    required this.title,
    required this.method,
    required this.minutes,
    required this.status,
    this.content,
    this.questions = const [],
  });
  final int id;
  final String title, method, status;
  final int minutes;
  final String? content;
  final List<TrainingQuestion> questions;
  bool get completed => status == 'completada';
  bool get pending => status == 'pendiente' || status == 'reprobada';
  bool get isPhishing => method.toLowerCase() == 'phishing';
  bool get isSmishing => method.toLowerCase() == 'smishing';

  factory TrainingLesson.fromJson(Map<String, dynamic> json) => TrainingLesson(
    id: json['id'] as int,
    title: json['titulo'] as String,
    method: json['metodoAtaque'] as String,
    minutes: json['duracionMinutos'] as int,
    status: (json['estadoUsuario'] ?? json['estado']) as String,
    content: json['contenidoMultimedia'] as String?,
    questions: [
      for (final q in (json['preguntas'] as List? ?? []))
        TrainingQuestion.fromJson(q as Map<String, dynamic>),
    ],
  );
}

class TrainingQuestion {
  const TrainingQuestion({
    required this.id,
    required this.text,
    required this.options,
  });
  final int id;
  final String text;
  final Map<String, String> options;
  factory TrainingQuestion.fromJson(Map<String, dynamic> json) =>
      TrainingQuestion(
        id: json['id'] as int,
        text: json['enunciado'] as String,
        options: {
          for (final key in ['A', 'B', 'C', 'D'])
            if ((json['opcion$key'] as String?)?.trim().isNotEmpty == true)
              key: json['opcion$key'] as String,
        },
      );
}

class TrainingResult {
  const TrainingResult({
    required this.passed,
    required this.correct,
    required this.total,
    required this.points,
    required this.totalPoints,
    required this.risk,
    required this.badges,
  });
  final bool passed;
  final int correct, total, points, totalPoints, risk;
  final List<String> badges;
  factory TrainingResult.fromJson(Map<String, dynamic> json) => TrainingResult(
    passed: json['aprobado'] as bool,
    correct: json['correctas'] as int,
    total: json['totalPreguntas'] as int,
    points: json['puntosGanados'] as int,
    totalPoints: json['puntosTotales'] as int,
    risk: json['scoreRiesgoActualizado'] as int,
    badges: [
      for (final b in json['nuevasMedallasDesbloqueadas'] as List)
        (b as Map<String, dynamic>)['nombre'] as String,
    ],
  );
}

abstract interface class TrainingRepository {
  Future<List<TrainingLesson>> load();
  Future<TrainingLesson> detail(int id);
  Future<TrainingResult> evaluate(int id, Map<int, String> answers);
}

class HttpTrainingRepository implements TrainingRepository {
  HttpTrainingRepository(this._api, this._access);
  final ApiClient _api;
  final LinkResult _access;
  String get _token {
    final token = _access.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiFailure('Tu sesión ha terminado. Vuelve a ingresar.');
    }
    return token;
  }

  @override
  Future<List<TrainingLesson>> load() async {
    final data = await _api.get('mobile/lecciones', bearerToken: _token);
    return [
      for (final group in [
        'asignadasPendientes',
        'catalogoDisponible',
        'completadas',
      ])
        for (final item in data[group] as List)
          TrainingLesson.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<TrainingLesson> detail(int id) async => TrainingLesson.fromJson(
    await _api.get('mobile/lecciones/$id', bearerToken: _token),
  );

  @override
  Future<TrainingResult> evaluate(int id, Map<int, String> answers) async =>
      TrainingResult.fromJson(
        await _api.post('mobile/lecciones/$id/evaluar', {
          'respuestas': [
            for (final answer in answers.entries)
              {'preguntaId': answer.key, 'respuestaSeleccionada': answer.value},
          ],
        }, bearerToken: _token),
      );
}
