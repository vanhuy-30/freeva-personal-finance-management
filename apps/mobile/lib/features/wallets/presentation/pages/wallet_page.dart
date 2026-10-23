import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../viewmodels/wallet_view_model.dart';
import '../widgets/wallet_editor.dart';
import '../widgets/wallet_list_body.dart';

/// Ví của tôi (D1): total, wallets in the user's order, hidden wallets link.
/// A pushed screen, so no bottom nav.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final WalletViewModel model = getIt<WalletViewModel>();

  @override
  void initState() {
    super.initState();
    model.addListener(_changed);
    Future.microtask(model.load);
  }

  /// A write that hit a conflict leaves the list stale: fetch it again.
  void _changed() {
    if (model.needsReload && !model.busy) Future.microtask(model.load);
  }

  @override
  void dispose() {
    model.removeListener(_changed);
    super.dispose();
  }

  void _add() {
    if (model.busy || model.needsReload || model.currencies.isEmpty) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => WalletEditor(model: model)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Scaffold(
        appBar: FreevaTopBar(
          title: s.walletTitle,
          onLeading: () => context.popOrGo('/home'),
          action: FreevaIconButton(
            icon: LucideIcons.plus,
            label: s.walletAdd,
            onPressed: model.currencies.isEmpty || model.needsReload
                ? null
                : _add,
          ),
        ),
        body: BalancesHiddenBuilder(
          builder: (context, hidden) =>
              WalletListBody(model: model, hidden: hidden, onAdd: _add),
        ),
      ),
    );
  }
}
