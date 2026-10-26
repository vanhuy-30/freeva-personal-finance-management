import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/domain/auth_use_cases.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../viewmodels/security_view_model.dart';
import '../widgets/security_form.dart';

/// Đổi mật khẩu while signed in. The server keeps this device signed in and
/// ends every other one.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late final SecurityViewModel model = SecurityViewModel(
    getIt<AuthUseCases>(),
    getIt<AuthViewModel>(),
  );
  final current = TextEditingController();
  final next = TextEditingController();
  final repeat = TextEditingController();

  @override
  void dispose() {
    model.dispose();
    current.dispose();
    next.dispose();
    repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = S.of(context);
    final ok = await model.changePassword(current.text, next.text, repeat.text);
    if (!ok || !mounted) return;
    showFreevaToast(context, message: s.mePasswordChanged);
    context.popOrGo('/me/security');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      final failure = model.failure;
      final wrong = failure?.code == AuthError.credentials;
      final other = failure != null && !wrong;
      VoidCallback? reset() => failure == null ? null : model.clear;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meChangePasswordTitle,
          onLeading: () => context.popOrGo('/me/security'),
        ),
        body: SecurityFormBody(
          hint: s.mePasswordHint,
          label: s.meSave,
          busy: model.busy,
          onSubmit: _submit,
          fields: [
            SecretField(
              label: s.mePasswordCurrent,
              controller: current,
              error: wrong ? securityError(s, failure!, pin: false) : null,
              onChanged: reset(),
            ),
            SecretField(
              label: s.mePasswordNew,
              controller: next,
              error: other ? securityError(s, failure, pin: false) : null,
              onChanged: reset(),
            ),
            SecretField(
              label: s.mePasswordRepeat,
              controller: repeat,
              onChanged: reset(),
            ),
          ],
        ),
      );
    },
  );
}
