import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/training_repository.dart';
import 'training_lesson_view_model.dart';
import 'training_widgets.dart';
import 'training_result_screen.dart';

class TrainingLessonScreen extends StatefulWidget {
  const TrainingLessonScreen({
    super.key,
    required this.id,
    required this.repository,
    required this.onEvaluated,
    required this.onProfile,
  });
  final int id;
  final TrainingRepository repository;
  final VoidCallback onEvaluated, onProfile;
  @override
  State<TrainingLessonScreen> createState() => _TrainingLessonScreenState();
}

class _TrainingLessonScreenState extends State<TrainingLessonScreen> {
  late final TrainingLessonViewModel _model;
  final _scroll = ScrollController();
  bool _quiz = false;
  int _question = 0;
  @override
  void initState() {
    super.initState();
    _model = TrainingLessonViewModel(widget.repository, widget.id)..load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _model.dispose();
    super.dispose();
  }

  void _move(VoidCallback action) {
    setState(action);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _submit() async {
    final saved = await _model.submit();
    if (!mounted || !saved) return;
    widget.onEvaluated();
    _move(() {});
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _model,
    builder: (context, _) => PopScope(
      canPop: !_model.submitting,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(20),
            children: [
              if (_model.loading) ...[
                const TrainingHeading(
                  label: 'Capacitación',
                  title: 'Microlección',
                  back: true,
                ),
                const Center(child: CircularProgressIndicator()),
              ] else if (_model.lesson == null) ...[
                const TrainingHeading(
                  label: 'Capacitación',
                  title: 'Microlección',
                  back: true,
                ),
                TrainingError(
                  message: _model.error ?? 'Microlección no disponible.',
                  onRetry: _model.load,
                ),
              ] else if (_model.result != null)
                TrainingResultContent(
                  result: _model.result!,
                  onProfile: widget.onProfile,
                  onRetry: () => _move(() {
                    _model.retryQuiz();
                    _quiz = false;
                    _question = 0;
                  }),
                )
              else if (_quiz)
                ..._quizWidgets(context)
              else
                ..._lessonWidgets(context),
            ],
          ),
        ),
      ),
    ),
  );

  List<Widget> _lessonWidgets(BuildContext context) {
    final lesson = _model.lesson!;
    return [
      TrainingHeading(
        label: '${lesson.method} · ${lesson.minutes} min',
        title: 'Microlección',
        back: true,
      ),
      if (lesson.pending)
        TrainingCard(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Fue una simulación. Estás a salvo.\nVeamos juntos las señales del mensaje.',
                ),
              ),
            ],
          ),
        ),
      Text(lesson.title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (lesson.isPhishing || lesson.isSmishing) ...[
        Text(
          lesson.isSmishing
              ? 'Los mensajes breves también pueden engañar. Estas son las pistas.'
              : 'Antes de tocar un enlace, revisa quién escribe y qué te pide hacer.',
        ),
        const SizedBox(height: 20),
        _MessageExample(sms: lesson.isSmishing),
        for (final tip in [
          (
            '1',
            'Remitente extraño',
            'Un nombre conocido no demuestra que el mensaje sea auténtico.',
          ),
          (
            '2',
            'Urgencia artificial',
            'La amenaza busca que actúes sin pensar. Tómate un momento para verificar.',
          ),
          (
            '3',
            'Enlace diferente',
            'Un dominio parecido no garantiza que sea legítimo.',
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: Text(tip.$1, style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.$2,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        tip.$3,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        TrainingCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_outlined, color: AppTheme.lowRisk),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lesson.isSmishing
                      ? 'Abre la app oficial de la empresa de envíos y verifica tu pedido. No compartas datos en el enlace del SMS.'
                      : 'No abras el enlace. Verifica la solicitud con TI por un canal conocido.',
                ),
              ),
            ],
          ),
        ),
      ],
      if (lesson.content?.trim().isNotEmpty == true)
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contenido de la microlección',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SelectableText(lesson.content!),
            ],
          ),
        ),
      if (!lesson.isPhishing &&
          !lesson.isSmishing &&
          lesson.content?.trim().isNotEmpty != true)
        const Text(
          'Esta microlección aún no tiene material de lectura disponible.',
        ),
      const SizedBox(height: 8),
      if (lesson.completed)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Ya completaste esta lección. Puedes repasar y volver a practicar.',
          ),
        ),
      FilledButton(
        onPressed:
            lesson.questions.isEmpty ||
                lesson.questions.any((q) => q.options.isEmpty)
            ? null
            : () => _move(() {
                _quiz = true;
                _question = 0;
              }),
        child: const Text('Ir al quiz de refuerzo'),
      ),
      if (lesson.questions.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('El quiz de esta lección aún no está disponible.'),
        ),
    ];
  }

  List<Widget> _quizWidgets(BuildContext context) {
    final lesson = _model.lesson!;
    final question = lesson.questions[_question];
    final selected = _model.answers[question.id];
    final last = _question == lesson.questions.length - 1;
    final colors = Theme.of(context).colorScheme;
    return [
      TrainingHeading(
        label: 'Quiz · ${lesson.method}',
        title: 'Ponlo en práctica',
        back: true,
      ),
      Text('Pregunta ${_question + 1} de ${lesson.questions.length}'),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: (_question + 1) / lesson.questions.length,
        borderRadius: BorderRadius.circular(8),
      ),
      const SizedBox(height: 20),
      TrainingCard(
        color: colors.surfaceContainerHighest,
        child: Row(
          children: [
            Icon(lesson.isSmishing ? Icons.sms_outlined : Icons.mail_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(lesson.title)),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(question.text, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 24),
      for (final option in question.options.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            selected: selected == option.key,
            button: true,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
                backgroundColor: selected == option.key
                    ? Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF283F50)
                          : const Color(0xFFFFF1D3)
                    : colors.surfaceContainerLow,
                padding: const EdgeInsets.all(18),
                side: BorderSide(
                  color: selected == option.key
                      ? AppTheme.gold
                      : colors.outline,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _model.submitting
                  ? null
                  : () => _model.select(question.id, option.key),
              child: Row(
                children: [
                  Icon(
                    selected == option.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected == option.key
                        ? AppTheme.gold
                        : colors.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${option.key}. ${option.value}'),
                        if (selected == option.key)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Seleccionada',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      const SizedBox(height: 8),
      const Text(
        'Elige una respuesta. Aprender importa más que acertar a la primera.',
      ),
      const SizedBox(height: 20),
      if (_model.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Semantics(
            liveRegion: true,
            child: Text(_model.error!, style: TextStyle(color: colors.error)),
          ),
        ),
      FilledButton(
        onPressed: _model.submitting || selected == null
            ? null
            : last
            ? (_model.canSubmit ? _submit : null)
            : () => _move(() => _question++),
        child: Text(
          _model.submitting
              ? 'Comprobando…'
              : last
              ? 'Comprobar respuesta'
              : 'Siguiente pregunta',
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _model.submitting
            ? null
            : () => _move(() {
                if (_question > 0) {
                  _question--;
                } else {
                  _quiz = false;
                }
              }),
        child: Text(
          _question > 0 ? 'Pregunta anterior' : 'Repasar microlección',
        ),
      ),
    ];
  }
}

class _MessageExample extends StatelessWidget {
  const _MessageExample({required this.sms});
  final bool sms;
  @override
  Widget build(BuildContext context) => TrainingCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sms ? 'SMS FICTICIO · 3 SEÑALES' : 'CORREO FICTICIO · 3 SEÑALES',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 14),
        Text(
          sms ? '① ENVÍOS-EXPRESS' : '① soporte@nova-ayuda.example',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          sms ? 'Tu paquete está retenido' : 'Actualiza tu cuenta hoy',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          sms ? '② Paga hoy o será devuelto. Actualiza la entrega aquí:' : '② Tu acceso se bloqueará en 30 minutos. Confirma tu cuenta para evitar la suspensión.',
        ),
        const SizedBox(height: 12),
        Text(
          sms
              ? '③ entrega-rapida.example/pago'
              : '③ nova-validacion.example/confirmar',
        ),
        const SizedBox(height: 12),
        Text(
          'Ejemplo educativo. No es un enlace real.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
