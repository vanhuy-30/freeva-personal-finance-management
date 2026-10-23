import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/feedback.dart';
import '../viewmodels/feedback_view_model.dart';
import '../widgets/feedback_form.dart';
import '../widgets/feedback_thanks.dart';

/// Góp ý: a modal form, then a thank-you screen.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  late final FeedbackViewModel model = FeedbackViewModel(
    getIt<FeedbackUseCases>(),
    getIt<AuthViewModel>(),
  );
  final message = TextEditingController();

  @override
  void dispose() {
    model.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    await model.send();
    final failure = model.failure;
    if (!mounted || failure == null) return;
    final s = S.of(context);
    showFreevaToast(
      context,
      message: failure.code == AuthError.rateLimited
          ? s.meBusyRetry(((failure.retryAfter ?? 3600) / 60).ceil())
          : failure.code == AuthError.network
          ? s.meNetworkError
          : s.fbError,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      final margin = context.screenMargin;
      if (model.sent) {
        return Scaffold(
          body: SafeArea(
            child: FeedbackThanks(
              replies: model.allowReply,
              onDone: () => context.popOrGo('/me'),
            ),
          ),
        );
      }
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meFeedback,
          kind: FreevaTopBarKind.modal,
          onLeading: () => context.popOrGo('/me'),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            margin,
            FreevaSpace.s2,
            margin,
            FreevaSpace.s8,
          ),
          children: [
            FeedbackForm(model: model, message: message),
            const SizedBox(height: FreevaSpace.s5),
            FreevaButton(
              label: model.sending ? s.fbSending : s.fbSend,
              expand: true,
              onPressed: model.canSend ? _send : null,
            ),
          ],
        ),
      );
    },
  );
}
