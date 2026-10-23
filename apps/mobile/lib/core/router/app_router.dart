import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/auth/presentation/widgets/auth_gate.dart';
import '../../features/categories/presentation/pages/category_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/notifications_page.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reports/presentation/pages/report_page.dart';
import '../../features/settings/domain/app_preferences.dart';
import '../../features/settings/presentation/pages/faq_page.dart';
import '../../features/settings/presentation/pages/feedback_page.dart';
import '../../features/settings/presentation/pages/legal_page.dart';
import '../../features/settings/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/viewmodels/settings_view_model.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/transactions/presentation/pages/deleted_transactions_page.dart';
import '../../features/transactions/presentation/pages/record_transaction_page.dart';
import '../../features/transactions/presentation/pages/transaction_page.dart';
import '../../features/transactions/presentation/pages/transaction_search_page.dart';
import '../../features/wallets/presentation/pages/hidden_wallets_page.dart';
import '../../features/wallets/presentation/pages/wallet_detail_page.dart';
import '../../features/wallets/presentation/pages/wallet_page.dart';
import '../../features/wallets/presentation/pages/wallet_sort_page.dart';
import '../di/injection.dart';
import '../logging/app_logger.dart';
import '../logging/logging_navigator_observer.dart';
import '../widgets/gallery/widget_gallery_page.dart';
import 'app_shell.dart';
import 'settings_redirect.dart';

GoRouter? _appRouter;
RouterRefresh? _refresh;

GoRouter get appRouter {
  final router = _appRouter;
  if (router == null) {
    throw StateError('Call createAppRouter after dependencies are ready');
  }
  return router;
}

GoRouter createAppRouter() {
  if (_appRouter != null) return _appRouter!;
  final auth = getIt<AuthViewModel>();
  final settings = getIt<SettingsViewModel>();
  _refresh = RouterRefresh([auth, settings]);
  _appRouter = _createAppRouter(auth, settings, _refresh!, getIt<AppLogger>());
  return _appRouter!;
}

void resetAppRouter() {
  _appRouter?.dispose();
  _refresh?.dispose();
  _appRouter = null;
  _refresh = null;
}

class RouterRefresh extends ChangeNotifier {
  RouterRefresh(this._sources) {
    for (final source in _sources) {
      source.addListener(_defer);
    }
  }

  final List<Listenable> _sources;
  var _scheduled = false;
  var _disposed = false;

  void _defer() {
    if (_disposed || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (final source in _sources) {
      source.removeListener(_defer);
    }
    super.dispose();
  }
}

GoRouter _createAppRouter(
  AuthViewModel auth,
  SettingsViewModel settings,
  Listenable refresh,
  AppLogger logger,
) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    observers: [LoggingNavigatorObserver(logger)],
    redirect: (context, state) {
      final next = settingsRedirect(
        stage: auth.stage,
        onboardingCompleted: settings.onboardingCompleted,
        path: state.uri.path,
      );
      if (next != null) {
        logger.op('nav redirect ${state.uri.path} → $next');
      }
      return next;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            AuthGate(child: AppShell(navigationShell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => TransactionPage(
                  record: state.uri.queryParameters['record'] == '1',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/settings', redirect: (context, state) => '/me'),
      GoRoute(
        path: '/record',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: AuthGate(
            child: RecordTransactionPage(
              type: TransactionType.values
                  .where((t) => t.name == state.uri.queryParameters['type'])
                  .firstOrNull,
              fromAccountId: state.uri.queryParameters['from'],
              toAccountId: state.uri.queryParameters['to'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/transactions/search',
        builder: (context, state) =>
            const AuthGate(child: TransactionSearchPage()),
      ),
      GoRoute(
        path: '/transactions/deleted',
        builder: (context, state) =>
            const AuthGate(child: DeletedTransactionsPage()),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const AuthGate(child: NotificationsPage()),
      ),
      GoRoute(
        path: '/wallets',
        builder: (context, state) => const AuthGate(child: WalletPage()),
        routes: [
          GoRoute(
            path: 'sort',
            builder: (context, state) =>
                const AuthGate(child: WalletSortPage()),
          ),
          GoRoute(
            path: 'hidden',
            builder: (context, state) =>
                const AuthGate(child: HiddenWalletsPage()),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => AuthGate(
              child: WalletDetailPage(walletId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const AuthGate(child: CategoryPage()),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const AuthGate(child: ProfilePage()),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const AuthGate(child: OnboardingPage()),
      ),
      GoRoute(
        path: '/help/faq',
        builder: (context, state) => const AuthGate(child: FaqPage()),
      ),
      GoRoute(
        path: '/help/feedback',
        builder: (context, state) => const AuthGate(child: FeedbackPage()),
      ),
      GoRoute(
        path: '/help/legal',
        builder: (context, state) => AuthGate(
          child: LegalPage(
            document: state.uri.queryParameters['doc'] == 'privacy'
                ? LegalDocument.privacy
                : LegalDocument.terms,
          ),
        ),
      ),
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashPage(),
      ),
      if (kDebugMode)
        GoRoute(
          path: '/debug/gallery',
          builder: (context, state) => const WidgetGalleryPage(),
        ),
    ],
  );
}
