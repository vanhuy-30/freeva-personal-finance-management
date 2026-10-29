import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/money/money_input_formatter.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_text_field.dart';
import '../../../../../core/widgets/money_display.dart';
import '../../viewmodels/wallet_form.dart';
import '../wallet_labels.dart';
import 'credit_card_fields.dart';
import 'currency_sheet.dart';
import 'locked_field.dart';
import '../../../../../core/widgets/freeva_picker_field.dart';
import 'wallet_type_grid.dart';

/// Fields of the add / edit form. A wallet with transactions shows type and
/// currency as one locked box instead of the type cards and currency field.
class WalletFormBody extends StatelessWidget {
  const WalletFormBody({
    required this.form,
    required this.name,
    required this.amount,
    required this.limit,
    required this.minimum,
    this.onHide,
    this.showTypes = true,
    this.gap = FreevaSpace.s4,
    super.key,
  });

  final WalletForm form;
  final TextEditingController name;
  final TextEditingController amount;
  final TextEditingController limit;
  final TextEditingController minimum;

  /// "Ẩn ví" under the fields; only when editing.
  final VoidCallback? onHide;

  /// False when the type is already fixed by where the form was opened
  /// (first-run setup).
  final bool showTypes;

  /// Space between the field groups (16; the "Thêm ví" board uses 18).
  final double gap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final spacer = SizedBox(height: gap);
    final type = walletTypeLabel(s, form.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!form.locked && showTypes) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              s.walletType,
              style: FreevaTypography.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ),
          WalletTypeGrid(selected: form.type, onChanged: form.setType),
          spacer,
        ],
        FreevaTextField(
          label: form.credit ? s.cardName : s.walletName,
          controller: name,
          inputFormatters: [_maxLength],
          textInputAction: TextInputAction.next,
          error: form.errors.contains(WalletFormError.name)
              ? s.walletNameMissing
              : null,
        ),
        spacer,
        if (form.locked)
          LockedField(
            label: s.walletLockedLabel,
            value: '$type · ${form.currency}',
            semanticsLabel: s.walletLockedSemantics(type, form.currency),
          )
        else
          PickerField(
            label: s.walletCurrencyField,
            value: currencyLabel(s, form.currency),
            onTap: () async {
              final code = await showCurrencyPicker(
                context,
                currencies: form.currencies,
                selected: form.currency,
              );
              if (code != null) form.setCurrency(code);
            },
          ),
        spacer,
        if (form.credit)
          CreditCardFields(
            form: form,
            debt: amount,
            limit: limit,
            minimum: minimum,
          )
        else ...[
          FreevaTextField(
            label: form.isNew ? s.walletCurrentBalance : s.walletInitialBalance,
            controller: amount,
            hint: '0',
            suffix: MoneyDisplay.symbolFor(form.currency),
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputFormatters: [
              MoneyInputFormatter(
                minorDigits: form.minorDigits,
                locale: locale,
                allowNegative: true,
              ),
            ],
            tabular: true,
            error: form.errors.contains(WalletFormError.amount)
                ? s.walletAmountInvalid
                : null,
          ),
          if (form.isNew)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(
                s.walletBalanceHint,
                style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
              ),
            ),
        ],
        if (onHide != null) ...[
          // Board: page gap 16 + 8 above the text button.
          const SizedBox(height: FreevaSpace.s6),
          Center(
            child: TextButton.icon(
              onPressed: onHide,
              icon: const Icon(LucideIcons.archive, size: FreevaSize.iconSm),
              label: Text(s.walletHide),
              style: TextButton.styleFrom(
                foregroundColor: c.textOnWash,
                minimumSize: const Size(FreevaSize.touch, FreevaSize.touch),
                padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static final _maxLength = LengthLimitingTextInputFormatter(100);
}
