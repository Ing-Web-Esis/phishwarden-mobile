import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../profile/data/profile_repository.dart';
import '../data/training_repository.dart';
import 'training_widgets.dart';

class TrainingResultContent extends StatelessWidget {
  const TrainingResultContent({
    super.key,
    required this.result,
    required this.onProfile,
    required this.onRetry,
  });
  final TrainingResult result;
  final VoidCallback onProfile, onRetry;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainingHeading(
          label: 'Quiz completado',
          title: result.passed ? '¡Bien hecho!' : 'Sigamos aprendiendo',
          back: true,
        ),
        CircleAvatar(
          radius: 38,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            result.passed ? Icons.check_circle_outline : Icons.school_outlined,
            size: 40,
            color: result.passed ? AppTheme.lowRisk : AppTheme.gold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${result.correct} de ${result.total} respuestas correctas',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.passed
                    ? 'Un paso más para protegerte.'
                    : 'Cada intento te ayuda a aprender.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                result.passed
                    ? 'Completaste esta microlección. Sigue revisando el remitente, los enlaces y las solicitudes inesperadas.'
                    : 'Repasa las señales de alerta y vuelve a intentarlo. Verifica los mensajes por un canal oficial antes de actuar.',
              ),
            ],
          ),
        ),
        TrainingCard(
          color: AppTheme.gold,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: AppTheme.ink),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+${result.points} puntos',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('De aprendizaje · Total: ${result.totalPoints} pts'),
                const SizedBox(height: 8),
                const Text(
                  'Los puntos recompensan tu práctica; no son tu riesgo.',
                ),
              ],
            ),
          ),
        ),
        TrainingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu riesgo individual',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                '${result.risk} /100 · ${riskLabelFor(result.risk)}',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (result.risk / 100).clamp(0, 1),
                color: result.risk <= 30
                    ? AppTheme.lowRisk
                    : result.risk <= 60
                    ? AppTheme.mediumRisk
                    : AppTheme.highRisk,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 12),
              const Text('Menor riesgo es mejor. No son puntos ganados.'),
            ],
          ),
        ),
        if (result.badges.isNotEmpty)
          TrainingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nuevos logros',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                for (final badge in result.badges)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: Text(badge),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onProfile,
          child: const Text('Volver a mi perfil'),
        ),
        if (!result.passed) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Repasar y volver a intentar'),
          ),
        ],
      ],
    );
  }
}
