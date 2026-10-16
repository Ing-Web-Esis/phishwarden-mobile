import 'package:flutter/material.dart';

import '../data/lesson_repository.dart';
import 'lesson_view_model.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.lessonId,
    required this.repository,
  });
  final String lessonId;
  final LessonRepository repository;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final LessonViewModel _model;
  @override
  void initState() {
    super.initState();
    _model = LessonViewModel(widget.repository)..load(widget.lessonId);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Microlección')),
    body: ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        if (_model.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_model.error != null) return Center(child: Text(_model.error!));
        final lesson = _model.lesson!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              lesson.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text('Lectura y pregunta · Aproximadamente 1–2 minutos'),
            for (var i = 0; i < lesson.tips.length; i++) ...[
              const SizedBox(height: 16),
              Text('${i + 1}. ${lesson.tips[i]}'),
            ],
            const SizedBox(height: 28),
            Text(
              lesson.question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < lesson.answers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: _model.submitted ? null : () => _model.select(i),
                  child: Row(
                    children: [
                      Icon(
                        _model.selectedAnswer == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(lesson.answers[i])),
                    ],
                  ),
                ),
              ),
            FilledButton(
              onPressed: _model.selectedAnswer == null || _model.submitted
                  ? null
                  : _model.submit,
              child: const Text('Comprobar respuesta'),
            ),
            if (_model.submitted) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  '${_model.isCorrect ? '¡Correcto!' : 'Revisa las señales de alerta.'}\n${lesson.explanation}',
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Práctica local: el resultado no se guarda y se reinicia al salir.',
            ),
          ],
        );
      },
    ),
  );
}
