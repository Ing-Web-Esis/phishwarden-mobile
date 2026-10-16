import 'package:flutter/material.dart';

import '../data/models/link_models.dart';

class AccessScreen extends StatelessWidget {
  const AccessScreen({
    super.key,
    required this.result,
    required this.onTraining,
    required this.onLogout,
  });
  final LinkResult result;
  final VoidCallback onTraining;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('PhishWarden MJ'),
      actions: [TextButton(onPressed: onLogout, child: const Text('Salir'))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.verified_user_outlined, size: 64),
        const SizedBox(height: 24),
        Text(
          'Acceso validado',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text(
          result.companyName ?? '',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(result.email),
        const SizedBox(height: 16),
        const Text('El servidor validó tu correo y código de empresa.'),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onTraining,
          child: const Text('Probar notificación y microlección'),
        ),
      ],
    ),
  );
}
