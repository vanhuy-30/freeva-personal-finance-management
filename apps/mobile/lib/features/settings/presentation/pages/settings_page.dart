import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../auth/presentation/widgets/session_alert_banner.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../tags/domain/tag_use_cases.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/app_preferences.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/app_settings_group.dart';
import '../widgets/danger_text_button.dart';
import '../widgets/help_settings_group.dart';
import '../widgets/money_setup_group.dart';
import '../widgets/profile_card.dart';

/// Cá nhân: the tab root. Profile card, three groups, log out and version.
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
    });
    _loadTags();
  }

  Future<void> _loadTags() async {
    if (!getIt.isRegistered<TagUseCases>()) return;
    final result = await getIt<TagUseCases>().list();
    if (!mounted) return;
    result.fold((_) {}, (tags) => setState(() => tagCount = tags.length));
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
      if (wallets != null) wallets!,
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
            MoneySetupGroup(
              profile: profile,
              walletCount: _walletCount,
              tagCount: tagCount,
              budget: settings.budgetDraftMinor,
            ),
            AppSettingsGroup(settings: settings, profile: profile),
            const HelpSettingsGroup(),
            const SizedBox(height: FreevaSpace.s4),
            DangerTextButton(
              icon: LucideIcons.logOut,
              label: s.meLogout,
              onPressed: _logout,
            ),
            const SizedBox(height: 6),
            Text(
              s.settingsVersion(appVersionDisplay),
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
