import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../viewmodels/transaction_view_model.dart';
import '../widgets/transaction_editor.dart';

/// Target of the + button: opens the transaction editor as a modal, without
/// the transaction list underneath.
class RecordTransactionPage extends StatefulWidget {
  const RecordTransactionPage({super.key});

  @override
  State<RecordTransactionPage> createState() => _RecordTransactionPageState();
}

class _RecordTransactionPageState extends State<RecordTransactionPage> {
  late final TransactionViewModel model = getIt<TransactionViewModel>();

  @override
  void initState() {
    super.initState();
    if (!model.composerReady) Future.microtask(model.load);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      if (model.composerReady && model.preferredAccountId() != null) {
        return TransactionEditor(model: model);
      }
      final waiting = !model.composerReady && model.failure == null;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.transactionRecord,
          kind: FreevaTopBarKind.modal,
        ),
        body: Center(
          child: waiting
              ? const CircularProgressIndicator()
              : EmptyState(
                  title: s.transactionNoWallet,
                  actionLabel: s.transactionCreateWallet,
                  onAction: () => context.pushReplacement('/wallets'),
                ),
        ),
      );
    },
  );
}
