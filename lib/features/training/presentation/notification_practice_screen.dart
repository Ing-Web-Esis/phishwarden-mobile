import 'package:flutter/material.dart';

import '../../../core/notifications/notification_service.dart';
import 'notification_practice_view_model.dart';

class NotificationPracticeScreen extends StatefulWidget {
  const NotificationPracticeScreen({super.key, required this.service});
  final NotificationService service;
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
    appBar: AppBar(title: const Text('Prueba en Android')),
    body: ListenableBuilder(
      listenable: _model,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.notifications_active_outlined, size: 64),
          const SizedBox(height: 24),
          Text(
            'Notificación y microlección',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'Al pulsar el botón, Android pedirá permiso si corresponde y mostrará una notificación del sistema. Tócala en la bandeja para abrir la microlección.',
          ),
          const SizedBox(height: 16),
          const Text(
          'Este aviso se genera en el celular; todavía no llega desde el backend.',
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
              _model.isLoading ? 'Enviando…' : 'Mostrar notificación real',
            ),
          ),
          if (_model.message != null) ...[
            const SizedBox(height: 16),
            Semantics(liveRegion: true, child: Text(_model.message!)),
          ],
        ],
      ),
    ),
  );
}
