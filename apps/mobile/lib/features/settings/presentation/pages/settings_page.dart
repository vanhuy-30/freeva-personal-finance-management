import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../goals/presentation/viewmodels/goal_view_model.dart';
import '../../../debts/presentation/viewmodels/debt_view_model.dart';
import '../../../loans/presentation/viewmodels/loan_view_model.dart';
import '../../../recurring/presentation/viewmodels/recurring_view_model.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../auto_suggest/presentation/viewmodels/auto_suggest_view_model.dart';
import '../../../auth/presentation/widgets/session_alert_banner.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../tags/domain/tag_use_cases.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/app_settings_group.dart';
import '../widgets/danger_text_button.dart';
import '../widgets/data_settings_group.dart';
import '../widgets/help_settings_group.dart';
import '../widgets/manage_grid.dart';
import '../widgets/money_setup_group.dart';
import '../widgets/profile_card.dart';
import '../../../../core/app_version/app_version.dart';

/// Cá nhân: the tab root. Profile card, the money grid, four groups, log out
/// and version.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsViewModel settings = getIt<SettingsViewModel>();
  late final ProfileViewModel profile = getIt<ProfileViewModel>();
  final WalletViewModel? wallets = getIt.isRegistered<WalletViewModel>()
      ? getIt<WalletViewModel>()
      : null;
  final GoalViewModel? goals = getIt.isRegistered<GoalViewModel>()
      ? getIt<GoalViewModel>()
      : null;
  final DebtViewModel? debts = getIt.isRegistered<DebtViewModel>()
      ? getIt<DebtViewModel>()
      : null;
  final LoanViewModel? loans = getIt.isRegistered<LoanViewModel>()
      ? getIt<LoanViewModel>()
      : null;
  final RecurringViewModel? recurring = getIt.isRegistered<RecurringViewModel>()
      ? getIt<RecurringViewModel>()
      : null;
  final AutoSuggestViewModel? autoSuggest =
      getIt.isRegistered<AutoSuggestViewModel>()
      ? getIt<AutoSuggestViewModel>()
      : null;
  int? tagCount;

  @override
  void initState() {
    super.initState();
    // Defer: load() notifies before await; FreevaApp listens to settings.
    Future.microtask(() {
      settings.refreshAccount();
      settings.refreshBiometrics();
      // Fresh copy: first run saves the budget draft through another writer.
      settings.load();
      if (wallets case final w? when w.wallets.isEmpty) w.load();
      goals?.load();
      debts?.load();
      loans?.load();
      recurring?.load();
    });
    _loadTags();
  }

  Future<void> _loadTags() async {
    if (!getIt.isRegistered<TagUseCases>()) return;
    final result = await getIt<TagUseCases>().list();
    if (!mounted) return;
    result.fold((_) {}, (tags) => setState(() => tagCount = tags.length));
  }

  /// Open debts plus loans still being paid, once both are known.
  int? get _debtCount {
    final d = debts, l = loans;
    if (d == null || l == null || !d.loaded || !l.loaded) return null;
    return d.openCount + l.openCount;
  }

  int? get _walletCount {
    final w = wallets;
    if (w == null || (w.wallets.isEmpty && w.busy)) return null;
    return w.active.length;
  }

  Future<void> _logout() async {
    final s = S.of(context);
    final ok = await showFreevaConfirm(
      context: context,
      title: s.meLogoutTitle,
      message: s.meLogoutBody,
      icon: LucideIcons.logOut,
      iconTone: FreevaDialogTone.danger,
      cancelLabel: s.commonCancel,
      confirmLabel: s.meLogout,
      destructive: true,
    );
    if (ok) await getIt<AuthViewModel>().logout();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      settings,
      profile,
      if (goals != null) goals!,
      if (debts != null) debts!,
      if (loans != null) loans!,
      if (recurring != null) recurring!,
      if (wallets != null) wallets!,
      if (autoSuggest != null) autoSuggest!,
    ]),
    builder: (context, _) {
      final s = S.of(context);
      final c = context.colors;
      final margin = context.screenMargin;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meTitle,
          kind: FreevaTopBarKind.largeTitle,
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            margin,
            FreevaSpace.s2,
            margin,
            FreevaLayout.navReserve,
          ),
          children: [
            SessionAlertBanner(onReview: () => context.push('/me/sessions')),
            ProfileCard(
              name: profile.saved?.displayName,
              email: settings.email,
            ),
            ManageGrid(
              walletCount: _walletCount,
              budget: settings.budgetDraftMinor,
              goalCount: goals != null && goals!.loaded
                  ? goals!.active.length
                  : null,
              debtCount: _debtCount,
              recurringCount: recurring != null && recurring!.loaded
                  ? recurring!.rules.length
                  : null,
              month: DateTime.now().month,
            ),
            MoneySetupGroup(profile: profile, tagCount: tagCount),
            AppSettingsGroup(
              settings: settings,
              profile: profile,
              autoSuggest: autoSuggest,
            ),
            const DataSettingsGroup(),
            const HelpSettingsGroup(),
            const SizedBox(height: FreevaSpace.s4),
            DangerTextButton(
              icon: LucideIcons.logOut,
              label: s.meLogout,
              onPressed: _logout,
            ),
            const SizedBox(height: 6),
            Text(
              s.settingsVersion(getIt<AppVersion>().display),
              textAlign: TextAlign.center,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textDisabled,
              ),
            ),
          ],
        ),
      );
    },
  );
}
