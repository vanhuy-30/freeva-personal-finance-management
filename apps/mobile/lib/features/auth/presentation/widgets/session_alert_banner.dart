import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/auth_view_model.dart';

class SessionAlertBanner extends StatefulWidget {
  const SessionAlertBanner({required this.scrollTarget, super.key});

  final GlobalKey scrollTarget;

  @override
  State<SessionAlertBanner> createState() => _SessionAlertBannerState();
}

class _SessionAlertBannerState extends State<SessionAlertBanner> {
  late final AuthViewModel _auth;

  @override
  void initState() {
    super.initState();
    _auth = getIt<AuthViewModel>();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _auth,
    builder: (context, _) {
      if (!_auth.newSessionAlert) return const SizedBox.shrink();
      final s = S.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _auth.deliverSessionNotification(
          s.sessionAlertTitle,
          s.sessionAlertBody,
        );
      });
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.sessionAlertTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(s.sessionAlertBody),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () async {
                      await _auth.openSessionAlert();
                      final target = widget.scrollTarget.currentContext;
                      if (target != null && target.mounted) {
                        await Scrollable.ensureVisible(target);
                      }
                    },
                    child: Text(s.sessionAlertReview),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
