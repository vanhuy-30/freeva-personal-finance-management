import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/check_mark.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/first_run_checklist.dart';

/// "Bắt đầu nào n/3" with a progress bar: what is left to set up. Rows that
/// are not done open where to do them; "Ghi ngay" goes straight to recording.
class FirstRunCard extends StatelessWidget {
  const FirstRunCard({required this.checklist, super.key});

  final FirstRunChecklist checklist;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final items = <Widget>[
      _Item(
        label: s.checklistWallet,
        done: checklist.walletDone,
        weight: FontWeight.w500,
        onTap: () => context.push('/wallets'),
      ),
      _Item(
        label: s.checklistExpense,
        done: checklist.expenseDone,
        weight: FontWeight.w600,
        action: checklist.expenseDone
            ? null
            : FreevaButton(
                label: s.checklistRecordNow,
                size: FreevaButtonSize.compact,
                onPressed: () => context.push('/record'),
              ),
      ),
      if (checklist.showPin)
        _Item(
          label: s.checklistPin,
          done: false,
          weight: FontWeight.w500,
          onTap: () => context.push('/me/security/pin-setup'),
          chevron: true,
        ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, FreevaSpace.s2),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(FreevaComponent.cardRadius),
        boxShadow: FreevaElevation.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    s.checklistTitle,
                    style: FreevaTypography.titleL.copyWith(
                      height: 1.2,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
              Text(
                s.onbProgress(checklist.done, checklist.total),
                style: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s3),
          FreevaProgressBar(
            value: checklist.done / checklist.total,
            height: 6,
            color: c.statusSuccess,
            trackColor: c.borderDivider,
          ),
          const SizedBox(height: 6),
          for (final (i, item) in items.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.listDivider),
            item,
          ],
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.done,
    required this.weight,
    this.onTap,
    this.action,
    this.chevron = false,
  });

  final String label;
  final bool done;

  /// Weight while not done (done rows are 400, struck through).
  final FontWeight weight;
  final VoidCallback? onTap;
  final Widget? action;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tap = done ? null : onTap;
    return Semantics(
      button: tap != null,
      checked: done,
      container: true,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(FreevaRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FreevaSize.touch),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: action == null ? FreevaSpace.s3 : FreevaSpace.s2,
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? c.statusSuccessBg : Colors.transparent,
                      border: done
                          ? null
                          : Border.all(
                              color: c.borderStrong,
                              width: FreevaBorder.selected,
                            ),
                    ),
                    child: done
                        ? CheckMark(
                            color: c.statusSuccess,
                            size: 13,
                            strokeWidth: 3,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: FreevaSpace.s3),
                Expanded(
                  child: Text(
                    label,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: done ? FontWeight.w400 : weight,
                      height: 1.2,
                      color: done ? c.textSecondary : c.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: c.textSecondary,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: FreevaSpace.s3),
                  action!,
                ],
                if (chevron) ...[
                  const SizedBox(width: FreevaSpace.s3),
                  ExcludeSemantics(
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: FreevaSize.iconChip,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
