import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../sync/presentation/viewmodels/sync_view_model.dart';
import '../../domain/deep_link_service.dart';
import '../viewmodels/auth_link_handler.dart';
import '../viewmodels/auth_view_model.dart';

/// Sits above the router and hands email links to [AuthLinkHandler].
///
/// It listens to both the link service and the auth view model, because a link
/// can arrive before auth is ready and auth can become ready after it.
class AuthLinkHost extends StatefulWidget {
  const AuthLinkHost({
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  /// The app's root navigator; dialogs and toasts need a context below it.
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AuthLinkHost> createState() => _AuthLinkHostState();
}

class _AuthLinkHostState extends State<AuthLinkHost> {
  late final DeepLinkService _service = getIt<DeepLinkService>();
  late final AuthViewModel _auth = getIt<AuthViewModel>();
  late final AuthLinkHandler _handler = AuthLinkHandler(
    service: _service,
    auth: _auth,
    confirmSignOut: _confirmSignOut,
    onInvalidLink: () => _toast((s) => s.authLinkInvalid),
    onSignOutFailed: () => _toast((s) => s.authLinkSignOutFailed),
  );

  @override
  void initState() {
    super.initState();
    _service.addListener(_changed);
    _auth.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _changed());
  }

  @override
  void dispose() {
    _service.removeListener(_changed);
    _auth.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) unawaited(_handler.process());
  }

  /// This widget sits above the navigator, so it borrows the navigator's context.
  BuildContext? get _overlayContext => widget.navigatorKey.currentContext;

  void _toast(String Function(S s) message) {
    final context = _overlayContext;
    final overlay = widget.navigatorKey.currentState?.overlay;
    if (context == null || !context.mounted || overlay == null) return;
    // This widget is above the navigator, so the toast gets the root overlay
    // directly instead of looking it up from a context.
    showFreevaToast(context, message: message(S.of(context)), overlay: overlay);
  }

  Future<bool> _confirmSignOut() async {
    final context = _overlayContext;
    if (context == null || !context.mounted) return false;
    final s = S.of(context);
    final unsynced = getIt<SyncViewModel>().items.isNotEmpty;
    return showFreevaConfirm(
      context: context,
      title: s.authLinkSignOutTitle,
      message: unsynced ? s.authLinkSignOutUnsynced : s.authLinkSignOutBody,
      icon: LucideIcons.logOut,
      iconTone: FreevaDialogTone.danger,
      cancelLabel: s.commonCancel,
      confirmLabel: s.authLinkSignOutConfirm,
      destructive: unsynced,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
