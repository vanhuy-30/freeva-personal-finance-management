import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../domain/wallet.dart';
import '../viewmodels/wallet_detail_view_model.dart';
import '../viewmodels/wallet_view_model.dart';
import '../widgets/detail/wallet_detail_body.dart';
import '../widgets/wallet_editor.dart';

/// One wallet or credit card (D, màn 3 / 4). Pushed, no bottom nav.
class WalletDetailPage extends StatefulWidget {
  const WalletDetailPage({required this.walletId, super.key});

  final String walletId;

  @override
  State<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends State<WalletDetailPage> {
  late final WalletViewModel model = getIt<WalletViewModel>();
  late final TransactionViewModel main = getIt<TransactionViewModel>();
  late final WalletDetailViewModel detail = getIt<WalletDetailViewModel>(
    param1: widget.walletId,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (model.wallets.isEmpty) await model.load();
      if (!main.composerReady) await main.load();
      await detail.reload();
    });
  }

  @override
  void dispose() {
    detail.dispose();
    super.dispose();
  }

  /// Balances and history both change after a record, edit or delete.
  Future<void> _refresh() async {
    await Future.wait([model.load(), detail.reload()]);
  }

  Future<void> _record(WalletRecordAction action) async {
    final id = widget.walletId;
    await context.push(switch (action) {
      WalletRecordAction.record => '/record?from=$id',
      WalletRecordAction.transfer => '/record?type=transfer&from=$id',
      WalletRecordAction.payCard => '/record?type=transfer&to=$id',
    });
    if (mounted) await _refresh();
  }

  Future<void> _edit(Wallet wallet) async {
    if (model.busy || model.needsReload || model.currencies.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalletEditor(model: model, wallet: wallet),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([model, main, detail]),
      builder: (context, _) {
        final wallet = model.byId(widget.walletId);
        void back() => context.popOrGo('/wallets');
        if (wallet == null) {
          return Scaffold(
            appBar: FreevaTopBar(title: s.walletTitle, onLeading: back),
            body: Center(
              child: model.busy || model.wallets.isEmpty
                  ? const CircularProgressIndicator()
                  : EmptyState(title: s.walletNotFound),
            ),
          );
        }
        final credit = wallet.draft.type == WalletType.credit;
        return Scaffold(
          appBar: FreevaTopBar(
            title: wallet.draft.name,
            onLeading: back,
            action: FreevaIconButton(
              icon: LucideIcons.pencil,
              label: credit ? s.walletEditCard : s.walletEdit,
              onPressed: () => _edit(wallet),
            ),
          ),
          body: BalancesHiddenBuilder(
            builder: (context, hidden) => WalletDetailBody(
              wallet: wallet,
              minorDigits: model.currencyOf(wallet)?.minorDigits ?? 0,
              today: model.today,
              hidden: hidden,
              main: main,
              detail: detail,
              onRecord: _record,
              onRefresh: _refresh,
            ),
          ),
        );
      },
    );
  }
}
