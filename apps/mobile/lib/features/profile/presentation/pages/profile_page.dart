import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../settings/presentation/viewmodels/settings_view_model.dart';
import '../../../settings/presentation/widgets/avatar_letter.dart';
import '../../../settings/presentation/widgets/danger_text_button.dart';
import '../../../settings/presentation/widgets/profile_actions.dart';
import '../../domain/avatar_picker.dart';
import '../../../../core/widgets/freeva_banner.dart';
import '../viewmodels/avatar_view_model.dart';
import '../viewmodels/email_verification_controller.dart';
import '../viewmodels/profile_view_model.dart';
import '../widgets/account_step_up.dart';
import '../../../server_config/domain/app_limits.dart';

/// Hồ sơ: information about you. Name is editable; the email changes later
/// (it needs a confirmation by mail).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  final ProfileViewModel profile = getIt<ProfileViewModel>();
  final SettingsViewModel settings = getIt<SettingsViewModel>();
  final AvatarViewModel avatar = getIt<AvatarViewModel>();
  late final TextEditingController name = TextEditingController(
    text: profile.saved?.displayName ?? '',
  );

  late final EmailVerificationController emailSend =
      EmailVerificationController(resend: _resendVerification);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(settings.refreshAccount);
    // The email may have been confirmed in the browser since the profile was
    // last read; ask again so the row is right when the page opens.
    if (profile.saved?.emailVerified != true) Future.microtask(profile.load);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    emailSend.dispose();
    name.dispose();
    super.dispose();
  }

  /// Back from the browser (or mail app): the link there may have confirmed
  /// the email, and only the server knows.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        profile.saved?.emailVerified == false) {
      profile.load();
    }
  }

  /// Uses the email kept on the device: the sign-in draft is empty after a cold
  /// start. The server answers 202 whether or not it sends.
  Future<AuthFailure?> _resendVerification() async {
    final auth = getIt<AuthViewModel>();
    if (auth.loading) return const AuthFailure(AuthError.unavailable);
    auth.draftEmail(settings.email ?? '');
    await auth.resendVerification();
    final failure = auth.failure;
    auth.clearMessage();
    return failure;
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

  /// Camera button: take a photo, choose one, or remove the one there.
  Future<void> _editAvatar(BuildContext context) async {
    final s = S.of(context);
    if (avatar.busy) return;
    final action = await showFreevaSheet<_AvatarAction>(
      context: context,
      title: s.meChangeAvatar,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.camera),
            title: Text(s.meAvatarCamera),
            onTap: () => Navigator.of(sheet).pop(_AvatarAction.camera),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.image),
            title: Text(s.meAvatarPick),
            onTap: () => Navigator.of(sheet).pop(_AvatarAction.library),
          ),
          if (avatar.image != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                LucideIcons.trash,
                color: sheet.colors.statusDanger,
              ),
              title: Text(
                s.meAvatarRemove,
                style: TextStyle(color: sheet.colors.statusDanger),
              ),
              onTap: () => Navigator.of(sheet).pop(_AvatarAction.remove),
            ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    final outcome = switch (action) {
      _AvatarAction.camera => await avatar.change(AvatarSource.camera),
      _AvatarAction.library => await avatar.change(AvatarSource.library),
      _AvatarAction.remove => await avatar.remove(),
    };
    if (!context.mounted) return;
    final message = switch (outcome) {
      AvatarOutcome.saved => s.meAvatarSaved,
      AvatarOutcome.removed => s.meAvatarRemoved,
      AvatarOutcome.unreadable => s.meAvatarUnreadable,
      AvatarOutcome.failed => s.meAvatarError,
      AvatarOutcome.cancelled => null,
    };
    if (message != null) showFreevaToast(context, message: message);
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
    if (!ok || !mounted) return;
    final password = await askAccountPassword(context);
    if (password == null || !mounted) return;
    await auth.deleteAccount(password: password);
    // On success the stage is signedOut and AuthGate has left this page.
    if (!mounted || auth.stage == AuthStage.signedOut) return;
    final failure = auth.failure;
    showFreevaToast(
      context,
      message: failure == null
          ? s.meDeleteError
          : accountStepUpError(s, failure, s.meDeleteError),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([profile, settings, name, avatar, emailSend]),
    builder: (context, _) {
      final s = S.of(context);
      final margin = context.screenMargin;
      final email = settings.email;
      void soon() => showFreevaToast(context, message: s.meSoon);
      Future<void> editAvatar() => _editAvatar(context);
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
                          image: avatar.image,
                          busy: avatar.busy,
                          onEdit: editAvatar,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FreevaTextField(
                        label: s.meProfileName,
                        controller: name,
                        leadingIcon: LucideIcons.user,
                        maxLength: getIt<AppLimitsSource>()
                            .requireLimits
                            .displayNameMaxLength,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (_changed) _save();
                        },
                      ),
                      if (email != null) ...[
                        const SizedBox(height: 14),
                        _EmailField(
                          email: email,
                          verified: profile.saved?.emailVerified,
                          onChange: soon,
                        ),
                        if (profile.saved?.emailVerified == false)
                          _EmailVerifyBanner(controller: emailSend),
                      ],
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

enum _AvatarAction { camera, library, remove }

/// 96 letter avatar with the 36 ink camera button over its lower right edge.
class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.name,
    required this.email,
    required this.image,
    required this.busy,
    required this.onEdit,
  });

  final String? name;
  final String? email;
  final Uint8List? image;
  final bool busy;
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
          AvatarLetter(
            name: name,
            email: email,
            image: image,
            size: 96,
            letterSize: 34,
          ),
          if (busy)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
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
                      size: 16,
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
  const _EmailField({
    required this.email,
    required this.verified,
    required this.onChange,
  });

  final String email;

  /// Null when the server does not say; the label is then a plain "Email".
  final bool? verified;
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
                        switch (verified) {
                          true => s.meProfileEmailVerified,
                          false => s.meProfileEmailUnverified,
                          null => s.meProfileEmail,
                        },
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FreevaTypography.bodyL.copyWith(
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

/// Under an unconfirmed email: why it matters and "Gửi link xác nhận". The
/// state follows [EmailVerificationController]; the profile decides when the
/// whole banner goes away (once the server reports the email confirmed).
class _EmailVerifyBanner extends StatelessWidget {
  const _EmailVerifyBanner({required this.controller});

  final EmailVerificationController controller;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = controller.state;
    final (message, icon, tone) = switch (state) {
      EmailSendState.sent => (
        s.meEmailSent,
        LucideIcons.circleCheck,
        FreevaBannerTone.success,
      ),
      EmailSendState.limited => (
        s.meBusyRetry(controller.retryMinutes ?? 15),
        LucideIcons.clock,
        FreevaBannerTone.warning,
      ),
      EmailSendState.failed => (
        s.meEmailSendError,
        LucideIcons.triangleAlert,
        FreevaBannerTone.danger,
      ),
      _ => (
        s.meEmailUnverifiedHint,
        LucideIcons.mail,
        FreevaBannerTone.warning,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: FreevaSpace.s3),
      child: FreevaBanner(
        message: message,
        icon: icon,
        tone: tone,
        actionLabel: controller.canSend ? s.meEmailSendLink : null,
        onAction: controller.canSend ? controller.send : null,
      ),
    );
  }
}
