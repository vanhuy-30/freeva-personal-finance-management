import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/wallet_view_model.dart';
import '../widgets/wallet_editor.dart';
import '../widgets/wallet_list.dart';
import '../widgets/wallet_labels.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final WalletViewModel model;
  bool archived = false;
  @override
  void initState() {
    super.initState();
    model = getIt<WalletViewModel>();
    Future.microtask(model.load);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      return Scaffold(
        appBar: AppBar(
          title: Text(s.walletTitle),
          leading: IconButton(
            tooltip: s.profileBack,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (model.busy) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(s.walletShowHidden),
                      value: archived,
                      onChanged: (v) => setState(() => archived = v),
                    ),
                    if (model.failure != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          walletError(s, model.failure!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (model.needsReload) Text(s.walletReloadRequired),
                    Wrap(
                      spacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: model.busy ? null : model.load,
                          child: Text(s.profileReload),
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(s.walletAdd),
                          onPressed:
                              model.busy ||
                                  model.needsReload ||
                                  model.currencies.isEmpty
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => WalletEditor(model: model),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: WalletList(model: model, archived: archived),
              ),
            ],
          ),
        ),
      );
    },
  );
}
