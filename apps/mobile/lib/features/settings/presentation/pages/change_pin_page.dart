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

/// Đổi mã PIN: current, new, repeat. The current PIN counts as an unlock
/// attempt, so five misses sign the device out like on the lock screen.
class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
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
    final ok = await model.changePin(current.text, next.text, repeat.text);
    if (!ok || !mounted) return;
    showFreevaToast(context, message: s.mePinChanged);
    context.popOrGo('/me/security');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      final failure = model.failure;
      // A wrong current PIN belongs under its own field; every other refusal
      // (not 6 digits, no match, same as before) is about the new one.
      final wrong = failure?.code == AuthError.wrongPin;
      final sameAsOld = current.text.isNotEmpty && current.text == next.text;
      String? aboutNew;
      if (failure != null && !wrong) {
        aboutNew = sameAsOld && failure.code == AuthError.invalidInput
            ? s.mePinSame
            : securityError(s, failure, pin: true);
      }
      final reset = failure == null ? null : model.clear;

      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meChangePinTitle,
          onLeading: () => context.popOrGo('/me/security'),
        ),
        body: SecurityFormBody(
          hint: null,
          label: s.meSave,
          busy: model.busy,
          onSubmit: _submit,
          fields: [
            SecretField(
              label: s.mePinCurrent,
              controller: current,
              pin: true,
              error: wrong ? securityError(s, failure!, pin: true) : null,
              onChanged: reset,
            ),
            SecretField(
              label: s.mePinNew,
              controller: next,
              pin: true,
              error: aboutNew,
              onChanged: reset,
            ),
            SecretField(
              label: s.mePinRepeat,
              controller: repeat,
              pin: true,
              onChanged: reset,
            ),
          ],
        ),
      );
    },
  );
}
