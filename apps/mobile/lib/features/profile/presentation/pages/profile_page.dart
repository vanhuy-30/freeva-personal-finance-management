import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/profile_view_model.dart';
import '../widgets/profile_form.dart';
import '../widgets/profile_status.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final model = getIt<ProfileViewModel>();
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final s = S.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(s.profileTitle),
            leading: IconButton(
              tooltip: s.profileBack,
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                model.cancel();
                context.go('/home');
              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (model.loading) const LinearProgressIndicator(),
                      ProfileStatus(model: model),
                      if (model.draft != null && model.options != null)
                        ProfileForm(model: model),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
