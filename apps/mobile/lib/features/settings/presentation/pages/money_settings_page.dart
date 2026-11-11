import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../widgets/choice_sheet.dart';
import '../widgets/income_sheet.dart';
import '../widgets/profile_actions.dart';
import '../../../server_config/domain/app_limits.dart';

/// Thu nhập và kỳ tính (board `MeMoney`): monthly income, default currency
/// and the day each month starts. Every pick saves at once.
class MoneySettingsPage extends StatefulWidget {
  const MoneySettingsPage({super.key});

  @override
  State<MoneySettingsPage> createState() => _MoneySettingsPageState();
}

class _MoneySettingsPageState extends State<MoneySettingsPage> {
  late final ProfileViewModel profile = getIt<ProfileViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (profile.saved == null) profile.load();
    });
  }

  Future<void> _pickCurrency() async {
    final s = S.of(context);
    final saved = profile.saved;
    final options = profile.options;
    if (saved == null || options == null) return;
    final picked = await showChoiceSheet<String>(
      context,
      title: s.meCurrency,
      selected: saved.currency,
      options: [for (final code in options.currencies) Choice(code, code)],
    );
    if (picked == null || picked == saved.currency || !mounted) return;
    await applyProfile(context, profile, (p) => p.copyWith(currency: picked));
  }

  Future<void> _pickFiscalDay() async {
    final s = S.of(context);
    final saved = profile.saved;
    if (saved == null) return;
    final picked = await showChoiceSheet<int>(
      context,
      title: s.meFiscal,
      selected: saved.fiscalDay,
      options: [
        for (
          var day = 1;
          day <= getIt<AppLimitsSource>().requireLimits.periodStartDayMax;
          day++
        )
          Choice(day, s.meFiscalDay(day)),
      ],
    );
    if (picked == null || picked == saved.fiscalDay || !mounted) return;
    await applyProfile(context, profile, (p) => p.copyWith(fiscalDay: picked));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: profile,
    builder: (context, _) {
      final s = S.of(context);
      final c = context.colors;
      final saved = profile.saved;
      const rowHeight = 54.0;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meMoneyTitle,
          onLeading: () => context.popOrGo('/me'),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            context.screenMargin,
            FreevaSpace.s2,
            context.screenMargin,
            FreevaSpace.s5,
          ),
          children: [
            SettingsGroup(
              children: [
                SettingsRow(
                  tint: (c.tintGreen, c.tintGreenFg),
                  minHeight: rowHeight,
                  icon: LucideIcons.arrowDownToLine,
                  title: s.meIncome,
                  value: saved?.monthlyIncomeMinor == null
                      ? s.meIncomeNone
                      : formatMoneyText(
                          saved!.monthlyIncomeMinor!,
                          saved.currency == 'VND' ? 0 : 2,
                          s.localeName,
                        ),
                  onTap: saved == null
                      ? null
                      : () => showIncomeSheet(context, profile),
                ),
                SettingsRow(
                  tint: (c.tintGreen, c.tintGreenFg),
                  minHeight: rowHeight,
                  icon: LucideIcons.banknote,
                  title: s.meCurrency,
                  value: saved?.currency,
                  onTap: saved == null || profile.options == null
                      ? null
                      : _pickCurrency,
                ),
                SettingsRow(
                  tint: (c.tintBlue, c.tintBlueFg),
                  minHeight: rowHeight,
                  icon: LucideIcons.calendar,
                  title: s.meFiscal,
                  value: saved == null ? null : s.meFiscalDay(saved.fiscalDay),
                  onTap: saved == null ? null : _pickFiscalDay,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, FreevaSpace.s2, 4, 0),
              child: Text(
                s.meMoneyHint,
                style: FreevaTypography.bodyS.copyWith(
                  height: 18 / 13,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
