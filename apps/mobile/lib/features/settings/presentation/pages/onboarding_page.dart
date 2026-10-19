import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/onboarding_controls.dart';
import '../widgets/onboarding_step.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final SettingsViewModel _model = getIt<SettingsViewModel>();
  var _step = 0;

  @override
  void initState() {
    super.initState();
    _model.beginOnboarding();
  }

  Future<void> _finish() async {
    final saved = await _model.completeOnboarding();
    if (saved && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final steps = [
      OnboardingStep(
        title: s.onboardingWelcomeTitle,
        body: s.onboardingWelcomeBody,
      ),
      OnboardingStep(
        title: s.onboardingWalletTitle,
        body: s.onboardingWalletBody,
      ),
      OnboardingStep(
        title: s.onboardingTransactionTitle,
        body: s.onboardingTransactionBody,
      ),
    ];
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _model.loading ? null : _finish,
                    child: Text(s.onboardingSkip),
                  ),
                ),
                steps[_step],
                if (_model.failure != null) Text(s.settingsStorageError),
                OnboardingControls(
                  step: _step,
                  last: _step == steps.length - 1,
                  loading: _model.loading,
                  onBack: () => setState(() => _step -= 1),
                  onNext: () {
                    if (_step < steps.length - 1) {
                      setState(() => _step += 1);
                    } else {
                      _finish();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
