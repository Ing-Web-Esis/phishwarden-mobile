import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/training_repository.dart';
import 'training_widgets.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({
    super.key,
    required this.repository,
    required this.onLesson,
    this.refresh,
  });
  final TrainingRepository repository;
  final ValueChanged<int> onLesson;
  final Listenable? refresh;
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late Future<List<TrainingLesson>> _future;
  int _filter = 0;
  @override
  void initState() {
    super.initState();
    _future = widget.repository.load();
    widget.refresh?.addListener(_reload);
  }

  void _reload() => setState(() {
    _future = widget.repository.load();
  });
  @override
  void dispose() {
    widget.refresh?.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const TrainingHeading(
              label: 'Capacitación',
              title: 'Aprende a protegerte',
            ),
            FutureBuilder<List<TrainingLesson>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return TrainingError(
                    message: 'No pudimos cargar tus microlecciones.',
                    onRetry: _reload,
                  );
                }
                final lessons = snapshot.requireData;
                final complete = lessons.where((l) => l.completed).length;
                final pending = lessons.where((l) => l.pending).length;
                final visible = lessons.where(
                  (l) => switch (_filter) {
                    1 => l.pending,
                    2 => l.completed,
                    _ => true,
                  },
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TrainingCard(
                      color: AppTheme.gold,
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(color: AppTheme.ink),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pequeños pasos, más seguridad',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$complete de ${lessons.length} lecciones completadas',
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: lessons.isEmpty
                                  ? 0
                                  : complete / lessons.length,
                              color: AppTheme.ink,
                              backgroundColor: Colors.white54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in [
                          (0, 'Todas'),
                          (1, 'Pendientes · $pending'),
                          (2, 'Completadas'),
                        ])
                          ChoiceChip(
                            label: Text(option.$2),
                            selected: _filter == option.$1,
                            onSelected: (_) =>
                                setState(() => _filter = option.$1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Microlecciones para ti',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          lessons.isEmpty
                              ? 'Aún no hay microlecciones disponibles.'
                              : 'No hay lecciones en esta categoría.',
                        ),
                      ),
                    for (final lesson in visible)
                      TrainingCard(
                        onTap: () => widget.onLesson(lesson.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  lesson.isSmishing
                                      ? Icons.sms_outlined
                                      : Icons.mail_outline,
                                  color: lesson.completed
                                      ? AppTheme.lowRisk
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lesson.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        lesson.method,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                Text(
                                  lesson.completed
                                      ? 'Completada'
                                      : lesson.status == 'reprobada'
                                      ? 'Vuelve a practicar'
                                      : lesson.pending
                                      ? 'Pendiente'
                                      : 'Disponible',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${lesson.minutes} min · ${lesson.completed ? 'Quiz aprobado' : 'Incluye quiz'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
