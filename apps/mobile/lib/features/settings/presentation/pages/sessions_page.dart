import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/domain/auth_use_cases.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../viewmodels/security_view_model.dart';
import '../widgets/security_form.dart';
import '../widgets/session_row.dart';

/// Phiên đăng nhập: this device and the others, with Thu hồi per device and
/// "Đăng xuất mọi máy khác".
class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  final AuthViewModel auth = getIt<AuthViewModel>();
  late final SecurityViewModel security = SecurityViewModel(
    getIt<AuthUseCases>(),
    auth,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(auth.loadSessions);
  }

  @override
  void dispose() {
    security.dispose();
    super.dispose();
  }

  Future<void> _revoke(AuthSession session) async {
    final s = S.of(context);
    final ok = await showFreevaConfirm(
      context: context,
      title: s.meRevokeTitle,
      message: s.meRevokeBody,
      cancelLabel: s.commonCancel,
      confirmLabel: s.meRevoke,
      destructive: true,
    );
    if (ok) await auth.revoke(session);
  }

  Future<void> _revokeOthers() async {
    final s = S.of(context);
    final ok = await showFreevaConfirm(
      context: context,
      title: s.meRevokeOthersTitle,
      message: s.meRevokeOthersBody,
      cancelLabel: s.commonCancel,
      confirmLabel: s.meRevokeOthers,
      destructive: true,
    );
    if (!ok) return;
    final done = await security.revokeOthers();
    if (done) await auth.loadSessions();
    if (!mounted) return;
    final failure = security.failure;
    if (failure != null) {
      showFreevaToast(context, message: securityError(s, failure, pin: false));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([auth, security]),
    builder: (context, _) {
      final s = S.of(context);
      final c = context.colors;
      final margin = context.screenMargin;
      final sessions = [...auth.sessions]
        ..sort((a, b) => a.current == b.current ? 0 : (a.current ? -1 : 1));
      final others = sessions.any((session) => !session.current);
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meSecSessions,
          onLeading: () => context.popOrGo('/me/security'),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, FreevaSpace.s8),
          children: [
            Text(
              s.meSessionsHint,
              style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: FreevaSpace.s4),
            if (sessions.isEmpty && auth.failure != null && !auth.loading)
              ErrorRetry(
                title: s.meSaveError,
                message: s.homeErrorBody,
                onRetry: auth.loadSessions,
              )
            else
              FreevaCard(
                list: true,
                padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
                child: Column(
                  children: [
                    for (final (i, session) in sessions.indexed) ...[
                      if (i > 0) Divider(height: 1, color: c.listDivider),
                      SessionRow(
                        session: session,
                        onRevoke: () => _revoke(session),
                      ),
                    ],
                  ],
                ),
              ),
            if (others) ...[
              const SizedBox(height: FreevaSpace.s5),
              FreevaButton(
                label: s.meRevokeOthers,
                variant: FreevaButtonVariant.secondary,
                expand: true,
                onPressed: security.busy ? null : _revokeOthers,
              ),
            ],
          ],
        ),
      );
    },
  );
}
