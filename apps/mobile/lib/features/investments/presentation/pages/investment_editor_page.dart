import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../auth/presentation/widgets/auth_message.dart';
import '../../../net_worth/presentation/widgets/net_worth_labels.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../transactions/presentation/widgets/composer/date_picker_sheet.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../../domain/investment.dart';
import '../viewmodels/investment_view_model.dart';
import '../widgets/investment_labels.dart';
import '../widgets/investment_wallet_list.dart';
import '../../../server_config/domain/app_limits.dart';

/// Khoản đầu tư mới (boards P.5 and P.6): pick a category, describe the
/// first buy, and say where the money came from. A name that already exists
/// adds the buy to that asset (the server merges).
class InvestmentEditorPage extends StatefulWidget {
  const InvestmentEditorPage({this.kind, this.name, this.unit, super.key});

  /// Category to start on (`?kind=` from the empty state chips).
  final InvestmentKind? kind;

  /// Name and unit of an asset to add a buy to ("Mua thêm"): the server
  /// merges a buy under the same name into that asset.
  final String? name;
  final String? unit;

  @override
  State<InvestmentEditorPage> createState() => _InvestmentEditorPageState();
}

class _InvestmentEditorPageState extends State<InvestmentEditorPage> {
  late final InvestmentViewModel model = getIt<InvestmentViewModel>();
  final name = TextEditingController();
  final quantity = TextEditingController();
  final price = TextEditingController();
  final rate = TextEditingController();
  final note = TextEditingController();
  late InvestmentKind kind = widget.kind ?? InvestmentKind.gold;
  late String unit = widget.unit ?? kind.defaultUnit;
  late String tradedOn = model.today;
  String? maturityOn;
  String? walletId;
  bool saving = false;
  bool ready = false;

  /// Kept for the whole screen so a resend never records the buy twice.
  late final String clientId = model.newClientId();
  late final String tradeClientId = model.newClientId();

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await model.loadWallets();
    if (!mounted) return;
    name.text = widget.name ?? '';
    setState(() {
      walletId = model.wallets.firstOrNull?.id;
      ready = true;
    });
  }

  @override
  void dispose() {
    for (final c in [name, quantity, price, rate, note]) {
      c.dispose();
    }
    super.dispose();
  }

  Wallet? get wallet =>
      model.wallets.where((w) => w.id == walletId).firstOrNull;

  String get _currency => wallet?.draft.currency ?? model.profileCurrency;

  int get _digits => model.digitsOf(_currency);

  void _pickKind(InvestmentKind value) {
    if (value == kind) return;
    setState(() {
      kind = value;
      unit = value.defaultUnit;
      quantity.clear();
      price.clear();
    });
  }

  /// Quantity scaled by 10^8; 1 for a one-lot kind.
  BigInt? _quantity(String locale) => kind.singleLot
      ? quantityOne
      : parseGroupedMoney(quantity.text, quantityDigits, locale);

  BigInt? _price(String locale) =>
      parseGroupedMoney(price.text, _digits, locale);

  /// What the buy costs; null until both numbers are typed.
  BigInt? _total(String locale) {
    final p = _price(locale);
    if (kind.singleLot) return p;
    final q = _quantity(locale);
    if (p == null || q == null) return null;
    return quantityTotalMinor(q, p);
  }

  int? _rateBps(String locale) =>
      parseGroupedMoney(rate.text, 2, locale)?.toInt();

  bool _ready(String locale) {
    if (saving || name.text.trim().isEmpty) return false;
    final q = _quantity(locale);
    final p = _price(locale);
    if (q == null || q <= BigInt.zero || p == null || p <= BigInt.zero) {
      return false;
    }
    if (kind == InvestmentKind.savingsDeposit) {
      final bps = _rateBps(locale);
      if (bps == null || bps < 0) return false;
      if (maturityOn == null || maturityOn!.compareTo(tradedOn) <= 0) {
        return false;
      }
    }
    return true;
  }

  Future<void> _pickDate({required bool maturity}) async {
    final picked = await showDatePickerSheet(
      context,
      value: maturity ? (maturityOn ?? tradedOn) : tradedOn,
      today: model.today,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (maturity) {
        maturityOn = picked;
      } else {
        tradedOn = picked;
        if (maturityOn != null && maturityOn!.compareTo(picked) <= 0) {
          maturityOn = null;
        }
      }
    });
  }

  Future<void> _save() async {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final deposit = kind == InvestmentKind.savingsDeposit;
    final lot = kind.singleLot;
    final text = note.text.trim();
    setState(() => saving = true);
    final saved = await model.create(
      InvestmentDraft(
        clientId: clientId,
        tradeClientId: tradeClientId,
        kind: kind,
        name: name.text,
        currencyCode: _currency,
        unit: unit,
        quantity: _quantity(locale)!,
        tradedOn: tradedOn,
        priceMinor: lot ? null : _price(locale),
        amountMinor: lot ? _price(locale) : null,
        accountId: walletId,
        note: text.isEmpty ? null : text,
        interestRateBps: deposit ? _rateBps(locale) : null,
        startDate: deposit ? tradedOn : null,
        maturityDate: deposit ? maturityOn : null,
      ),
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (saved != null) {
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
          title: s.investmentNewTitle,
          kind: FreevaTopBarKind.modal,
          onLeading: () => context.popOrGo('/me/investments'),
        ),
        body: !ready
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(child: _form(context, s, margin, hidden, locale)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(margin, 0, margin, 28),
                    child: FreevaButton(
                      label: s.investmentSave,
                      size: FreevaButtonSize.l,
                      expand: true,
                      loading: saving,
                      onPressed: _ready(locale) ? _save : null,
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
    final deposit = kind == InvestmentKind.savingsDeposit;
    final lot = kind.singleLot;
    final total = _total(locale);
    final symbol = MoneyDisplay.symbolFor(_currency);
    Widget field(
      String label,
      TextEditingController controller,
      int digits, {
      String? suffix,
      IconData? icon,
    }) => FreevaTextField(
      label: label,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        MoneyInputFormatter(minorDigits: digits, locale: locale),
      ],
      tabular: true,
      suffix: suffix,
      leadingIcon: icon,
      onChanged: (_) => setState(() {}),
    );
    PickerField date(String label, String? value, VoidCallback onTap) =>
        PickerField(
          chevron: false,
          label: label,
          value: value == null
              ? s.investmentPickDate
              : netWorthDate(value, locale, year: true),
          placeholder: value == null,
          leading: FieldIconTile(
            icon: LucideIcons.calendar,
            background: c.bgSubtle,
            foreground: c.textOnWash,
          ),
          onTap: onTap,
        );
    final priceField = field(
      deposit
          ? s.investmentDepositAmount
          : lot
          ? s.investmentPurchasePrice
          : s.investmentUnitPrice(unit),
      price,
      _digits,
      suffix: symbol,
    );
    final children = <Widget>[
      SectionHeader(s.investmentsKinds),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final k in InvestmentKind.values)
            FreevaChip(
              label: investmentKindName(s, k),
              selected: k == kind,
              icon: investmentKindIcon(k),
              onTap: () => _pickKind(k),
            ),
        ],
      ),
      const SizedBox(height: 14),
      FreevaTextField(
        label: s.investmentName,
        controller: name,
        maxLength:
            getIt<AppLimitsSource>().requireLimits.investmentNameMaxLength,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
      ),
      if (kind == InvestmentKind.gold) ...[
        const SizedBox(height: 14),
        FreevaSegmented<String>(
          expand: true,
          selected: unit,
          segments: [
            FreevaSegment('chi', s.investmentGoldByChi),
            FreevaSegment('luong', s.investmentGoldByLuong),
          ],
          onChanged: (value) => setState(() => unit = value),
        ),
      ],
      const SizedBox(height: 14),
      if (deposit) ...[
        FormPair(
          first: priceField,
          second: field(s.investmentRate, rate, 2, suffix: '%'),
        ),
        const SizedBox(height: 14),
        FormPair(
          first: date(
            s.investmentDepositDate,
            tradedOn,
            () => _pickDate(maturity: false),
          ),
          second: date(
            s.investmentMaturity,
            maturityOn,
            () => _pickDate(maturity: true),
          ),
        ),
      ] else if (lot) ...[
        priceField,
        const SizedBox(height: 14),
        date(s.investmentBuyDate, tradedOn, () => _pickDate(maturity: false)),
      ] else ...[
        FormPair(
          first: field(
            s.investmentQuantity,
            quantity,
            quantityDigits,
            suffix: s.investmentUnit(unit),
          ),
          second: priceField,
        ),
        const SizedBox(height: 14),
        date(s.investmentBuyDate, tradedOn, () => _pickDate(maturity: false)),
        const SizedBox(height: 14),
        _TotalRow(
          label: s.investmentTotalMoney,
          minor: total ?? BigInt.zero,
          currency: _currency,
          digits: _digits,
          hidden: false,
        ),
      ],
      SectionHeader(s.investmentFromWallet),
      InvestmentWalletList(
        wallets: model.wallets,
        selected: walletId,
        digitsOf: model.digitsOf,
        hidden: hidden,
        onChanged: (id) => setState(() => walletId = id),
      ),
      const SizedBox(height: 14),
      FreevaTextField(
        label: s.investmentNote,
        controller: note,
        maxLength: getIt<AppLimitsSource>().requireLimits.noteMaxLength,
        leadingIcon: LucideIcons.textAlignStart,
      ),
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 14),
      children: children,
    );
  }
}

/// "Tổng tiền" worked out from quantity × price, read-only.
class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.minor,
    required this.currency,
    required this.digits,
    required this.hidden,
  });

  final String label;
  final BigInt minor;
  final String currency;
  final int digits;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.tintBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: FreevaTypography.bodyM.copyWith(
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
            ),
            MoneyDisplay(
              minor: minor,
              currency: currency,
              minorDigits: digits,
              style: FreevaTypography.titleM,
              hidden: hidden,
            ),
          ],
        ),
      ),
    );
  }
}
