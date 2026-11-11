import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_dialog_input.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../recurring/domain/recurring_calendar.dart';
import '../../../recurring/presentation/widgets/recurring_labels.dart';
import '../../../transactions/presentation/widgets/composer/date_picker_sheet.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../../domain/card_installment.dart';
import '../viewmodels/installment_view_model.dart';
import '../widgets/installment_parts.dart';
import 'installment_detail_page.dart';
import '../../../server_config/domain/app_limits.dart';
import '../../../../core/di/injection.dart';

/// The purchase being split, as the expense detail shows it.
class InstallmentPurchase {
  const InstallmentPurchase({
    required this.transactionId,
    required this.accountId,
    required this.title,
    required this.icon,
    required this.walletName,
    required this.occurredOn,
    required this.amountMinor,
    required this.currency,
  });

  final String transactionId;
  final String accountId;
  final String title;
  final IconData icon;
  final String walletName;
  final String occurredOn;
  final BigInt amountMinor;
  final String currency;
}

/// "Trả góp" (M, màn 5, board `InstAdd`): turn a card purchase into a
/// schedule. Every number on the screen comes from the API preview; the
/// plan is only made on "Tạo lịch trả góp". Online only.
class InstallmentAddPage extends StatefulWidget {
  const InstallmentAddPage({
    required this.model,
    required this.purchase,
    super.key,
  });

  final InstallmentViewModel model;
  final InstallmentPurchase purchase;

  @override
  State<InstallmentAddPage> createState() => _InstallmentAddPageState();
}

class _InstallmentAddPageState extends State<InstallmentAddPage> {
  InstallmentViewModel get model => widget.model;
  InstallmentPurchase get purchase => widget.purchase;

  late final AppLimits limits = getIt<AppLimitsSource>().requireLimits;
  late int count = limits.installmentDefaultTerm;
  List<int> get counts => limits.installmentTermOptions;
  BigInt? each;
  late String firstDue = _suggestedFirst();
  InstallmentPreview? preview;
  AuthFailure? previewFailure;
  bool loading = false;
  bool saving = false;
  int _epoch = 0;

  /// Kept while the page is open so a resend never makes two plans.
  late final String clientId = model.newClientId();

  int get digits => model.digitsOf(purchase.currency);

  String _suggestedFirst() {
    final card = model.wallet(purchase.accountId)?.draft;
    return suggestedFirstDue(
      purchase.occurredOn,
      closeDay: card?.closeDay,
      dueDay: card?.dueDay,
    );
  }

  bool get _tooEarly => firstDue.compareTo(purchase.occurredOn) < 0;

  InstallmentDraft get _draft => InstallmentDraft(
    transactionId: purchase.transactionId,
    installmentCount: count,
    installmentMinor: each,
    firstDueOn: firstDue,
  );

  @override
  void initState() {
    super.initState();
    _preview();
  }

  Future<void> _preview() async {
    final epoch = ++_epoch;
    if (_tooEarly) {
      setState(() {
        preview = null;
        previewFailure = null;
        loading = false;
      });
      return;
    }
    setState(() => loading = true);
    final result = await model.preview(_draft);
    if (!mounted || epoch != _epoch) return;
    setState(() {
      loading = false;
      result.fold(
        (error) {
          preview = null;
          previewFailure = error;
        },
        (value) {
          preview = value;
          previewFailure = null;
        },
      );
    });
  }

  void _setCount(int value) {
    if (value == count) return;
    count = value;
    each = null;
    _preview();
  }

  Future<void> _otherCount(S s) async {
    final text = await showFreevaInputDialog(
      context: context,
      title: s.installmentOtherTitle,
      label: s.installmentOtherLabel(
        limits.installmentMinTerm,
        limits.installmentMaxTerm,
      ),
      initial: counts.contains(count) ? '' : '$count',
      keyboardType: TextInputType.number,
      formatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
    );
    final value = int.tryParse(text ?? '');
    if (value == null) return;
    if (value < limits.installmentMinTerm ||
        value > limits.installmentMaxTerm) {
      if (mounted) {
        showFreevaToast(
          context,
          message: s.installmentOtherLabel(
            limits.installmentMinTerm,
            limits.installmentMaxTerm,
          ),
        );
      }
      return;
    }
    _setCount(value);
  }

  Future<void> _editEach(S s, String locale) async {
    final current = each ?? preview?.installmentMinor;
    final text = await showFreevaInputDialog(
      context: context,
      title: s.installmentEditEach,
      label: s.installmentEach,
      initial: current == null ? '' : formatMoneyText(current, digits, locale),
      keyboardType: TextInputType.numberWithOptions(decimal: digits > 0),
      formatters: [MoneyInputFormatter(minorDigits: digits, locale: locale)],
    );
    if (text == null) return;
    // Cleared: back to the even split the API suggests.
    final value = text.trim().isEmpty
        ? null
        : parseGroupedMoney(text, digits, locale);
    if (text.trim().isNotEmpty && (value == null || value <= BigInt.zero)) {
      return;
    }
    each = value;
    _preview();
  }

  Future<void> _pickFirst() async {
    final picked = await showDatePickerSheet(
      context,
      value: firstDue,
      today: isoDay(model.today),
    );
    if (picked == null || picked == firstDue) return;
    firstDue = picked;
    _preview();
  }

  Future<void> _create(S s) async {
    setState(() => saving = true);
    final plan = await model.create(_draft, clientId: clientId);
    if (!mounted) return;
    setState(() => saving = false);
    if (plan == null) {
      showFreevaToast(
        context,
        message: model.failure?.code == AuthError.conflict
            ? s.installmentConflict
            : s.installmentPreviewError,
      );
      return;
    }
    showFreevaToast(context, message: s.installmentCreated, success: true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => InstallmentDetailPage(planId: plan.id, model: model),
      ),
    );
  }

  /// Red line under the fields when the input cannot make a schedule.
  String? _error(S s) {
    if (_tooEarly) return s.installmentFirstTooEarly;
    final failure = previewFailure;
    if (failure == null) return null;
    return switch (failure.code) {
      AuthError.conflict => s.installmentConflict,
      AuthError.invalidToken ||
      AuthError.invalidInput => s.installmentEachInvalid(count),
      _ => s.installmentPreviewError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    final shown = preview;
    final error = _error(s);
    final month = parseCalendarParts(purchase.occurredOn)?.month ?? 0;
    final custom = !counts.contains(count);
    final children = <Widget>[
      _PurchaseCard(purchase: purchase, money: money),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              s.installmentCount,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in counts)
                FreevaChip(
                  label: '$n',
                  selected: n == count,
                  onTap: () => _setCount(n),
                ),
              FreevaChip(
                label: custom ? '$count' : s.installmentOther,
                selected: custom,
                onTap: () => _otherCount(s),
              ),
            ],
          ),
        ],
      ),
      // Stacks when narrow so the amount is never cut.
      FormPair(
        first: PickerField(
          label: s.installmentEach,
          value: (each ?? shown?.installmentMinor) == null
              ? '—'
              : money((each ?? shown!.installmentMinor)),
          placeholder: each == null && shown == null,
          trailing: Icon(LucideIcons.penLine, size: 16, color: c.textSecondary),
          onTap: () => _editEach(s, locale),
        ),
        second: PickerField(
          chevron: false,
          label: s.installmentFirst,
          value: dayMonth(firstDue),
          leading: FieldIconTile(
            icon: LucideIcons.calendarClock,
            background: c.statusWarningBg,
            foreground: c.statusWarning,
          ),
          onTap: _pickFirst,
        ),
      ),
      if (shown != null)
        InstallmentGroup(
          children: [
            for (final p in shown.periods.take(3))
              InstallmentPeriodTile(
                period: p,
                digits: digits,
                next: p.index == 1,
              ),
            if (shown.periods.length > 3)
              SizedBox(
                height: 40,
                child: Center(
                  child: Text(
                    s.installmentMore(
                      shown.periods.length - 3,
                      installmentDay(shown.lastDueOn),
                    ),
                    style: FreevaTypography.bodyS.copyWith(
                      color: c.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
          ],
        )
      else if (loading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(FreevaSpace.s4),
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          error ?? s.installmentHint(month),
          style: FreevaTypography.bodyS.copyWith(
            height: 18 / 13,
            color: error == null ? c.textSecondary : c.statusDanger,
          ),
        ),
      ),
    ];
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.installmentTitle,
        kind: FreevaTopBarKind.modal,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.screenMargin,
                  FreevaSpace.s2,
                  context.screenMargin,
                  FreevaSpace.s4,
                ),
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    children[i],
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.screenMargin,
                0,
                context.screenMargin,
                28,
              ),
              child: FreevaButton(
                label: s.installmentCreate,
                size: FreevaButtonSize.l,
                expand: true,
                loading: saving,
                onPressed: shown != null && error == null && !loading && !saving
                    ? () => _create(s)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board: card padding 14/16, 40 round tile, name 15/600, "Thẻ chính ·
/// 12/10", amount 15/600.
class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.purchase, required this.money});

  final InstallmentPurchase purchase;
  final String Function(BigInt) money;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FreevaCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: MergeSemantics(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.bgSubtle,
              ),
              child: Icon(purchase.icon, size: 18, color: c.textOnWash),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${purchase.walletName} · ${dayMonth(purchase.occurredOn)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              money(purchase.amountMinor),
              maxLines: 1,
              style: FreevaTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
