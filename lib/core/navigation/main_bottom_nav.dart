import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onProfile,
    required this.onTraining,
  });

  static const profileIndex = 0;
  static const trainingIndex = 1;

  final int selectedIndex;
  final VoidCallback onProfile;
  final VoidCallback onTraining;

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
        height: 76,
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
          if (index == selectedIndex) return;
          if (index == profileIndex) onProfile();
          if (index == trainingIndex) onTraining();
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
    );
  }
}
