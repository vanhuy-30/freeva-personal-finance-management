import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../auth/presentation/widgets/pin_setup_flow.dart';

/// Đặt mã PIN from Bảo mật, for people who skipped it at sign-up.
class PinSetupPage extends StatelessWidget {
  const PinSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = getIt<AuthViewModel>();
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => PinSetupFlow(
        model: model,
        onSkip: () => context.popOrGo('/me/security'),
        onBack: () => context.popOrGo('/me/security'),
        onDone: () {
          showFreevaToast(context, message: S.of(context).meSecPinSetDone);
          context.popOrGo('/me/security');
        },
      ),
    );
  }
}
