import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../settings/domain/account_labels.dart';
import '../../../settings/presentation/viewmodels/settings_view_model.dart';
import '../../../settings/presentation/widgets/avatar_letter.dart';
import '../../../settings/presentation/widgets/profile_actions.dart';
import '../viewmodels/profile_view_model.dart';

/// Hồ sơ: information about you. Name is editable; the email changes later
/// (it needs a confirmation by mail).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileViewModel profile = getIt<ProfileViewModel>();
  final SettingsViewModel settings = getIt<SettingsViewModel>();
  late final TextEditingController name = TextEditingController(
    text: profile.saved?.displayName ?? '',
  );

  @override
  void initState() {
    super.initState();
    settings.refreshAccount();
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  String? get _typed => name.text.trim().isEmpty ? null : name.text.trim();

  bool get _changed => _typed != profile.saved?.displayName;

  Future<void> _save() async {
    final s = S.of(context);
    final ok = await applyProfile(
      context,
      profile,
      (p) => p.copyWith(displayName: _typed),
    );
    if (!ok || !mounted) return;
    showFreevaToast(context, message: s.meSaved);
    context.popOrGo('/me');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([profile, settings, name]),
    builder: (context, _) {
      final s = S.of(context);
      final c = context.colors;
      final margin = context.screenMargin;
      final email = settings.email;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meProfileTitle,
          onLeading: () => context.popOrGo('/me'),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, FreevaSpace.s8),
          children: [
            Center(child: AvatarLetter(name: _typed, email: email, size: 96)),
            const SizedBox(height: FreevaSpace.s6),
            FreevaTextField(
              label: s.meProfileName,
              controller: name,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_changed) _save();
              },
            ),
            if (email != null) ...[
              const SizedBox(height: FreevaSpace.s3),
              FreevaCard(
                list: true,
                onTap: () => showFreevaToast(context, message: s.meSoon),
                padding: const EdgeInsets.symmetric(
                  horizontal: FreevaSpace.s4,
                  vertical: FreevaSpace.s3,
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.mail, size: 18, color: c.textSecondary),
                    const SizedBox(width: FreevaSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.meProfileEmail,
                            style: FreevaTypography.label.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          Text(
                            maskEmail(email),
                            style: FreevaTypography.body.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      s.meChange,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.textLink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: FreevaSpace.s8),
            FreevaButton(
              label: s.meSave,
              expand: true,
              onPressed: _changed && !profile.loading ? _save : null,
            ),
          ],
        ),
      );
    },
  );
}
