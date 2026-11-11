import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../domain/credit_card_status.dart';
import '../../domain/reconcile_result.dart';
import '../../domain/wallet.dart';
import '../viewmodels/wallet_view_model.dart';
import '../../../../core/money/currency_catalog.dart';

/// "Khớp số dư" over the wallet detail (M, màn 1). The user types the real
/// balance (the real debt on a card); the server computes the difference and
/// writes one adjustment. Returns true once it is saved.
Future<bool?> showReconcileSheet(
  BuildContext context,
  WalletViewModel model,
  Wallet wallet,
) => showFreevaSheet<bool>(
  context: context,
  // The board centres its own 17/600 title, so the sheet draws it.
  titleGap: 0,
  builder: (context) => ReconcileSheet(model: model, wallet: wallet),
);

class ReconcileSheet extends StatefulWidget {
  const ReconcileSheet({required this.model, required this.wallet, super.key});

  final WalletViewModel model;
  final Wallet wallet;

  @override
  State<ReconcileSheet> createState() => _ReconcileSheetState();
}

class _ReconcileSheetState extends State<ReconcileSheet> {
  final amount = TextEditingController();
  Timer? _debounce;
  int _epoch = 0;
  bool _disposed = false;
  bool saving = false;

  /// Server answer for the value in the field; null until it arrives.
  ReconcileResult? preview;
  BigInt? _previewFor;

  /// One id per typed value, so a retry after a lost reply never doubles.
  String? _clientId;
  BigInt? _clientFor;

  Wallet get wallet => widget.wallet;
  bool get credit => wallet.draft.type == WalletType.credit;
  int get digits => widget.model.currencyOf(wallet)?.minorDigits ?? 0;

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    amount.dispose();
    super.dispose();
  }

  BigInt? _value(String locale) =>
      parseGroupedMoney(amount.text, digits, locale);

  void _typed(String locale) {
    final value = _value(locale);
    _debounce?.cancel();
    _epoch++;
    setState(() {
      preview = null;
      _previewFor = null;
    });
    if (value == null) return;
    final epoch = _epoch;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final result = await widget.model.previewReconcile(wallet, value);
      if (_disposed || epoch != _epoch) return;
      setState(() {
        preview = result;
        _previewFor = value;
      });
    });
  }

  Future<void> _submit(String locale) async {
    final s = S.of(context);
    final value = _value(locale);
    if (value == null || saving) return;
    if (_clientFor != value) {
      _clientFor = value;
      _clientId = widget.model.newClientId();
    }
    setState(() => saving = true);
    final result = await widget.model.reconcile(
      wallet,
      value,
      clientId: _clientId!,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (result == null) {
      showFreevaToast(context, message: s.walletReconcileFailed);
      return;
    }
    Navigator.of(context).pop(true);
  }

  /// What the app shows now: balance, or debt on a card.
  BigInt get _shown => credit
      ? CreditCardStatus.of(wallet, DateTime.now()).used
      : wallet.balance;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final value = _value(locale);
    final symbol = CurrencyCatalog.current.symbol(wallet.draft.currency);
    final answer = value != null && _previewFor == value ? preview : null;
    // The difference as the user reads it: against the typed number (debt on
    // a card). The colour follows the ledger: up is green, down is red.
    final ledger = answer?.deltaMinor;
    final shown = answer == null
        ? _shown
        : credit
        ? -answer.currentMinor
        : answer.currentMinor;
    final diff = value == null ? null : value - shown;
    final ready = answer != null && ledger != BigInt.zero && !saving;
    final up = ledger != null && ledger > BigInt.zero;
    final down = ledger != null && ledger < BigInt.zero;
    final stripBg = up
        ? c.statusSuccessBg
        : down
        ? c.statusDangerBg
        : c.bgSubtle;
    final stripFg = up
        ? c.statusSuccess
        : down
        ? c.statusDanger
        : c.textSecondary;
    String signed(BigInt v) =>
        '${v > BigInt.zero
            ? '+'
            : v < BigInt.zero
            ? '−'
            : ''}'
        '${formatMoneyText(v.abs(), digits, locale)}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.walletReconcileTitle(wallet.draft.name),
          textAlign: TextAlign.center,
          style: FreevaTypography.body.copyWith(
            fontSize: 17,
            height: 24 / 17,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  credit
                      ? s.walletReconcileCurrentDebt
                      : s.walletReconcileCurrent,
                  style: FreevaTypography.bodyM.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Text(
                formatMoneyText(shown, digits, locale),
                style: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Board `.fld`: 72 high, 1.5 primary border, 4 soft ring.
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
                credit ? s.walletReconcileFieldDebt : s.walletReconcileField,
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
                        signed: !credit,
                      ),
                      inputFormatters: [
                        MoneyInputFormatter(
                          minorDigits: digits,
                          locale: locale,
                          // A wallet can be overdrawn; a card's debt cannot.
                          allowNegative: !credit,
                        ),
                        LengthLimitingTextInputFormatter(20),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                      ),
                      onChanged: (_) => _typed(locale),
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
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: stripBg,
            borderRadius: BorderRadius.circular(FreevaRadius.md),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.scale, size: 18, color: stripFg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.walletReconcileDiff,
                  style: FreevaTypography.bodyM.copyWith(color: c.textPrimary),
                ),
              ),
              Text(
                answer == null || diff == null ? '—' : signed(diff),
                style: FreevaTypography.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: stripFg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            s.walletReconcileHint,
            style: FreevaTypography.bodyS.copyWith(
              height: 18 / 13,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        FreevaButton(
          label: s.walletReconcileConfirm,
          size: FreevaButtonSize.l,
          expand: true,
          loading: saving,
          onPressed: ready ? () => _submit(locale) : null,
        ),
      ],
    );
  }
}
