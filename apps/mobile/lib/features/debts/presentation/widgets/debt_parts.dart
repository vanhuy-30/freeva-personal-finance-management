import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../recurring/presentation/widgets/rec_tag.dart';
import '../../../recurring/presentation/widgets/recurring_labels.dart';

/// Round avatar with the first letter of a person's name on a tint picked
/// from the name, so the same person keeps the same colour (DebtList: 40,
/// 15/600 letter).
class NameAvatar extends StatelessWidget {
  const NameAvatar({required this.name, this.size = 40, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tints = [
      (c.tintBlue, c.tintBlueFg),
      (c.tintViolet, c.tintVioletFg),
      (c.tintCyan, c.tintCyanFg),
      (c.tintGreen, c.tintGreenFg),
    ];
    final trimmed = name.trim();
    // Vietnamese names end with the given name: "Chị Lan" → L.
    final last = trimmed.split(RegExp(r'\s+')).last;
    final letter = last.isEmpty ? '?' : last.characters.first.toUpperCase();
    final hash = trimmed.codeUnits.fold<int>(
      0,
      (a, b) => (a * 31 + b) & 0xffff,
    );
    final (bg, fg) = tints[hash % tints.length];
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(
          letter,
          style: FreevaTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            height: 1,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// "Còn N ngày" (amber) within 14 days of [due], "Quá hạn" (red) once past;
/// null otherwise. Shared by debts and loans.
RecTag? dueTag(BuildContext context, String today, String? due) {
  if (due == null) return null;
  final s = S.of(context);
  final c = context.colors;
  final days = daysBetween(today, due);
  if (days < 0) {
    return RecTag(
      s.recTagOverdue,
      background: c.statusDangerBg,
      color: c.statusDanger,
    );
  }
  if (days == 0) {
    return RecTag(
      s.recTagToday,
      background: c.statusWarningBg,
      color: c.statusWarning,
    );
  }
  if (days > 14) return null;
  return RecTag(
    s.recTagDays(days),
    background: c.statusWarningBg,
    color: c.statusWarning,
  );
}

/// Upper-case group label (12/600, 1.4 tracking) over a white list card
/// with hairline dividers; 8 between them.
class DebtGroup extends StatelessWidget {
  const DebtGroup({required this.label, required this.children, super.key});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Semantics(
            header: true,
            child: Text(
              label.toUpperCase(),
              style: FreevaTypography.sectionLabel.copyWith(
                color: c.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s2),
        DebtCard(children: children),
      ],
    );
  }
}

/// White list card (radius 20) with hairline dividers between [children].
class DebtCard extends StatelessWidget {
  const DebtCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FreevaCard(
      list: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.listDivider),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Info row: 15/500 label on the left, 14/500 value on the right (54 high).
class DebtInfoRow extends StatelessWidget {
  const DebtInfoRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                label,
                style: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One history line: 36 round icon, title, "dd/MM · vào ví", signed amount
/// (green when money came in).
class DebtHistoryRow extends StatelessWidget {
  const DebtHistoryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.incoming,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: incoming ? c.tintGreen : c.bgSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: incoming ? c.tintGreenFg : c.textOnWash,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
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
              Text(
                amount,
                maxLines: 1,
                style: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: incoming ? c.moneyIncome : c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `yyyy-MM-dd` as `dd/MM`.
String debtDay(String date) => dayMonth(date);

/// Sheet content under a centred 17/600 title, 18 apart (DebtPay, LoanPay).
class SheetTitled extends StatelessWidget {
  const SheetTitled({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 4),
      Semantics(
        header: true,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: FreevaTypography.titleL.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
      ),
      const SizedBox(height: 18),
      child,
    ],
  );
}
