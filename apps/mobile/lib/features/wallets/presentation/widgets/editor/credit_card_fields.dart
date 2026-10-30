import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/money/money_input_formatter.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_text_field.dart';
import '../../viewmodels/wallet_form.dart';
import 'day_picker_dialog.dart';
import 'form_pair.dart';
import '../../../../../core/widgets/freeva_picker_field.dart';

/// Card rows of the form: debt + limit, statement day + due day (popup),
/// and "Hạn mức và ngày có thể để trống."
class CreditCardFields extends StatelessWidget {
  const CreditCardFields({
    required this.form,
    required this.debt,
    required this.limit,
    required this.minimum,
    super.key,
  });

  final WalletForm form;
  final TextEditingController debt;
  final TextEditingController limit;
  final TextEditingController minimum;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final close = FieldIconTile(
      icon: LucideIcons.calendarCheck,
      background: c.bgSubtle,
      foreground: c.textOnWash,
    );
    final due = FieldIconTile(
      icon: LucideIcons.calendarClock,
      background: c.statusWarningBg,
      foreground: c.statusWarning,
    );
    MoneyInputFormatter money() => MoneyInputFormatter(
      minorDigits: form.minorDigits,
      locale: locale,
      allowNegative: true,
    );
    Future<void> pick({required bool closing}) async {
      final choice = await showDayOfMonthPicker(
        context,
        title: closing ? s.dayCloseTitle : s.dayDueTitle,
        icon: closing ? close : due,
        selected: closing ? form.closeDay : form.dueDay,
        marked: closing ? form.dueDay : form.closeDay,
        markLabel: closing ? s.dayDueMark : s.dayCloseMark,
      );
      if (choice == null) return;
      closing ? form.setCloseDay(choice.day) : form.setDueDay(choice.day);
    }

    String day(int? value) =>
        value == null ? s.creditPickDay : s.creditDayValue(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormPair(
          first: FreevaTextField(
            label: form.isNew ? s.creditCurrentDebt : s.creditInitialDebt,
            controller: debt,
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputFormatters: [money()],
            tabular: true,
            error: form.errors.contains(WalletFormError.amount)
                ? s.walletAmountInvalid
                : null,
          ),
          second: FreevaTextField(
            label: s.creditLimitField,
            controller: limit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              MoneyInputFormatter(
                minorDigits: form.minorDigits,
                locale: locale,
              ),
            ],
            tabular: true,
            error: form.errors.contains(WalletFormError.limit)
                ? s.walletAmountInvalid
                : null,
          ),
        ),
        const SizedBox(height: FreevaSpace.s4),
        FreevaTextField(
          label: s.creditMinimumField,
          controller: minimum,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            MoneyInputFormatter(
              minorDigits: form.minorDigits,
              locale: locale,
            ),
          ],
          tabular: true,
          error: form.errors.contains(WalletFormError.minimum)
              ? s.walletAmountInvalid
              : null,
        ),
        const SizedBox(height: FreevaSpace.s4),
        FormPair(
          first: PickerField(
            label: s.creditCloseField,
            value: day(form.closeDay),
            placeholder: form.closeDay == null,
            leading: close,
            onTap: () => pick(closing: true),
          ),
          second: PickerField(
            label: s.creditDueField,
            value: day(form.dueDay),
            placeholder: form.dueDay == null,
            leading: due,
            onTap: () => pick(closing: false),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            s.creditOptionalHint,
            style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}
