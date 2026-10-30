import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../viewmodels/auth_view_model.dart';

class SessionAlertBanner extends StatefulWidget {
  const SessionAlertBanner({this.scrollTarget, this.onReview, super.key});

  /// Session list to scroll to on the same screen.
  final GlobalKey? scrollTarget;

  /// Or a navigation to where the session list lives.
  final VoidCallback? onReview;

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
        var timezone = 'Asia/Ho_Chi_Minh';
        if (getIt.isRegistered<ProfileViewModel>()) {
          timezone =
              getIt<ProfileViewModel>().saved?.timezone ?? timezone;
        }
        _auth.deliverSessionNotification(
          s.sessionAlertTitle,
          s.sessionAlertBody,
          timeZone: timezone,
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
                      widget.onReview?.call();
                      final target = widget.scrollTarget?.currentContext;
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
