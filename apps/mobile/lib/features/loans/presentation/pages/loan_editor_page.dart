import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../debts/presentation/widgets/debt_parts.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../settings/presentation/widgets/choice_sheet.dart';
import '../../../transactions/presentation/widgets/composer/date_picker_sheet.dart';
import '../../../transactions/presentation/widgets/composer/wallet_picker_sheet.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../../domain/loan.dart';
import '../viewmodels/loan_view_model.dart';
import '../widgets/loan_kind_chip.dart';
import '../widgets/loan_labels.dart';

/// Thêm / Sửa khoản vay (LoanAdd). An empty "Trả mỗi kỳ" is worked out from
/// the end date (fixed payment, same formula as the API).
class LoanEditorPage extends StatefulWidget {
  const LoanEditorPage({this.loanId, super.key});

  final String? loanId;

  @override
  State<LoanEditorPage> createState() => _LoanEditorPageState();
}

class _LoanEditorPageState extends State<LoanEditorPage> {
  late final LoanViewModel model = getIt<LoanViewModel>();
  final name = TextEditingController();
  final principal = TextEditingController();
  final outstanding = TextEditingController();
  final rate = TextEditingController();
  final installment = TextEditingController();
  LoanKind kind = LoanKind.mortgage;
  LoanFrequency frequency = LoanFrequency.monthly;
  late String startDate = model.today;
  String? endDate;
  String? nextDueDate;
  String? walletId;
  bool _nameTouched = false;
  bool saving = false;
  bool ready = false;
  Loan? existing;

  /// Kept for the screen so a resend never adds the loan twice.
  late final String clientId = model.newClientId();

  bool get editing => widget.loanId != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (!model.loaded) await model.load();
    if (!mounted) return;
    final locale = Localizations.localeOf(context).toString();
    final loan = editing ? model.byId(widget.loanId!) : null;
    existing = loan;
    if (loan != null) {
      final digits = model.digitsOf(loan.currencyCode);
      kind = loan.kind;
      name.text = loan.name;
      _nameTouched = true;
      principal.text = formatMoneyText(loan.principalMinor, digits, locale);
      outstanding.text = formatMoneyText(loan.outstandingMinor, digits, locale);
      rate.text = loanRate(context, loan.interestRateBps);
      if (loan.installmentMinor != null) {
        installment.text = formatMoneyText(
          loan.installmentMinor!,
          digits,
          locale,
        );
      }
      frequency = loan.frequency;
      startDate = loan.startDate;
      endDate = loan.endDate;
      nextDueDate = loan.nextDueDate;
      walletId = loan.accountId;
    } else {
      name.text = loanKindLabel(S.of(context), kind);
      nextDueDate = addPeriod(model.today, frequency);
      walletId = model
          .walletsFor(model.profileCurrency)
          .where((w) => w.draft.type != WalletType.credit)
          .firstOrNull
          ?.id;
    }
    setState(() => ready = true);
  }

  @override
  void dispose() {
    name.dispose();
    principal.dispose();
    outstanding.dispose();
    rate.dispose();
    installment.dispose();
    super.dispose();
  }

  Wallet? get wallet => model.wallet(walletId);

  String get _currency =>
      existing?.currencyCode ?? wallet?.draft.currency ?? model.profileCurrency;

  int get _digits => model.digitsOf(_currency);

  BigInt? _money(TextEditingController c, String locale) =>
      c.text.trim().isEmpty ? null : parseGroupedMoney(c.text, _digits, locale);

  void _pickKind(LoanKind value) => setState(() {
    final s = S.of(context);
    if (!_nameTouched || name.text.trim() == loanKindLabel(s, kind)) {
      name.text = loanKindLabel(s, value);
      _nameTouched = false;
    }
    kind = value;
  });

  Future<void> _pickFrequency(S s) async {
    final picked = await showChoiceSheet<LoanFrequency>(
      context,
      title: s.loanFrequency,
      selected: frequency,
      options: [
        for (final f in LoanFrequency.values)
          Choice(f, loanFrequencyLabel(s, f)),
      ],
    );
    if (picked != null) setState(() => frequency = picked);
  }

  Future<void> _pickDate(String field) async {
    final current = switch (field) {
      'start' => startDate,
      'end' => endDate ?? nextDueDate ?? startDate,
      _ => nextDueDate ?? model.today,
    };
    final picked = await showDatePickerSheet(
      context,
      value: current,
      today: model.today,
    );
    if (picked == null || !mounted) return;
    setState(() {
      switch (field) {
        case 'start':
          startDate = picked;
        case 'end':
          endDate = picked;
        default:
          nextDueDate = picked;
      }
    });
  }

  Future<void> _pickWallet(S s, bool hidden) async {
    final wallets = existing == null
        ? model.wallets
        : model.walletsFor(existing!.currencyCode);
    final picked = await showWalletPicker(
      context,
      title: s.loanPayFrom,
      wallets: wallets,
      selected: walletId,
      digitsOf: model.digitsOf,
      hideBalances: hidden,
    );
    if (picked != null) setState(() => walletId = picked);
  }

  /// Fixed payment from the end date when "Trả mỗi kỳ" is empty.
  BigInt? _autoInstallment(BigInt owed, int bps) {
    final end = endDate;
    final first = nextDueDate;
    if (end == null || first == null) return null;
    final periods = periodsUntil(first, end, frequency);
    if (periods < 1) return null;
    return annuityPayment(owed, bps, frequency, periods);
  }

  Future<void> _save() async {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = _money(principal, locale);
    final owed = _money(outstanding, locale) ?? amount;
    final bps = parseRateBps(rate.text.isEmpty ? '0' : rate.text);
    final typed = _money(installment, locale);
    if (amount == null || owed == null || bps == null) {
      showFreevaToast(context, message: s.meSaveError);
      return;
    }
    if (owed > amount) {
      showFreevaToast(context, message: s.loanOwedTooMuch);
      return;
    }
    final perPeriod = typed ?? _autoInstallment(owed, bps);
    setState(() => saving = true);
    final old = existing;
    final Loan? saved = old == null
        ? await model.create(
            LoanDraft(
              clientId: clientId,
              kind: kind,
              name: name.text,
              currencyCode: _currency,
              principalMinor: amount,
              outstandingMinor: owed,
              interestRateBps: bps,
              installmentMinor: perPeriod,
              frequency: frequency,
              startDate: startDate,
              endDate: endDate,
              nextDueDate: nextDueDate,
              accountId: walletId,
            ),
          )
        : await model.save(
            old,
            kind: kind,
            name: name.text,
            interestRateBps: bps,
            installmentMinor: perPeriod,
            frequency: frequency,
            endDate: endDate,
            nextDueDate: nextDueDate,
            accountId: walletId,
            outstandingMinor: owed,
          );
    if (!mounted) return;
    setState(() => saving = false);
    if (saved != null) {
      if (old != null) {
        context.pop();
      } else {
        context.pushReplacement('/me/debts/loans/${saved.id}');
      }
      return;
    }
    showFreevaToast(
      context,
      message: model.failure?.code == AuthError.conflict
          ? s.meConflict
          : s.meSaveError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    final locale = Localizations.localeOf(context).toString();
    final canSave =
        !saving &&
        name.text.trim().isNotEmpty &&
        (_money(principal, locale) ?? BigInt.zero) > BigInt.zero;
    return BalancesHiddenBuilder(
      builder: (context, hidden) => Scaffold(
        appBar: FreevaTopBar(
          title: editing ? s.loanEdit : s.loansAdd,
          kind: FreevaTopBarKind.modal,
          onLeading: () => context.popOrGo('/me/debts?tab=loans'),
        ),
        body: !ready
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(child: _form(context, s, margin, hidden)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(margin, 0, margin, 28),
                    child: FreevaButton(
                      label: s.loanSave,
                      size: FreevaButtonSize.l,
                      expand: true,
                      loading: saving,
                      onPressed: canSave ? _save : null,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _form(BuildContext context, S s, double margin, bool hidden) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final money = [MoneyInputFormatter(minorDigits: _digits, locale: locale)];
    final w = wallet;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: FreevaTypography.sectionLabel.copyWith(color: c.textSecondary),
        ),
      ),
    );
    final fields = <Widget>[
      Wrap(
        spacing: FreevaSpace.s2,
        runSpacing: FreevaSpace.s2,
        children: [
          for (final k in pickableLoanKinds)
            LoanKindChip(
              kind: k,
              label: loanKindLabel(s, k),
              selected: kind == k,
              onTap: () => _pickKind(k),
            ),
        ],
      ),
      FreevaTextField(
        label: s.loanName,
        controller: name,
        maxLength: 80,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() => _nameTouched = true),
      ),
      label(s.loanAmountGroup),
      FormPair(
        first: FreevaTextField(
          label: s.loanPrincipal,
          controller: principal,
          locked: editing,
          keyboardType: TextInputType.number,
          inputFormatters: money,
          tabular: true,
          onChanged: (_) => setState(() {}),
        ),
        second: FreevaTextField(
          label: s.loansOwed,
          controller: outstanding,
          hint: principal.text,
          keyboardType: TextInputType.number,
          inputFormatters: money,
          tabular: true,
        ),
      ),
      FormPair(
        first: FreevaTextField(
          label: s.loanRate,
          controller: rate,
          hint: '0',
          suffix: s.loanRateUnit,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            LengthLimitingTextInputFormatter(7),
          ],
          tabular: true,
        ),
        second: FreevaTextField(
          label: s.loanInstallment,
          controller: installment,
          keyboardType: TextInputType.number,
          inputFormatters: money,
          tabular: true,
        ),
      ),
      label(s.loanSchedule),
      FormPair(
        first: PickerField(
          chevron: false,
          label: s.loanFrequency,
          value: loanFrequencyLabel(s, frequency),
          leading: FieldIconTile(
            icon: LucideIcons.repeat,
            background: c.bgSubtle,
            foreground: c.textOnWash,
          ),
          onTap: () => _pickFrequency(s),
        ),
        second: PickerField(
          chevron: false,
          label: s.loanNextDue,
          value: nextDueDate == null ? s.debtPickDate : debtDay(nextDueDate!),
          placeholder: nextDueDate == null,
          leading: FieldIconTile(
            icon: LucideIcons.calendarClock,
            background: c.statusWarningBg,
            foreground: c.statusWarning,
          ),
          onTap: () => _pickDate('next'),
        ),
      ),
      FormPair(
        first: PickerField(
          chevron: false,
          label: s.loanStart,
          value: monthYear(startDate),
          leading: FieldIconTile(
            icon: LucideIcons.calendar,
            background: c.bgSubtle,
            foreground: c.textOnWash,
          ),
          // The API keeps the start date once the loan exists.
          onTap: editing ? () {} : () => _pickDate('start'),
        ),
        second: PickerField(
          chevron: false,
          label: s.loanEnd,
          value: endDate == null ? s.debtPickDate : monthYear(endDate!),
          placeholder: endDate == null,
          leading: FieldIconTile(
            icon: LucideIcons.calendar,
            background: c.bgSubtle,
            foreground: c.textOnWash,
          ),
          onTap: () => _pickDate('end'),
        ),
      ),
      PickerField(
        chevron: false,
        label: s.loanPayFrom,
        value: w?.draft.name ?? s.recNeedWallet,
        placeholder: w == null,
        leading: FieldIconTile(
          icon: LucideIcons.landmark,
          background: c.tintBlue,
          foreground: c.tintBlueFg,
        ),
        onTap: () => _pickWallet(s, hidden),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          s.loanInstallmentHint,
          style: FreevaTypography.bodyS.copyWith(
            height: 18 / 13,
            color: c.textSecondary,
          ),
        ),
      ),
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 14),
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          fields[i],
        ],
      ],
    );
  }
}
