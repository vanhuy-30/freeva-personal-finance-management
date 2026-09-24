import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/profile_view_model.dart';
import 'profile_select.dart';

class ProfileForm extends StatelessWidget {
  const ProfileForm({required this.model, super.key});
  final ProfileViewModel model;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final value = model.draft!;
    final options = model.options!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSelect(
          label: s.profileLanguage,
          value: value.locale,
          enabled: !model.loading,
          choices: {'vi': s.profileVietnamese, 'en': s.profileEnglish},
          onChanged: (v) => model.edit(value.copyWith(locale: v)),
        ),
        ProfileSelect(
          label: s.profileCurrency,
          value: value.currency,
          enabled: !model.loading,
          choices: {for (final code in options.currencies) code: code},
          onChanged: (v) => model.edit(value.copyWith(currency: v)),
        ),
        Text(
          s.profileCurrencyHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        ProfileSelect(
          label: s.profileTimezone,
          value: value.timezone,
          enabled: !model.loading,
          choices: {for (final zone in options.timezones) zone: zone},
          onChanged: (v) => model.edit(value.copyWith(timezone: v)),
        ),
        ProfileSelect(
          label: s.profileFiscalDay,
          value: value.fiscalDay.toString(),
          enabled: !model.loading,
          choices: {
            for (var day = 1; day <= 28; day++)
              day.toString(): NumberFormat.decimalPattern(s.localeName)
                  .format(day),
          },
          onChanged: (v) => model.edit(value.copyWith(fiscalDay: int.parse(v))),
        ),
        Text(s.profileFiscalHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: model.loading || !model.dirty ? null : model.save,
          child: Text(s.profileSave),
        ),
        TextButton(
          onPressed: model.loading || !model.dirty ? null : model.cancel,
          child: Text(s.profileCancel),
        ),
      ],
    );
  }
}
