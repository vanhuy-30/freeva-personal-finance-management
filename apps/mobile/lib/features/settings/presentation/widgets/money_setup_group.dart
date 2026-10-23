import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import 'choice_sheet.dart';
import 'profile_actions.dart';

/// THIẾT LẬP TÀI CHÍNH: how you manage money. Budget, goals and tags open
/// once their screens exist; until then they say "Sắp có".
class MoneySetupGroup extends StatelessWidget {
  const MoneySetupGroup({required this.profile, super.key});

  final ProfileViewModel profile;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final saved = profile.saved;
    void soon() => showFreevaToast(context, message: s.meSoon);
    return SettingsGroup(
      title: s.meGroupFinance,
      children: [
        SettingsRow(
          accent: true,
          icon: LucideIcons.wallet,
          title: s.meWallets,
          onTap: () => context.push('/wallets'),
        ),
        SettingsRow(
          accent: true,
          icon: LucideIcons.layoutGrid,
          title: s.meCategories,
          onTap: () => context.push('/categories'),
        ),
        SettingsRow(
          accent: true,
          icon: LucideIcons.tag,
          title: s.meTags,
          onTap: soon,
        ),
        SettingsRow(
          accent: true,
          icon: LucideIcons.coins,
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
          accent: true,
          icon: LucideIcons.piggyBank,
          title: s.meBudget,
          onTap: soon,
        ),
        SettingsRow(
          accent: true,
          icon: LucideIcons.calendarDays,
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
          accent: true,
          icon: LucideIcons.target,
          title: s.meGoals,
          onTap: soon,
        ),
      ],
    );
  }
}
