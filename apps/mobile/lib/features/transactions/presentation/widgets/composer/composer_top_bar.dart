import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_icon_button.dart';
import '../../../../../core/widgets/freeva_segmented.dart';
import '../../../domain/transaction.dart';
import '../../viewmodels/transaction_composer.dart';
import '../transaction_naming.dart';

/// Close on the left; Chi · Thu · Chuyển for a new transaction, or
/// "Sửa khoản chi" when editing (type is locked).
class ComposerTopBar extends StatelessWidget {
  const ComposerTopBar({
    required this.composer,
    required this.onClose,
    super.key,
  });

  final TransactionComposer composer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final naming = TransactionNaming(
      s,
      categories: const [],
      wallets: const [],
    );
    return SizedBox(
      height: FreevaSize.touch,
      child: Row(
        children: [
          FreevaIconButton(
            icon: LucideIcons.x,
            label: s.commonClose,
            onPressed: onClose,
          ),
          Expanded(
            child: Center(
              child: composer.isNew
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: FreevaSegmented<TransactionType>(
                        segments: [
                          FreevaSegment(
                            TransactionType.expense,
                            s.transactionExpense,
                          ),
                          FreevaSegment(
                            TransactionType.income,
                            s.transactionIncome,
                          ),
                          FreevaSegment(
                            TransactionType.transfer,
                            s.transactionTransfer,
                          ),
                        ],
                        selected: composer.type,
                        onChanged: composer.setType,
                      ),
                    )
                  : Semantics(
                      header: true,
                      child: Text(
                        s.txEditTitle(naming.kind(composer.type)),
                        style: FreevaTypography.titleL.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: FreevaSize.touch),
        ],
      ),
    );
  }
}
