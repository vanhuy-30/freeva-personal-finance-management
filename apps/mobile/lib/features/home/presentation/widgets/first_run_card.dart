import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/first_run_checklist.dart';

/// "Bắt đầu nào n/3": what is left to set up. Rows that are not done open
/// where to do them; "Ghi ngay" goes straight to recording.
class FirstRunCard extends StatelessWidget {
  const FirstRunCard({required this.checklist, super.key});

  final FirstRunChecklist checklist;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
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
                    style: FreevaTypography.titleM.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
              Text(
                s.onbProgress(checklist.done, checklist.total),
                style: FreevaTypography.label.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s2),
          _Item(
            label: s.checklistWallet,
            done: checklist.walletDone,
            onTap: () => context.push('/wallets'),
          ),
          _Item(
            label: s.checklistExpense,
            done: checklist.expenseDone,
            action: checklist.expenseDone
                ? null
                : FreevaButton(
                    label: s.checklistRecordNow,
                    size: FreevaButtonSize.xs,
                    variant: FreevaButtonVariant.secondary,
                    onPressed: () => context.push('/record'),
                  ),
          ),
          if (checklist.showPin)
            _Item(
              label: s.checklistPin,
              done: false,
              onTap: () => context.push('/me/security/pin-setup'),
              chevron: true,
            ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.done,
    this.onTap,
    this.action,
    this.chevron = false,
  });

  final String label;
  final bool done;
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
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? c.statusSuccessBg : Colors.transparent,
                    border: done
                        ? null
                        : Border.all(color: c.borderDefault, width: 1.5),
                  ),
                  child: done
                      ? Icon(
                          LucideIcons.check,
                          size: 14,
                          color: c.statusSuccess,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Text(
                  label,
                  style: FreevaTypography.body.copyWith(
                    color: done ? c.textSecondary : c.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (action != null) action!,
              if (chevron)
                ExcludeSemantics(
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: c.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
