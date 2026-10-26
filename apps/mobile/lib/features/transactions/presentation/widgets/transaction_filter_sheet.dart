import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../domain/transaction_filter.dart';
import '../viewmodels/transaction_view_model.dart';
import 'filter_sheet_header.dart';
import 'filter_sheet_sections.dart';

/// "Bộ lọc" sheet. Edits a draft; "Xem N giao dịch" applies it. N is
/// counted by the server for the draft, a moment after each change.
Future<TransactionFilter?> showTransactionFilterSheet(
  BuildContext context,
  TransactionViewModel model,
) => showFreevaSheet<TransactionFilter>(
  context: context,
  builder: (_) => _FilterBody(model: model),
);

class _FilterBody extends StatefulWidget {
  const _FilterBody({required this.model});
  final TransactionViewModel model;

  @override
  State<_FilterBody> createState() => _FilterBodyState();
}

class _FilterBodyState extends State<_FilterBody> {
  late TransactionFilter draft = widget.model.filter;
  int? count;
  int? deleted;
  Timer? _timer;
  int _ask = 0;

  @override
  void initState() {
    super.initState();
    _recount();
    widget.model.deletedCount().then((value) {
      if (mounted) setState(() => deleted = value);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _change(TransactionFilter value) {
    setState(() {
      draft = value;
      count = null;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 250), _recount);
  }

  Future<void> _recount() async {
    final ask = ++_ask;
    final value = await widget.model.countFor(draft);
    if (mounted && ask == _ask) setState(() => count = value);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterSheetHeader(onReset: () => _change(TransactionFilter.list)),
        Flexible(
          child: SingleChildScrollView(
            child: FilterSheetSections(
              model: widget.model,
              draft: draft,
              deleted: deleted,
              onChanged: _change,
              onOpenDeleted: () {
                Navigator.of(context).pop();
                context.push('/transactions/deleted');
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        FreevaButton(
          label: count == null
              ? s.txFilterApplyUnknown
              : s.txFilterApply(count!),
          size: FreevaButtonSize.l,
          expand: true,
          onPressed: () => Navigator.of(context).pop(draft),
        ),
      ],
    );
  }
}
