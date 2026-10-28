import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import 'choice_sheet.dart';
import 'profile_actions.dart';

/// THIẾT LẬP TÀI CHÍNH: how you manage money, each row with its own tint.
/// Goals still say "Sắp có"; budget opens the monthly budget screen.
class MoneySetupGroup extends StatelessWidget {
  const MoneySetupGroup({
    required this.profile,
    this.walletCount,
    this.tagCount,
    this.budget,
    super.key,
  });

  final ProfileViewModel profile;

  /// Active wallets; null while unknown.
  final int? walletCount;

  /// Tags; null while unknown.
  final int? tagCount;

  /// Monthly budget draft in VND; null when none was typed.
  final int? budget;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final saved = profile.saved;
    final goals = saved?.goals.length ?? 0;
    void soon() => showFreevaToast(context, message: s.meSoon);
    const rowHeight = 54.0;
    return SettingsGroup(
      title: s.meGroupFinance,
      children: [
        SettingsRow(
          tint: (c.tintViolet, c.tintVioletFg),
          minHeight: rowHeight,
          icon: LucideIcons.walletMinimal,
          title: s.meWallets,
          value: walletCount == null ? null : '$walletCount',
          onTap: () => context.push('/wallets'),
        ),
        SettingsRow(
          tint: (c.tintCyan, c.tintCyanFg),
          minHeight: rowHeight,
          icon: LucideIcons.layoutGrid,
          title: s.meCategories,
          onTap: () => context.push('/categories'),
        ),
        SettingsRow(
          tint: (c.tintBlue, c.tintBlueFg),
          minHeight: rowHeight,
          icon: LucideIcons.tag,
          title: s.meTags,
          value: tagCount == null ? null : '$tagCount',
          onTap: () => context.push('/me/tags'),
        ),
        SettingsRow(
          tint: (c.statusWarningBg, c.statusWarning),
          minHeight: rowHeight,
          icon: LucideIcons.refreshCw,
          title: s.meRecurring,
          onTap: () => context.push('/me/recurring'),
        ),
        SettingsRow(
          tint: (c.tintCyan, c.tintCyanFg),
          minHeight: rowHeight,
          icon: LucideIcons.zap,
          title: s.meBills,
          onTap: () => context.push('/me/bills'),
        ),
        SettingsRow(
          tint: (c.tintGreen, c.tintGreenFg),
          minHeight: rowHeight,
          icon: LucideIcons.banknote,
          title: s.meCurrency,
          value: saved?.currency,
          onTap: saved == null || profile.options == null
              ? null
              : () async {
                  final picked = await showChoiceSheet<String>(
                    context,
                    title: s.meCurrency,
                    selected: saved.currency,
                    options: [
                      for (final code in profile.options!.currencies)
                        Choice(code, code),
                    ],
                  );
                  if (picked == null || picked == saved.currency) return;
                  if (!context.mounted) return;
                  await applyProfile(
                    context,
                    profile,
                    (p) => p.copyWith(currency: picked),
                  );
                },
        ),
        SettingsRow(
          tint: (c.statusWarningBg, c.statusWarning),
          minHeight: rowHeight,
          icon: LucideIcons.chartPie,
          title: s.meBudget,
          value: budget == null || budget! <= 0
              ? null
              : formatMoneyText(BigInt.from(budget!), 0, s.localeName),
          onTap: () => context.push('/budgets'),
        ),
        SettingsRow(
          tint: (c.tintBlue, c.tintBlueFg),
          minHeight: rowHeight,
          icon: LucideIcons.calendar,
          title: s.meFiscal,
          value: saved == null ? null : s.meFiscalDay(saved.fiscalDay),
          onTap: saved == null
              ? null
              : () async {
                  final picked = await showChoiceSheet<int>(
                    context,
                    title: s.meFiscal,
                    selected: saved.fiscalDay,
                    options: [
                      for (var day = 1; day <= 28; day++)
                        Choice(day, s.meFiscalDay(day)),
                    ],
                  );
                  if (picked == null || picked == saved.fiscalDay) return;
                  if (!context.mounted) return;
                  await applyProfile(
                    context,
                    profile,
                    (p) => p.copyWith(fiscalDay: picked),
                  );
                },
        ),
        SettingsRow(
          tint: (c.tintViolet, c.tintVioletFg),
          minHeight: rowHeight,
          icon: LucideIcons.target,
          title: s.meGoals,
          value: goals == 0 ? null : s.meGoalsCount(goals),
          onTap: soon,
        ),
      ],
    );
  }
}
