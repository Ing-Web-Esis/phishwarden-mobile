import 'package:flutter/material.dart';

import '../../../core/navigation/main_bottom_nav.dart';
import '../../../core/notifications/notification_service.dart';
import 'notification_practice_view_model.dart';

class NotificationPracticeScreen extends StatefulWidget {
  const NotificationPracticeScreen({
    super.key,
    required this.service,
    this.onRanking,
    this.onProfile,
  });
  final NotificationService service;
  final VoidCallback? onRanking;
  final VoidCallback? onProfile;
  @override
  State<NotificationPracticeScreen> createState() =>
      _NotificationPracticeScreenState();
}

class _NotificationPracticeScreenState
    extends State<NotificationPracticeScreen> {
  late final NotificationPracticeViewModel _model;
  @override
  void initState() {
    super.initState();
    _model = NotificationPracticeViewModel(widget.service);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: widget.onProfile == null
        ? null
        : MainBottomNav(
            selectedIndex: MainBottomNav.trainingIndex,
            onProfile: widget.onProfile!,
            onTraining: () {},
            onRanking: widget.onRanking,
          ),
    body: SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: _model,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          children: [
            Text(
              'CAPACITACIÓN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aprende a protegerte',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.notifications_active_outlined),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Práctica de notificaciones',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Genera un aviso de práctica en este celular. Toca la notificación para abrir la microlección de phishing.',
                    ),
                    const SizedBox(height: 24),
                    if (!_model.isSupported)
                      const Text(
                        'Conecta un celular Android o inicia un emulador para realizar esta prueba.',
                      ),
                    FilledButton(
                      onPressed: !_model.isSupported || _model.isLoading
                          ? null
                          : _model.send,
                      child: Text(
                        _model.isLoading ? 'Enviando…' : 'Probar notificación',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_model.message != null) ...[
              const SizedBox(height: 16),
              Semantics(liveRegion: true, child: Text(_model.message!)),
            ],
          ],
        ),
      ),
    ),
  );
}
