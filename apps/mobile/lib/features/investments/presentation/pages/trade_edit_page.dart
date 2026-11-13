import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../auth/presentation/widgets/auth_message.dart';
import '../../../net_worth/presentation/widgets/net_worth_labels.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../transactions/presentation/widgets/composer/date_picker_sheet.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../../domain/investment.dart';
import '../viewmodels/investment_view_model.dart';
import '../widgets/investment_labels.dart';
import '../widgets/investment_wallet_list.dart';
import '../widgets/trade_delete_sheet.dart';
import '../../../../core/money/currency_catalog.dart';

/// Sửa lần mua (board P.7): quantity, price, date, wallet and note of one
/// buy. The server replays the position, so later sales' profit is
/// recomputed; selling more than what is left is refused.
class TradeEditPage extends StatefulWidget {
  const TradeEditPage({required this.id, required this.tradeId, super.key});

  final String id;
  final String tradeId;

  @override
  State<TradeEditPage> createState() => _TradeEditPageState();
}

class _TradeEditPageState extends State<TradeEditPage> {
  late final InvestmentViewModel model = getIt<InvestmentViewModel>();
  final quantity = TextEditingController();
  final price = TextEditingController();
  final note = TextEditingController();
  String tradedOn = '';
  String? walletId;
  bool ready = false;
  bool saving = false;

  Investment? get inv => model.byId(widget.id);
  InvestmentTrade? get trade => model.tradeById(widget.id, widget.tradeId);
  bool get lot => inv?.kind.singleLot ?? false;
  int get digits =>
      model.digitsOf(inv?.currencyCode ?? CurrencyCatalog.current.defaultCode);

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (!model.loaded) await model.load();
    if (!mounted) return;
    await model.loadTrades([widget.id]);
    await model.loadWallets();
    if (!mounted) return;
    final t = trade;
    final i = inv;
    if (t != null && i != null) {
      final locale = Localizations.localeOf(context).toString();
      quantity.text = formatQuantity(t.quantity, locale);
      price.text = formatMoneyText(
        lot ? t.amountMinor : t.unitPriceMinor,
        digits,
        locale,
      );
      note.text = t.note ?? '';
      tradedOn = t.tradedOn;
      walletId = t.accountId;
    }
    setState(() => ready = true);
  }

  @override
  void dispose() {
    for (final c in [quantity, price, note]) {
      c.dispose();
    }
    super.dispose();
  }

  BigInt? _quantity(String locale) => lot
      ? quantityOne
      : parseGroupedMoney(quantity.text, quantityDigits, locale);

  BigInt? _price(String locale) =>
      parseGroupedMoney(price.text, digits, locale);

  BigInt? _total(String locale) {
    final p = _price(locale);
    if (lot) return p;
    final q = _quantity(locale);
    return p == null || q == null ? null : quantityTotalMinor(q, p);
  }

  bool _valid(String locale) {
    final q = _quantity(locale);
    final p = _price(locale);
    return !saving &&
        q != null &&
        q > BigInt.zero &&
        p != null &&
        p > BigInt.zero;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePickerSheet(
      context,
      value: tradedOn,
      today: model.today,
    );
    if (picked != null) setState(() => tradedOn = picked);
  }

  Future<void> _pickWallet(bool hidden) async {
    // A sentinel tells "đã có từ trước" (null) from a dismissed sheet.
    const none = '\u0000';
    final picked = await showFreevaSheet<String>(
      context: context,
      title: S.of(context).investmentFromWallet,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: InvestmentWalletList(
          wallets: [
            for (final w in model.wallets)
              if (w.draft.currency == inv?.currencyCode) w,
          ],
          selected: walletId,
          digitsOf: model.digitsOf,
          hidden: hidden,
          onChanged: (id) => Navigator.of(sheet).pop(id ?? none),
        ),
      ),
    );
    if (picked == null) return;
    setState(() => walletId = picked == none ? null : picked);
  }

  Future<void> _save(String locale) async {
    final s = S.of(context);
    final i = inv!;
    setState(() => saving = true);
    final ok = await model.updateTrade(
      i,
      widget.tradeId,
      TradeEdit(
        quantity: _quantity(locale)!,
        priceMinor: lot ? null : _price(locale),
        amountMinor: lot ? _price(locale) : null,
        accountId: walletId,
        tradedOn: tradedOn,
        note: note.text,
      ),
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      context.popOrGo('/me/investments');
      return;
    }
    final failure = model.failure;
    showFreevaToast(
      context,
      message: failure == null ? s.meSaveError : authFailureText(s, failure),
    );
  }

  Future<void> _delete() async {
    final s = S.of(context);
    final i = inv!;
    final t = trade!;
    final locale = Localizations.localeOf(context).toString();
    final yes = await showTradeDeleteSheet(
      context,
      date: investmentDateBox(t.tradedOn).$1,
      line: s.tradeDeleteLine(
        investmentQuantityText(s, t.quantity, i.unit, locale),
        i.name,
      ),
      walletName: model.wallets
          .where((w) => w.id == t.accountId)
          .firstOrNull
          ?.draft
          .name,
      amountMinor: t.amountMinor,
      digits: digits,
    );
    if (!yes || !mounted) return;
    final ok = await model.deleteBuy(i, t.id);
    if (!mounted) return;
    if (ok) {
      context.popOrGo('/me/investments');
      return;
    }
    final failure = model.failure;
    showFreevaToast(
      context,
      message: failure == null ? s.meSaveError : authFailureText(s, failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    final locale = Localizations.localeOf(context).toString();
    return BalancesHiddenBuilder(
      builder: (context, hidden) => Scaffold(
        appBar: FreevaTopBar(
          title: s.tradeEditTitle,
          kind: FreevaTopBarKind.modal,
          onLeading: () => context.popOrGo('/me/investments'),
        ),
        body: !ready || inv == null || trade == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(child: _form(context, s, margin, hidden, locale)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(margin, 0, margin, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FreevaButton(
                          label: s.tradeSave,
                          size: FreevaButtonSize.l,
                          expand: true,
                          loading: saving,
                          onPressed: _valid(locale)
                              ? () => _save(locale)
                              : null,
                        ),
                        TextButton(
                          onPressed: _delete,
                          child: Text(
                            s.tradeDeleteLink,
                            style: FreevaTypography.bodyM.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.statusDanger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    S s,
    double margin,
    bool hidden,
    String locale,
  ) {
    final c = context.colors;
    final i = inv!;
    final total = _total(locale);
    final walletName = walletId == null
        ? s.investmentExisting
        : (model.wallets
                  .where((w) => w.id == walletId)
                  .firstOrNull
                  ?.draft
                  .name ??
              '—');
    Widget field(
      String label,
      TextEditingController controller,
      int fieldDigits, {
      String? suffix,
    }) => FreevaTextField(
      label: label,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        MoneyInputFormatter(minorDigits: fieldDigits, locale: locale),
      ],
      tabular: true,
      suffix: suffix,
      onChanged: (_) => setState(() {}),
    );
    final priceField = field(
      lot ? s.investmentPurchasePrice : s.investmentUnitPrice(i.unit),
      price,
      digits,
      suffix: MoneyDisplay.symbolFor(i.currencyCode),
    );
    final children = <Widget>[
      if (lot)
        priceField
      else
        FormPair(
          first: field(
            s.investmentQuantity,
            quantity,
            quantityDigits,
            suffix: s.investmentUnit(i.unit),
          ),
          second: priceField,
        ),
      PickerField(
        chevron: false,
        label: s.investmentBuyDate,
        value: netWorthDate(tradedOn, locale, year: true),
        leading: FieldIconTile(
          icon: LucideIcons.calendar,
          background: c.bgSubtle,
          foreground: c.textOnWash,
        ),
        onTap: _pickDate,
      ),
      if (!lot)
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.tintBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.investmentTotalMoney,
                    style: FreevaTypography.bodyM.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                MoneyDisplay(
                  minor: total ?? BigInt.zero,
                  currency: i.currencyCode,
                  minorDigits: digits,
                  style: FreevaTypography.titleM,
                ),
              ],
            ),
          ),
        ),
      PickerField(
        label: s.investmentFromWallet,
        value: walletName,
        leading: FieldIconTile(
          icon: LucideIcons.wallet,
          background: c.tintCyan,
          foreground: c.tintCyanFg,
        ),
        onTap: () => _pickWallet(hidden),
      ),
      FreevaTextField(
        label: s.tradeNoteRow,
        controller: note,
        maxLength: 500,
        leadingIcon: LucideIcons.textAlignStart,
      ),
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 14),
      children: [
        for (var k = 0; k < children.length; k++) ...[
          if (k > 0) const SizedBox(height: 14),
          children[k],
        ],
      ],
    );
  }
}
