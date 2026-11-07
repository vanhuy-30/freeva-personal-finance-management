import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/settings_group.dart';

/// One cell of [ManageGrid].
class ManageCell {
  const ManageCell({
    required this.icon,
    required this.title,
    required this.tint,
    required this.route,
    this.value,
  });
  final IconData icon;
  final String title;
  final (Color, Color) tint;
  final String route;

  /// One short muted line; null while unknown or when there is nothing yet.
  final String? value;
}

/// QUẢN LÝ TIỀN (board `MeHome3`): tiles in three columns that open the
/// money screens. Each shows a short count or amount under its name.
class ManageGrid extends StatelessWidget {
  const ManageGrid({
    this.walletCount,
    this.budget,
    this.goalCount,
    this.debtCount,
    this.recurringCount,
    this.month,
    super.key,
  });

  /// Active wallets; null while unknown.
  final int? walletCount;

  /// Monthly budget draft in VND; null when none was typed.
  final int? budget;
  final int? goalCount;
  final int? debtCount;
  final int? recurringCount;

  /// Month shown on the calendar tile (1–12).
  final int? month;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final cells = [
      ManageCell(
        icon: LucideIcons.walletMinimal,
        title: s.meWallets,
        tint: (c.tintViolet, c.tintVioletFg),
        route: '/wallets',
        value: walletCount == null ? null : s.meWalletsCount(walletCount!),
      ),
      ManageCell(
        icon: LucideIcons.chartPie,
        title: s.meBudgetShort,
        tint: (c.statusWarningBg, c.statusWarning),
        route: '/budgets',
        value: budget == null || budget! <= 0
            ? null
            : formatMoneyText(BigInt.from(budget!), 0, s.localeName),
      ),
      ManageCell(
        icon: LucideIcons.target,
        title: s.meGoals,
        tint: (c.tintViolet, c.tintVioletFg),
        route: '/me/goals',
        value: goalCount == null || goalCount == 0
            ? null
            : s.meGoalsCount(goalCount!),
      ),
      ManageCell(
        icon: LucideIcons.handHelping,
        title: s.meDebts,
        tint: (c.tintGreen, c.tintGreenFg),
        route: '/me/debts',
        value: debtCount == null || debtCount == 0
            ? null
            : s.meDebtsCount(debtCount!),
      ),
      ManageCell(
        icon: LucideIcons.refreshCw,
        title: s.meRecurring,
        tint: (c.statusWarningBg, c.statusWarning),
        route: '/me/recurring',
        value: recurringCount == null || recurringCount == 0
            ? null
            : s.meRecurringCount(recurringCount!),
      ),
      ManageCell(
        icon: LucideIcons.calendarDays,
        title: s.meCalendarShort,
        tint: (c.tintBlue, c.tintBlueFg),
        route: '/me/calendar',
        value: month == null ? null : s.meCalendarMonth(month!),
      ),
      ManageCell(
        icon: LucideIcons.chartLine,
        title: s.meNetWorth,
        tint: (c.tintGreen, c.tintGreenFg),
        route: '/me/net-worth',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(s.meGroupManage),
        LayoutBuilder(
          builder: (context, box) {
            // 320 pt at large text: two columns keep names on one line.
            final columns = box.maxWidth < 300 ? 2 : 3;
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
}

class _Tile extends StatelessWidget {
  const _Tile({required this.cell});
  final ManageCell cell;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = cell.tint;
    return FreevaCard(
      padding: const EdgeInsets.all(12),
      semanticsLabel: cell.value == null
          ? cell.title
          : '${cell.title}, ${cell.value}',
      onTap: () => context.push(cell.route),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: SizedBox.square(
                dimension: 36,
                child: Icon(cell.icon, size: 18, color: fg),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              cell.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FreevaTypography.bodyM.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              cell.value ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
