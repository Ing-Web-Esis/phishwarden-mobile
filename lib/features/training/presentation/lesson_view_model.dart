import 'package:flutter/foundation.dart';

import '../data/lesson_repository.dart';

class LessonViewModel extends ChangeNotifier {
  LessonViewModel(this._repository);
  final LessonRepository _repository;
  Lesson? lesson;
  bool isLoading = true;
  String? error;
  int? selectedAnswer;
  bool submitted = false;
  bool _disposed = false;

  bool get isCorrect => submitted && selectedAnswer == lesson?.correctAnswer;

  Future<void> load(String id) async {
    try {
      lesson = await _repository.findById(id);
      if (lesson == null) error = 'No se encontró esta microlección.';
    } catch (_) {
      error = 'No se pudo cargar la microlección.';
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void select(int index) {
    if (submitted ||
        lesson == null ||
        index < 0 ||
        index >= lesson!.answers.length) {
      return;
    }
    selectedAnswer = index;
    notifyListeners();
  }

  void submit() {
    if (selectedAnswer == null || submitted) return;
    submitted = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
