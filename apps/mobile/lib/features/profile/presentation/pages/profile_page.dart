import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../settings/domain/account_labels.dart';
import '../../../settings/presentation/viewmodels/settings_view_model.dart';
import '../../../settings/presentation/widgets/avatar_letter.dart';
import '../../../settings/presentation/widgets/danger_text_button.dart';
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
    Future.microtask(settings.refreshAccount);
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

  Future<void> _export() async {
    final s = S.of(context);
    await profile.exportData();
    if (!mounted || profile.failure == null) return;
    showFreevaToast(context, message: s.meExportError);
  }

  Future<void> _delete() async {
    final s = S.of(context);
    final auth = getIt<AuthViewModel>();
    final ok = await showFreevaConfirm(
      context: context,
      title: s.meDeleteTitle,
      message: s.meDeleteBody,
      icon: LucideIcons.trash,
      iconTone: FreevaDialogTone.danger,
      cancelLabel: s.commonCancel,
      confirmLabel: s.meDeleteConfirm,
      destructive: true,
    );
    if (!ok) return;
    await auth.deleteAccount();
    // On success the stage is signedOut and AuthGate has left this page.
    if (!mounted || auth.stage == AuthStage.signedOut) return;
    showFreevaToast(context, message: s.meDeleteError);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([profile, settings, name]),
    builder: (context, _) {
      final s = S.of(context);
      final margin = context.screenMargin;
      final email = settings.email;
      void soon() => showFreevaToast(context, message: s.meSoon);
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meProfileTitle,
          onLeading: () => context.popOrGo('/me'),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(margin, 0, margin, FreevaSpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: FreevaSpace.s2),
                    children: [
                      const SizedBox(height: FreevaSpace.s2),
                      Center(
                        child: _EditableAvatar(
                          name: _typed,
                          email: email,
                          onEdit: soon,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FreevaTextField(
                        label: s.meProfileName,
                        controller: name,
                        leadingIcon: LucideIcons.user,
                        maxLength: 50,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (_changed) _save();
                        },
                      ),
                      if (email != null) ...[
                        const SizedBox(height: 14),
                        _EmailField(email: email, onChange: soon),
                      ],
                      const SizedBox(height: 14),
                      SettingsRow(
                        icon: LucideIcons.download,
                        title: s.meExportData,
                        subtitle: s.meExportHint,
                        chevron: false,
                        onTap: profile.exporting ? null : _export,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FreevaSpace.s2),
                DangerTextButton(
                  icon: LucideIcons.trash,
                  label: s.meDeleteAccount,
                  onPressed: _delete,
                ),
                const SizedBox(height: 14),
                FreevaButton(
                  label: s.meSave,
                  size: FreevaButtonSize.l,
                  expand: true,
                  onPressed: _changed && !profile.loading ? _save : null,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 96 letter avatar with the 36 ink camera button over its lower right edge.
class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final String? name;
  final String? email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AvatarLetter(name: name, email: email, size: 96, letterSize: 34),
          PositionedDirectional(
            end: -2 - 4,
            bottom: -2 - 4,
            child: Semantics(
              button: true,
              label: S.of(context).meChangeAvatar,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit,
                // 44 touch area around the 36 button.
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.buttonInkBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bgCanvas, width: 3),
                    ),
                    child: Icon(
                      LucideIcons.camera,
                      size: 15,
                      color: c.buttonInkFg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Email in the same boxed style as the name field, with "Đổi" on the right.
class _EmailField extends StatelessWidget {
  const _EmailField({required this.email, required this.onChange});

  final String email;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaComponent.inputRadius);
    return Material(
      color: c.inputBg,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.inputBorder),
      ),
      child: InkWell(
        onTap: onChange,
        borderRadius: radius,
        splashFactory: NoSplash.splashFactory,
        highlightColor: c.bgSubtle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
            child: Row(
              children: [
                Container(
                  width: FreevaSize.iconTile,
                  height: FreevaSize.iconTile,
                  decoration: BoxDecoration(
                    color: c.bgSubtle,
                    borderRadius: BorderRadius.circular(FreevaRadius.xs),
                  ),
                  child: Icon(
                    LucideIcons.mail,
                    size: FreevaSize.iconChip,
                    color: c.textOnWash,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // No verification state from the API yet, so no "đã xác nhận".
                        s.meProfileEmail,
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        maskEmail(email),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FreevaTypography.body.copyWith(
                          fontSize: 16,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  s.meChange,
                  style: FreevaTypography.titleM.copyWith(
                    fontSize: 14,
                    color: c.textLink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
