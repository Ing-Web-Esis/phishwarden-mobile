import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class TrainingCard extends StatelessWidget {
  const TrainingCard({super.key, required this.child, this.color, this.onTap});
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      ),
    ),
  );
}

class TrainingHeading extends StatelessWidget {
  const TrainingHeading({
    super.key,
    required this.label,
    required this.title,
    this.back = false,
  });
  final String label, title;
  final bool back;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      children: [
        if (back) const BackButton(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.gold
                      : AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ],
    ),
  );
}

class TrainingError extends StatelessWidget {
  const TrainingError({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 36),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}
