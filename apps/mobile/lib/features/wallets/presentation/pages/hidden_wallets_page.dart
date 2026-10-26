import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../domain/wallet.dart';
import '../viewmodels/wallet_view_model.dart';
import '../widgets/hidden_wallet_row.dart';

/// Ví đã ẩn (D, màn 9): muted rows with "Khôi phục".
class HiddenWalletsPage extends StatelessWidget {
  const HiddenWalletsPage({super.key});

  Future<void> _restore(
    BuildContext context,
    WalletViewModel model,
    Wallet wallet,
  ) async {
    final s = S.of(context);
    if (await model.archive(wallet) && context.mounted) {
      showFreevaToast(
        context,
        message: s.walletRestored(wallet.draft.name),
        icon: LucideIcons.check,
        aboveNav: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final model = getIt<WalletViewModel>();
    final margin = context.screenMargin;
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.walletHiddenTitle,
        onLeading: () => context.popOrGo('/wallets'),
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          final items = model.hidden;
          return ListView(
            padding: EdgeInsets.fromLTRB(margin, 0, margin, FreevaSpace.s8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, FreevaSpace.s4),
                child: Text(
                  s.walletHiddenHint,
                  style: FreevaTypography.body.copyWith(
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
              ),
              if (items.isEmpty)
                EmptyState(title: s.walletHiddenEmpty)
              else
                FreevaCard(
                  list: true,
                  padding: const EdgeInsets.fromLTRB(
                    FreevaSpace.s4,
                    FreevaSpace.s1,
                    FreevaSpace.s3,
                    FreevaSpace.s1,
                  ),
                  child: BalancesHiddenBuilder(
                    builder: (context, hidden) => Column(
                      children: [
                        for (final (i, w) in items.indexed) ...[
                          if (i > 0) Divider(height: 1, color: c.listDivider),
                          HiddenWalletRow(
                            wallet: w,
                            minorDigits: model.currencyOf(w)?.minorDigits ?? 0,
                            hidden: hidden,
                            busy: model.busy,
                            onRestore: () => _restore(context, model, w),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
