import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onProfile,
    required this.onTraining,
    this.onRanking,
  });

  static const profileIndex = 0;
  static const trainingIndex = 1;
  static const rankingIndex = 2;

  final int selectedIndex;
  final VoidCallback onProfile;
  final VoidCallback onTraining;
  // Null deshabilita la pestaña (por ejemplo, en modo demo sin sesión).
  final VoidCallback? onRanking;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppTheme.gold : AppTheme.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: NavigationBar(
        height: 66,
        selectedIndex: selectedIndex,
        backgroundColor: colors.surfaceContainerLow,
        indicatorColor: AppTheme.gold,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            color: states.contains(WidgetState.selected)
                ? accent
                : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
        onDestinationSelected: (index) {
          if (index == profileIndex) onProfile();
          if (index == trainingIndex) onTraining();
          if (index == rankingIndex) onRanking?.call();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_outline, color: AppTheme.ink),
            label: 'Perfil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_outlined, color: AppTheme.ink),
            label: 'Capacitación',
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(
              Icons.emoji_events_outlined,
              color: AppTheme.ink,
            ),
            label: 'Ranking',
            enabled: onRanking != null,
            tooltip: onRanking == null ? 'Ranking · Inicia sesión' : null,
          ),
        ],
      ),
    );
  }
}
