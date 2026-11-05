import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../domain/transaction.dart';

/// "Xoá khoản chi này?" for an expense that has refunds (M, màn 4,
/// `TxRefundDelete`). [refunded] is already formatted. Null when cancelled.
Future<RefundDisposition?> showRefundDeletePopup(
  BuildContext context, {
  required String refunded,
}) => showDialog<RefundDisposition>(
  context: context,
  builder: (_) => _RefundDeletePopup(refunded: refunded),
);

class _RefundDeletePopup extends StatefulWidget {
  const _RefundDeletePopup({required this.refunded});

  final String refunded;

  @override
  State<_RefundDeletePopup> createState() => _RefundDeletePopupState();
}

class _RefundDeletePopupState extends State<_RefundDeletePopup> {
  RefundDisposition choice = RefundDisposition.cascade;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: FreevaDialogIcon(icon: LucideIcons.trash)),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              s.refundDeleteTitle,
              textAlign: TextAlign.center,
              style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.refundDeleteBody(widget.refunded),
            textAlign: TextAlign.center,
            style: FreevaTypography.body.copyWith(
              fontSize: 14,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: FreevaSpace.s4),
          _RadioCard(
            title: s.refundDeleteCascade,
            hint: s.refundDeleteCascadeSub(widget.refunded),
            selected: choice == RefundDisposition.cascade,
            onTap: () => setState(() => choice = RefundDisposition.cascade),
          ),
          const SizedBox(height: FreevaSpace.s2),
          _RadioCard(
            title: s.refundDeleteKeep,
            hint: s.refundDeleteKeepSub,
            selected: choice == RefundDisposition.keep,
            onTap: () => setState(() => choice = RefundDisposition.keep),
          ),
          const SizedBox(height: FreevaSpace.s4),
          Row(
            children: [
              Expanded(
                child: FreevaButton(
                  label: s.commonCancel,
                  variant: FreevaButtonVariant.secondary,
                  size: FreevaButtonSize.dialog,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: FreevaButton(
                  label: s.categoryDeleteShort,
                  variant: FreevaButtonVariant.destructive,
                  size: FreevaButtonSize.dialog,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(choice),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Board radio card: radius 16, padding 12/14, 22 radio, title 15/600 and a
/// 12 hint that wraps; selected = 1.5 primary border on a light blue wash.
class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaRadius.md);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      container: true,
      excludeSemantics: true,
      label: '$title, $hint',
      onTap: onTap,
      child: Material(
        color: selected
            ? Color.lerp(c.bgSurface, c.tintBlue, .5)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? c.actionPrimary : c.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? c.actionPrimary : c.borderStrong,
                      width: selected ? 6 : 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: FreevaTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
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
