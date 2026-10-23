import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/presentation/widgets/auth_gate.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import 'composer/transaction_composer_screen.dart';

class TransactionEditor extends StatefulWidget {
  const TransactionEditor({
    required this.model,
    this.transactionId,
    this.initial,
    this.copy = false,
    this.initialType,
    super.key,
  });
  final TransactionViewModel model;
  final String? transactionId;
  final TransactionBundle? initial;
  final bool copy;
  final TransactionType? initialType;
  @override
  State<TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends State<TransactionEditor> {
  TransactionBundle? bundle;
  bool loading = false;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_changed);
    bundle = widget.initial;
    if (widget.initial == null && widget.transactionId != null) {
      loading = true;
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    final value = await widget.model.open(widget.transactionId!);
    if (!mounted) return;
    setState(() {
      bundle = value;
      loading = false;
      failed = value == null;
    });
  }

  void _changed() {
    if (widget.model.wallets.isNotEmpty || widget.model.busy) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    widget.model.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AuthGate(
      child: loading || failed
          ? Scaffold(
              appBar: FreevaTopBar(
                title: s.transactionEdit,
                kind: FreevaTopBarKind.modal,
              ),
              body: Center(
                child: loading
                    ? const CircularProgressIndicator()
                    : ErrorRetry(
                        title: s.transactionError,
                        message: s.homeErrorBody,
                        onRetry: _load,
                      ),
              ),
            )
          : TransactionComposerScreen(
              model: widget.model,
              existing: bundle,
              copy: widget.copy,
              initialType: widget.initialType,
            ),
    );
  }
}
