import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/profile_repository.dart';
import 'profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.repository,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onTraining,
    required this.onLesson,
    required this.onLogout,
  });
  final ProfileRepository repository;
  final ValueListenable<ThemeMode> themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onTraining;
  final VoidCallback onLesson;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _model;

  @override
  void initState() {
    super.initState();
    _model = ProfileViewModel(widget.repository)..load();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _settings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'A tu manera',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              const Text('Apariencia'),
              const SizedBox(height: 12),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: widget.themeMode,
                builder: (context, mode, _) => Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final option in [
                      (ThemeMode.light, 'Claro', Icons.light_mode_outlined),
                      (ThemeMode.dark, 'Oscuro', Icons.dark_mode_outlined),
                      (ThemeMode.system, 'Sistema', Icons.devices_outlined),
                    ])
                      ChoiceChip(
                        label: Text(option.$2),
                        avatar: Icon(option.$3, size: 18),
                        selected: mode == option.$1,
                        onSelected: (_) => widget.onThemeChanged(option.$1),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  widget.onLogout();
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outline)),
        ),
        child: NavigationBar(
          height: 76,
          selectedIndex: 0,
          backgroundColor: colors.surfaceContainerLow,
          indicatorColor: AppTheme.gold,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              color: states.contains(WidgetState.selected)
                  ? _accent(context)
                  : colors.onSurfaceVariant,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
          onDestinationSelected: (index) {
            if (index == 1) widget.onTraining();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_outline, color: AppTheme.ink),
              label: 'Perfil',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              label: 'Capacitación',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Ranking',
              enabled: false,
              tooltip: 'Ranking · Próximamente',
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            if (_model.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_model.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_model.errorMessage!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _model.load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final profile = _model.profile!;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PHISHWARDEN MJ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppTheme.gold
                                        : AppTheme.ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Mi perfil',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontSize: 28),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _settings,
                            tooltip: 'Ajustes',
                            icon: Icon(
                              Icons.settings_outlined,
                              color: colors.onSurfaceVariant,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _Identity(profile: profile),
                      const SizedBox(height: 20),
                      _RiskCard(profile: profile),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cards = [
                            _MetricCard(
                              title: 'PUNTOS DE APRENDIZAJE',
                              value: '${profile.learningPoints ?? '—'} pts',
                              description: profile.learningPoints == null
                                  ? 'Puntos aún no disponibles'
                                  : 'Cada práctica cuenta',
                              showProgress: true,
                            ),
                            _MetricCard(
                              title: 'RACHA SEGURA',
                              value: '${profile.safeDays ?? '—'} días',
                              icon: Icons.local_fire_department_outlined,
                              description: profile.safeDays == null
                                  ? 'Racha aún no disponible'
                                  : 'Sigue aprendiendo a tu ritmo',
                            ),
                          ];
                          if (constraints.maxWidth < 300 ||
                              MediaQuery.textScalerOf(context).scale(14) > 21) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                cards[0],
                                const SizedBox(height: 12),
                                cards[1],
                              ],
                            );
                          }
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 12),
                                Expanded(child: cards[1]),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(
                        title: 'Tus simulaciones',
                        action: 'Ver historial',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SimulationCount(
                              value: profile.simulationsReceived,
                              label: 'Recibidas',
                            ),
                          ),
                          Expanded(
                            child: _SimulationCount(
                              value: profile.simulationsWithInteraction,
                              label: 'Con interacción',
                            ),
                          ),
                          Expanded(
                            child: _SimulationCount(
                              value: profile.simulationsWithoutInteraction,
                              label: 'Sin interacción',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: widget.onLesson,
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mail_outline,
                                  size: 23,
                                  color: _accent(context),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MICROLECCIÓN DE PRÁCTICA',
                                        style: TextStyle(
                                          fontSize: 10,
                                          height: 1.1,
                                          fontWeight: FontWeight.w700,
                                          color: _accent(context),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Reconoce un correo de phishing',
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                      ),
                                      Text(
                                        '1–2 min · Incluye una pregunta',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  color: _accent(context),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(
                        title: 'Tus medallas',
                        action: 'Ver logros',
                        status: 'Sin datos',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final badge in [
                            (Icons.directions_walk_outlined, 'Primer paso'),
                            (
                              Icons.local_fire_department_outlined,
                              'Racha de 3',
                            ),
                            (Icons.visibility_outlined, 'Ojo atento'),
                          ])
                            Expanded(
                              child: Column(
                                children: [
                                  Icon(
                                    badge.$1,
                                    color: colors.onSurfaceVariant,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    badge.$2,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Riesgo, progreso, simulaciones y medallas aún no disponibles.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Color _accent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? AppTheme.gold
    : AppTheme.ink;

class _Identity extends StatelessWidget {
  const _Identity({required this.profile});
  final EmployeeProfile profile;
  @override
  Widget build(BuildContext context) {
    // No deducimos el nombre real a partir del correo.
    final name = profile.name;
    final initialSource = name?.trim().isNotEmpty == true
        ? name!.trim()
        : profile.email.trim();
    final initial = initialSource.isEmpty
        ? '?'
        : initialSource.characters.first;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.gold,
          child: Text(
            initial.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name == null ? 'Hola, bienvenido' : 'Hola, $name',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  Text(
                    profile.companyName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text('·', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    profile.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (profile.department != null)
                    Text(
                      profile.department!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.profile});
  final EmployeeProfile profile;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              const Text(
                'Tu riesgo individual',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.riskLabel ?? 'Sin datos',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _accent(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '${profile.riskScore ?? '—'}',
                style: TextStyle(
                  fontSize: 42,
                  height: 1,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              Text(
                profile.riskScore == null
                    ? 'Pendiente de evaluación'
                    : 'Cada lección cuenta',
                style: TextStyle(fontSize: 10, color: _accent(context)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sin un score confirmado, la barra queda neutra y no representa 0.
          if (profile.riskScore == null)
            Semantics(
              label: 'Riesgo individual no disponible',
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            LinearProgressIndicator(
              value: profile.riskScore!.clamp(0, 100) / 100,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: theme.colorScheme.outline,
              color: switch (profile.riskLabel?.toLowerCase()) {
                'bajo' => dark ? const Color(0xFF93D2AD) : AppTheme.lowRisk,
                'medio' => dark ? const Color(0xFFFFD166) : AppTheme.mediumRisk,
                'alto' => dark ? const Color(0xFFEF8E8E) : AppTheme.highRisk,
                _ => AppTheme.gold,
              },
              semanticsLabel: 'Riesgo individual',
              semanticsValue: '${profile.riskScore!.clamp(0, 100)}',
            ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 5,
            children: [
              _RiskLegend(
                label: 'Bajo',
                color: dark ? const Color(0xFF93D2AD) : AppTheme.lowRisk,
              ),
              _RiskLegend(
                label: 'Medio',
                color: dark ? const Color(0xFFFFD166) : AppTheme.mediumRisk,
              ),
              _RiskLegend(
                label: 'Alto',
                color: dark ? const Color(0xFFEF8E8E) : AppTheme.highRisk,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Menor riesgo es mejor. No son puntos ganados.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _RiskLegend extends StatelessWidget {
  const _RiskLegend({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.description,
    this.icon,
    this.showProgress = false,
  });
  final String title;
  final String value;
  final String description;
  final IconData? icon;
  final bool showProgress;
  @override
  Widget build(BuildContext context) => _ProfileCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: _accent(context), size: 20),
              const SizedBox(width: 5),
            ],
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 23),
              ),
            ),
          ],
        ),
        if (showProgress) ...[
          const SizedBox(height: 9),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
        const SizedBox(height: 9),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, this.status});
  final String title;
  final String action;
  final String? status;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 10,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      if (status != null)
        Text(
          status!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      Tooltip(
        message: '$action · Próximamente',
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: null,
          child: Text(action, style: const TextStyle(fontSize: 11)),
        ),
      ),
    ],
  );
}

class _SimulationCount extends StatelessWidget {
  const _SimulationCount({required this.value, required this.label});
  final int? value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${value ?? '—'}',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 21),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
      ),
    ],
  );
}
