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
import '../../../auto_suggest/presentation/viewmodels/auto_suggest_view_model.dart';
import '../../../auth/presentation/widgets/session_alert_banner.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../tags/domain/tag_use_cases.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/app_settings_group.dart';
import '../widgets/danger_text_button.dart';
import '../widgets/data_settings_group.dart';
import '../widgets/manage_grid.dart';
import '../widgets/money_setup_group.dart';
import '../widgets/profile_card.dart';
import '../../../../core/app_version/app_version.dart';

/// Cá nhân: the tab root. Profile card, Tài sản and Kế hoạch tiles, three
/// groups of rows, log out and version.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsViewModel settings = getIt<SettingsViewModel>();
  late final ProfileViewModel profile = getIt<ProfileViewModel>();
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
    });
    _loadTags();
  }

  Future<void> _loadTags() async {
    if (!getIt.isRegistered<TagUseCases>()) return;
    final result = await getIt<TagUseCases>().list();
    if (!mounted) return;
    result.fold((_) {}, (tags) => setState(() => tagCount = tags.length));
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
            const ManageGrid(),
            MoneySetupGroup(
              profile: profile,
              tagCount: tagCount,
              autoSuggest: autoSuggest,
            ),
            AppSettingsGroup(settings: settings, profile: profile),
            const DataSettingsGroup(),
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
