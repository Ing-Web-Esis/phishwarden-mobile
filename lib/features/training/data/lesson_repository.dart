class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.tips,
    required this.question,
    required this.answers,
    required this.correctAnswer,
    required this.explanation,
  });
  final String id;
  final String title;
  final List<String> tips;
  final String question;
  final List<String> answers;
  final int correctAnswer;
  final String explanation;
}

abstract class LessonRepository {
  Future<Lesson?> findById(String id);
}

/// Contenido local de práctica. Luego se sustituye por el repositorio de API.
class LocalLessonRepository implements LessonRepository {
  static const practiceLessonId = 'phishing-email';
  @override
  Future<Lesson?> findById(String id) async {
    if (id != practiceLessonId) return null;
    return const Lesson(
      id: practiceLessonId,
      title: 'Reconoce un correo de phishing',
      tips: [
        'Revisa la dirección completa del remitente. Un nombre conocido no demuestra que el mensaje sea auténtico.',
        'Desconfía de mensajes que amenazan con bloquear tu cuenta o te presionan para actuar de inmediato.',
        'Verifica el destino de los enlaces. En el celular, mantén pulsado el enlace para inspeccionarlo sin abrirlo.',
        'Si tienes dudas, abre la aplicación o el sitio oficial por tu cuenta y consulta al equipo de TI por un canal conocido.',
      ],
      question: 'Un correo dice que tu cuenta será bloqueada hoy y pide tu contraseña mediante un enlace. ¿Qué haces?',
      answers: [
        'Abro el enlace y escribo mi contraseña.',
        'Verifico por un canal oficial y reporto el mensaje a TI.',
        'Respondo al correo enviando mis datos.',
      ],
      correctAnswer: 1,
      explanation: 'La urgencia y la solicitud de contraseña son señales de alerta. Verifica por un canal oficial y reporta el mensaje; no compartas credenciales.',
    );
  }
}
