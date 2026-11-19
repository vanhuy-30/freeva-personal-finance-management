import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/currency_catalog.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../viewmodels/first_run_nudges_view_model.dart';

/// "Đặt ngân sách tháng n" over Tổng quan on the first visit without a
/// budget (board BudgetAsk). The amount starts from the declared income;
/// "Để sau" closes it for good.
Future<void> showBudgetAskSheet(
  BuildContext context,
  FirstRunNudgesViewModel nudges, {
  required String currency,
  DateTime? today,
}) => showFreevaSheet<void>(
  context: context,
  scrollable: false,
  builder: (context) => BudgetAskBody(
    nudges: nudges,
    currency: currency,
    today: today ?? DateTime.now(),
  ),
);

class BudgetAskBody extends StatefulWidget {
  const BudgetAskBody({
    required this.nudges,
    required this.currency,
    required this.today,
    super.key,
  });

  final FirstRunNudgesViewModel nudges;
  final String currency;
  final DateTime today;

  @override
  State<BudgetAskBody> createState() => _BudgetAskBodyState();
}

class _BudgetAskBodyState extends State<BudgetAskBody> {
  late final TextEditingController _amount;
  bool _saving = false;

  int get _digits => CurrencyCatalog.current.digits(widget.currency);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final locale = Localizations.localeOf(context).toString();
    final suggestion = widget.nudges.budgetSuggestion;
    _amount = TextEditingController(
      text: suggestion == null
          ? ''
          : formatMoneyText(suggestion, _digits, locale),
    );
  }

  bool _initialised = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _set(BigInt value) async {
    setState(() => _saving = true);
    final ok = await widget.nudges.setBudget(value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      showFreevaToast(context, message: S.of(context).meIncomeFailed);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final value = parseGroupedMoney(_amount.text, _digits, locale);
    final month = locale.startsWith('vi')
        ? '${widget.today.month}'
        : DateFormat.MMMM(locale).format(widget.today);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Center(
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.statusWarningBg,
              borderRadius: BorderRadius.circular(FreevaRadius.md),
            ),
            child: Icon(LucideIcons.chartPie, size: 22, color: c.statusWarning),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(
            s.budgetAskTitle(month),
            textAlign: TextAlign.center,
            style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
          ),
        ),
        const SizedBox(height: 18),
        FreevaTextField(
          label: s.budgetAskLimit,
          controller: _amount,
          tabular: true,
          keyboardType: TextInputType.numberWithOptions(decimal: _digits > 0),
          inputFormatters: [
            MoneyInputFormatter(minorDigits: _digits, locale: locale),
            LengthLimitingTextInputFormatter(20),
          ],
          suffix: CurrencyCatalog.current.symbol(widget.currency),
          onChanged: (_) => setState(() {}),
        ),
        if (widget.nudges.budgetSuggestion != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: FreevaSpace.s1),
            child: Text(
              s.budgetAskHint,
              style: FreevaTypography.bodyS.copyWith(
                height: 18 / 13,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        FreevaButton(
          label: s.budgetAskSet,
          size: FreevaButtonSize.l,
          expand: true,
          loading: _saving,
          onPressed: _saving || value == null || value <= BigInt.zero
              ? null
              : () => _set(value),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, FreevaSize.touch),
              padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
              foregroundColor: c.textLink,
            ),
            child: Text(
              s.authLaterLink,
              style: FreevaTypography.titleM.copyWith(color: c.textLink),
            ),
          ),
        ),
      ],
    );
  }
}
