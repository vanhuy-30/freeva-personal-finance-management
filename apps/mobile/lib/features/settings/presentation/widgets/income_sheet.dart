import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/sheet_amount_field.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../../core/money/currency_catalog.dart';

/// Edits the stated monthly income (Cá nhân): "Lưu" sets it, "Xoá thu nhập"
/// clears it. Saved through `PUT /profile/monthly-income`.
Future<void> showIncomeSheet(BuildContext context, ProfileViewModel profile) {
  final s = S.of(context);
  return showFreevaSheet<void>(
    context: context,
    title: s.meIncome,
    builder: (context) => _IncomeBody(profile: profile),
  );
}

class _IncomeBody extends StatefulWidget {
  const _IncomeBody({required this.profile});

  final ProfileViewModel profile;

  @override
  State<_IncomeBody> createState() => _IncomeBodyState();
}

class _IncomeBodyState extends State<_IncomeBody> {
  late final TextEditingController _amount;
  bool _saving = false;

  String get _currency =>
      widget.profile.saved?.currency ?? CurrencyCatalog.current.defaultCode;
  int get _digits => CurrencyCatalog.current.digits(_currency);

  @override
  void initState() {
    super.initState();
    final income = widget.profile.saved?.monthlyIncomeMinor;
    final locale = widget.profile.saved?.locale ?? 'vi';
    _amount = TextEditingController(
      text: income == null ? '' : formatMoneyText(income, _digits, locale),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save(BigInt? minor) async {
    setState(() => _saving = true);
    final ok = await widget.profile.saveMonthlyIncome(minor);
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
    final locale = Localizations.localeOf(context).toString();
    final value = parseGroupedMoney(_amount.text, _digits, locale);
    final had = widget.profile.saved?.monthlyIncomeMinor != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetAmountField(
          controller: _amount,
          digits: _digits,
          locale: locale,
          symbol: CurrencyCatalog.current.symbol(_currency),
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: FreevaSpace.s5),
        FreevaButton(
          label: s.meIncomeSave,
          size: FreevaButtonSize.l,
          expand: true,
          loading: _saving,
          onPressed: _saving || value == null || value <= BigInt.zero
              ? null
              : () => _save(value),
        ),
        if (had) ...[
          const SizedBox(height: FreevaSpace.s2),
          Center(
            child: TextButton(
              onPressed: _saving ? null : () => _save(null),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, FreevaSize.touch),
                foregroundColor: context.colors.actionDanger,
              ),
              child: Text(
                s.meIncomeClear,
                style: FreevaTypography.titleM.copyWith(
                  color: context.colors.actionDanger,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
