import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/loan.dart';
import 'loan_labels.dart';

/// Radio chip of the loan kind: 44 high, 28 tinted tile, 14 text; selected
/// has a 1.5 ink border and 600 text (LoanAdd).
class LoanKindChip extends StatelessWidget {
  const LoanKindChip({
    required this.kind,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final LoanKind kind;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = loanKindTint(context, kind);
    final shape = StadiumBorder(
      side: BorderSide(
        color: selected ? c.textPrimary : c.inputBorder,
        width: selected ? 1.5 : 1,
      ),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: c.inputBg,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 12, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(loanKindIcon(kind), size: 15, color: fg),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: FreevaTypography.bodyM.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
