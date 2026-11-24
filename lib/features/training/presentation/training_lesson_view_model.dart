import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/training_repository.dart';

class TrainingLessonViewModel extends ChangeNotifier {
  TrainingLessonViewModel(this.repository, this.id);
  final TrainingRepository repository;
  final int id;
  TrainingLesson? lesson;
  TrainingResult? result;
  final Map<int, String> answers = {};
  bool loading = false, submitting = false, _disposed = false;
  String? error;
  bool get canSubmit =>
      lesson != null &&
      lesson!.questions.isNotEmpty &&
      lesson!.questions.every((q) => q.options.containsKey(answers[q.id]));

  Future<void> load() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      lesson = await repository.detail(id);
    } catch (_) {
      error = 'No pudimos cargar esta microlección.';
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void select(int questionId, String option) {
    if (_disposed || submitting || result != null || lesson == null) return;
    if (!lesson!.questions.any(
      (q) => q.id == questionId && q.options.containsKey(option),
    )) {
      return;
    }
    answers[questionId] = option;
    error = null;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (_disposed || submitting || result != null || !canSubmit) return false;
    submitting = true;
    error = null;
    notifyListeners();
    try {
      result = await repository.evaluate(id, Map.of(answers));
      return true;
    } on ApiFailure catch (e) {
      error = e.statusCode == 401 || e.statusCode == 403
          ? 'Tu sesión no permite enviar respuestas. Vuelve a ingresar.'
          : 'No pudimos confirmar el resultado. Tus respuestas se conservan; vuelve a intentarlo.';
      return false;
    } catch (_) {
      error = 'No pudimos confirmar el resultado. Tus respuestas se conservan; vuelve a intentarlo.';
      return false;
    } finally {
      submitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  void retryQuiz() {
    if (_disposed || submitting) return;
    result = null;
    answers.clear();
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
