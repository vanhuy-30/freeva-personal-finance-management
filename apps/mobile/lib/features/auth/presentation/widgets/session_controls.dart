import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/auth_view_model.dart';
import 'auth_message.dart';

class SessionControls extends StatelessWidget {
  const SessionControls({super.key});
  @override
  Widget build(BuildContext context) {
    final model = getIt<AuthViewModel>();
    final s = S.of(context);
    return ListenableBuilder(
        listenable: model,
        builder: (context, _) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AuthMessage(model: model),
              OutlinedButton(
                  onPressed: model.loading ? null : model.loadSessions,
                  child: Text(s.authSessions)),
              ...model.sessions.map((session) => ListTile(
                    title: Text(session.current
                        ? s.authCurrentSession
                        : s.authOtherSession),
                    subtitle: Text(s.authSessionExpiry(
                        DateFormat.yMd(s.localeName)
                            .add_Hm()
                            .format(session.expiresAt.toLocal()))),
                    trailing: IconButton(
                        tooltip: s.authRevoke,
                        icon: const Icon(Icons.logout),
                        onPressed:
                            model.loading ? null : () => model.revoke(session)),
                  )),
              if (model.sessions.isNotEmpty)
                TextButton(
                    onPressed: model.loading ? null : () => model.revoke(null),
                    child: Text(s.authRevokeAll)),
              TextButton(
                  onPressed: model.loading ? null : model.lock,
                  child: Text(s.authLockNow)),
              TextButton(
                  onPressed: model.loading ? null : model.logout,
                  child: Text(s.authLogout)),
            ]));
  }
}
