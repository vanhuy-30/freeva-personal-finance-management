import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../categories/presentation/widgets/category_icon_tile.dart';
import '../../domain/recurring_rule.dart';
import 'rec_tag.dart';

/// One row of the Định kỳ và hóa đơn lists: 40 icon tile, title (+ tag),
/// second line, then either the "Đã trả" pill ([onPaid]) or the amount.
class RecurringRow extends StatelessWidget {
  const RecurringRow({
    required this.rule,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onTap,
    this.category,
    this.tag,
    this.tagBackground,
    this.tagColor,
    this.onPaid,
    this.paidLabel,
    this.minHeight = 56,
    super.key,
  });

  final RecurringRule rule;
  final FinanceCategory? category;
  final String title;
  final String subtitle;

  /// Signed text shown at the end when there is no "Đã trả" button.
  final String amount;
  final String? tag;
  final Color? tagBackground;
  final Color? tagColor;
  final VoidCallback onTap;
  final VoidCallback? onPaid;
  final String? paidLabel;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final paused = !rule.active;
    final amountColor = paused
        ? c.textDisabled
        : rule.type == 'income'
        ? c.moneyIncome
        : c.textPrimary;
    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _Tile(rule: rule, category: category, paused: paused),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary,
                            ),
                          ),
                          if (tag != null)
                            RecTag(
                              tag!,
                              background: tagBackground ?? c.bgSubtle,
                              color: tagColor ?? c.textOnWash,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (onPaid != null)
                  _PaidButton(label: paidLabel!, onTap: onPaid!)
                else
                  Text(
                    amount,
                    maxLines: 1,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.rule,
    required this.category,
    required this.paused,
  });

  final RecurringRule rule;
  final FinanceCategory? category;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (rule.type == 'expense') {
      return CategoryIconTile(
        iconToken: category?.iconToken ?? 'bills',
        colorToken: category?.colorToken,
        muted: paused,
      );
    }
    final income = rule.type == 'income';
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: paused ? c.bgSubtle : (income ? c.tintGreen : c.tintBlue),
          borderRadius: BorderRadius.circular(FreevaRadius.sm),
        ),
        child: Icon(
          income ? LucideIcons.arrowDownToLine : LucideIcons.arrowRightLeft,
          size: 18,
          color: paused
              ? c.textSecondary
              : (income ? c.tintGreenFg : c.tintBlueFg),
        ),
      ),
    );
  }
}

/// Ink pill, 32 high, 13/600 white text.
class _PaidButton extends StatelessWidget {
  const _PaidButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            widthFactor: 1,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: c.actionInk,
              ),
              child: Text(
                label,
                maxLines: 1,
                style: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textOnInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
