import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import '../../../sync/presentation/widgets/sync_status_banner.dart';
import '../widgets/transaction_editor.dart';
import '../widgets/transaction_labels.dart';
import '../widgets/transaction_list.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({this.record = false, super.key});
  final bool record;
  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  late final TransactionViewModel model;
  final search = TextEditingController();
  bool prompted = false;

  @override
  void initState() {
    super.initState();
    model = getIt<TransactionViewModel>();
    model.addListener(_maybeRecord);
    Future.microtask(model.load);
  }

  void _maybeRecord() {
    if (!widget.record || prompted || model.busy) return;
    if (model.preferredAccountId() == null) return;
    prompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openNew();
    });
  }

  void _openNew() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TransactionEditor(model: model)),
    );
  }

  void _open(TransactionBundle row) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionEditor(model: model, transactionId: row.id),
      ),
    );
  }

  @override
  void dispose() {
    model.removeListener(_maybeRecord);
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      final noWallet =
          !model.busy &&
          model.failure == null &&
          model.wallets.every((wallet) => wallet.archived);
      return Scaffold(
        appBar: AppBar(
          title: Text(s.transactionTitle),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SyncStatusBanner(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    if (model.failure != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          transactionError(s, model.failure!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (model.needsReload) Text(s.transactionReloadRequired),
                    if (noWallet) ...[
                      Text(s.transactionNoWallet),
                      FilledButton(
                        onPressed: () => context.go('/wallets'),
                        child: Text(s.transactionCreateWallet),
                      ),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.transactionShowDeleted),
                      value: model.deleted,
                      onChanged: model.busy
                          ? null
                          : (value) => model.showDeleted(value),
                    ),
                    TextField(
                      controller: search,
                      decoration: InputDecoration(
                        labelText: s.transactionSearch,
                      ),
                      onSubmitted: model.busy
                          ? null
                          : (value) => model.search(value),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: Text(s.transactionAll),
                          selected: model.typeFilter == null,
                          onSelected: model.busy
                              ? null
                              : (_) {
                                  model.filterType(null);
                                },
                        ),
                        for (final type in TransactionType.values)
                          FilterChip(
                            label: Text(transactionTypeLabel(s, type)),
                            selected: model.typeFilter == type,
                            onSelected: model.busy
                                ? null
                                : (_) {
                                    model.filterType(type);
                                  },
                          ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 12,
                        children: [
                          OutlinedButton(
                            onPressed: model.busy ? null : model.load,
                            child: Text(s.profileReload),
                          ),
                          FilledButton.icon(
                            onPressed:
                                model.busy ||
                                    model.needsReload ||
                                    model.preferredAccountId() == null
                                ? null
                                : _openNew,
                            icon: const Icon(Icons.add),
                            label: Text(s.transactionRecord),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TransactionList(model: model, onOpen: _open),
              ),
            ],
          ),
        ),
      );
    },
  );
}
