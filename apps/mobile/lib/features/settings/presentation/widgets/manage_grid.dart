import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/settings_group.dart';

/// One tile of [ManageGrid].
class ManageCell {
  const ManageCell({
    required this.icon,
    required this.title,
    required this.tint,
    required this.route,
  });
  final IconData icon;
  final String title;
  final (Color, Color) tint;
  final String route;
}

/// TÀI SẢN and KẾ HOẠCH (board `MeHome`): two rows of four tiles that open
/// the money screens. What you have and owe, then what you plan.
class ManageGrid extends StatelessWidget {
  const ManageGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final assets = [
      ManageCell(
        icon: LucideIcons.walletMinimal,
        title: s.meWallets,
        tint: (c.tintViolet, c.tintVioletFg),
        route: '/wallets',
      ),
      ManageCell(
        icon: LucideIcons.chartLine,
        title: s.meNetWorth,
        tint: (c.tintGreen, c.tintGreenFg),
        route: '/me/net-worth',
      ),
      ManageCell(
        icon: LucideIcons.trendingUp,
        title: s.meInvestments,
        tint: (c.tintBlue, c.tintBlueFg),
        route: '/me/investments',
      ),
      ManageCell(
        icon: LucideIcons.handHelping,
        title: s.meDebts,
        tint: (c.tintGreen, c.tintGreenFg),
        route: '/me/debts',
      ),
    ];
    final plans = [
      ManageCell(
        icon: LucideIcons.chartPie,
        title: s.meBudgetShort,
        tint: (c.statusWarningBg, c.statusWarning),
        route: '/budgets',
      ),
      ManageCell(
        icon: LucideIcons.target,
        title: s.meGoals,
        tint: (c.tintViolet, c.tintVioletFg),
        route: '/me/goals',
      ),
      ManageCell(
        icon: LucideIcons.refreshCw,
        title: s.meRecurring,
        tint: (c.statusWarningBg, c.statusWarning),
        route: '/me/recurring',
      ),
      ManageCell(
        icon: LucideIcons.calendarDays,
        title: s.meCalendarShort,
        tint: (c.tintBlue, c.tintBlueFg),
        route: '/me/calendar',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(title: s.meGroupAssets, cells: assets),
        _Section(title: s.meGroupPlans, cells: plans),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.cells});
  final String title;
  final List<ManageCell> cells;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHeader(title),
      LayoutBuilder(
        builder: (context, box) {
          // Four across when each name fits on one line ("Tài sản ròng" is
          // the longest); narrow phones or large text get two.
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final columns = (box.maxWidth - 3 * 8) / 4 >= 78 * scale ? 4 : 2;
          final width = (box.maxWidth - (columns - 1) * 8) / columns;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cell in cells)
                SizedBox(
                  width: width,
                  child: _Tile(cell: cell),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.cell});
  final ManageCell cell;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = cell.tint;
    return FreevaCard(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      semanticsLabel: cell.title,
      onTap: () => context.push(cell.route),
      child: ExcludeSemantics(
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox.square(
                dimension: 40,
                child: Icon(cell.icon, size: 18, color: fg),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cell.title,
              textAlign: TextAlign.center,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
