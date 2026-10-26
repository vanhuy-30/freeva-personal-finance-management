import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/freeva_bottom_nav.dart';

/// Root of the 4 tabs. The bottom nav lives only here, so any pushed, detail
/// or modal route (on the root navigator) hides it.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _select(int index) {
    // Tapping the current tab again returns to the tab's root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: FreevaBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: _select,
        onAdd: () => context.push('/record'),
        addLabel: s.navRecord,
        items: [
          FreevaNavItem(icon: LucideIcons.house, label: s.navOverview),
          FreevaNavItem(icon: LucideIcons.list, label: s.navTransactions),
          FreevaNavItem(icon: LucideIcons.chartPie, label: s.navReports),
          FreevaNavItem(icon: LucideIcons.user, label: s.navMe),
        ],
      ),
    );
  }
}
