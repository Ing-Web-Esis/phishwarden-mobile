import 'package:flutter/material.dart';

import '../../../core/navigation/main_bottom_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../data/ranking_repository.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({
    super.key,
    required this.repository,
    this.onProfile,
    this.onTraining,
    this.refresh,
  });
  final RankingRepository repository;
  final VoidCallback? onProfile;
  final VoidCallback? onTraining;
  final Listenable? refresh;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<RankingData> _future = widget.repository.load();

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_retry);
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_retry);
    super.dispose();
  }

  void _retry() => setState(() {
    _future = widget.repository.load();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: widget.onProfile == null
        ? null
        : MainBottomNav(
            selectedIndex: MainBottomNav.rankingIndex,
            onProfile: widget.onProfile!,
            onTraining: widget.onTraining ?? () {},
            onRanking: () {},
          ),
    body: SafeArea(
      bottom: false,
      child: FutureBuilder<RankingData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pudimos cargar el ranking.'),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _retry,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.requireData;
          if (data.entries.isEmpty) {
            return const Center(
              child: Text('Aún no hay colaboradores en el ranking.'),
            );
          }
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Text(
                'RANKING',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.gold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aprendemos juntos',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Una comunidad que crece contigo. Posiciones por puntos de aprendizaje, no por riesgo.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (data.myPosition != null)
                _PositionCard(
                  position: data.myPosition!,
                  total: data.entries.length,
                  points: _currentUserPoints(data.entries),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Clasificación de la empresa',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const Text(
                    'Puntos',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final entry in data.entries) _RankingRow(entry: entry),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});
  final RankingEntry entry;

  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: entry.isCurrentUser
        ? AppTheme.gold.withValues(alpha: 0.18)
        : null,
    leading: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 20, child: Text('${entry.position}')),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: AppTheme.gold,
          foregroundColor: AppTheme.ink,
          child: Text(_initials(entry.name)),
        ),
      ],
    ),
    title: Text(
      entry.isCurrentUser ? '${entry.name} · Tú' : entry.name,
      style: TextStyle(
        fontWeight: entry.isCurrentUser ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
    subtitle: entry.isCurrentUser ? const Text('¡Sigue aprendiendo!') : null,
    trailing: Text(
      formatPoints(entry.points),
      style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700),
    ),
  );
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final first = parts.first.isEmpty ? '' : parts.first[0];
  final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  return (first + second).toUpperCase();
}

/// Separa miles con punto, como en el mockup (1.250).
String formatPoints(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

int? _currentUserPoints(List<RankingEntry> entries) {
  for (final entry in entries) {
    if (entry.isCurrentUser) return entry.points;
  }
  return null;
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.position,
    required this.total,
    required this.points,
  });
  final int position;
  final int total;
  final int? points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppTheme.gold,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 36,
              color: AppTheme.ink,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puesto $position de $total',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (points != null)
                    Text(
                      '${formatPoints(points!)} puntos de aprendizaje',
                      style: const TextStyle(color: AppTheme.ink),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
