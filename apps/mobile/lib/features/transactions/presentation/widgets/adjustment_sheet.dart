import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import 'transaction_labels.dart';
import '../../../../core/money/currency_catalog.dart';

/// Changes the signed amount of a balance adjustment (from the wallet's
/// "Khớp số dư"). Same look as that sheet: one big field, one hint, one
/// button. Returns true once saved.
Future<bool?> showAdjustmentSheet(
  BuildContext context,
  TransactionViewModel model,
  TransactionBundle bundle,
) => showFreevaSheet<bool>(
  context: context,
  titleGap: 0,
  builder: (_) => AdjustmentSheet(model: model, bundle: bundle),
);

class AdjustmentSheet extends StatefulWidget {
  const AdjustmentSheet({required this.model, required this.bundle, super.key});

  final TransactionViewModel model;
  final TransactionBundle bundle;

  @override
  State<AdjustmentSheet> createState() => _AdjustmentSheetState();
}

class _AdjustmentSheetState extends State<AdjustmentSheet> {
  bool saving = false;

  TxLeg get leg => widget.bundle.legs.first;
  int get digits =>
      widget.model.currencies
          .where((x) => x.code == leg.currencyCode)
          .map((x) => x.minorDigits)
          .firstOrNull ??
      0;

  final amount = TextEditingController();
  bool _filled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    final locale = Localizations.localeOf(context).toString();
    amount.text = formatMoneyText(leg.amountMinor, digits, locale);
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  BigInt? _value(String locale) =>
      parseGroupedMoney(amount.text, digits, locale);

  Future<void> _submit(String locale) async {
    final s = S.of(context);
    final value = _value(locale);
    if (value == null || saving) return;
    setState(() => saving = true);
    final saved = await widget.model.adjust(widget.bundle, value);
    if (!mounted) return;
    setState(() => saving = false);
    if (!saved) {
      final error = widget.model.failure;
      showFreevaToast(
        context,
        message: error == null
            ? s.transactionError
            : transactionError(s, error),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final value = _value(locale);
    final symbol = CurrencyCatalog.current.symbol(leg.currencyCode);
    final ready =
        value != null && value != BigInt.zero && value != leg.amountMinor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.txAdjustEditTitle,
          textAlign: TextAlign.center,
          style: FreevaTypography.body.copyWith(
            fontSize: 17,
            height: 24 / 17,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: c.inputBg,
            borderRadius: BorderRadius.circular(FreevaRadius.md),
            border: Border.all(color: c.actionPrimary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: c.focusRing.withValues(alpha: .18),
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.txAdjustAmount,
                style: FreevaTypography.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amount,
                      autofocus: true,
                      cursorColor: c.actionPrimary,
                      style: FreevaTypography.titleL.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: digits > 0,
                        signed: true,
                      ),
                      inputFormatters: [
                        MoneyInputFormatter(
                          minorDigits: digits,
                          locale: locale,
                          allowNegative: true,
                        ),
                        LengthLimitingTextInputFormatter(21),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Text(
                    symbol,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            s.txAdjustHint,
            style: FreevaTypography.bodyS.copyWith(
              height: 18 / 13,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        FreevaButton(
          label: s.txSaveChanges,
          size: FreevaButtonSize.l,
          expand: true,
          loading: saving,
          onPressed: ready ? () => _submit(locale) : null,
        ),
      ],
    );
  }
}
