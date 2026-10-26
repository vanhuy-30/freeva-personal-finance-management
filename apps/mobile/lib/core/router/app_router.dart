import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/auth/presentation/widgets/auth_gate.dart';
import '../../features/categories/presentation/pages/category_page.dart';
import '../../features/categories/presentation/pages/hidden_categories_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/notifications_page.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reports/domain/category_detail.dart';
import '../../features/reports/presentation/pages/report_category_page.dart';
import '../../features/reports/presentation/pages/report_page.dart';
import '../../features/settings/domain/app_preferences.dart';
import '../../features/sync/presentation/pages/sync_compare_page.dart';
import '../../features/sync/presentation/pages/sync_page.dart';
import '../../features/sync/presentation/widgets/sync_duplicate_host.dart';
import '../../features/settings/presentation/pages/faq_page.dart';
import '../../features/feedback/presentation/pages/feedback_page.dart';
import '../../features/settings/presentation/pages/legal_page.dart';
import '../../features/settings/presentation/pages/change_password_page.dart';
import '../../features/tags/presentation/pages/tag_page.dart';
import '../../features/settings/presentation/pages/change_pin_page.dart';
import '../../features/settings/presentation/pages/pin_setup_page.dart';
import '../../features/settings/presentation/pages/notification_settings_page.dart';
import '../../features/settings/presentation/pages/security_page.dart';
import '../../features/settings/presentation/pages/sessions_page.dart';
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
  _appRouter = _createAppRouter(_refresh!, getIt<AppLogger>());
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

GoRouter _createAppRouter(Listenable refresh, AppLogger logger) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    observers: [LoggingNavigatorObserver(logger)],
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AuthGate(
          child: SyncDuplicateHost(child: AppShell(navigationShell: shell)),
        ),
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
      GoRoute(
        path: '/reports/category',
        redirect: (context, state) =>
            state.extra is CategoryDetailArgs ? null : '/reports',
        builder: (context, state) => AuthGate(
          child: ReportCategoryPage(args: state.extra! as CategoryDetailArgs),
        ),
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
        path: '/sync',
        builder: (context, state) => const AuthGate(child: SyncPage()),
        routes: [
          GoRoute(
            path: 'compare/:opId',
            builder: (context, state) => AuthGate(
              child: SyncComparePage(opId: state.pathParameters['opId']!),
            ),
          ),
        ],
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
        routes: [
          GoRoute(
            path: 'hidden',
            builder: (context, state) =>
                const AuthGate(child: HiddenCategoriesPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const AuthGate(child: ProfilePage()),
      ),
      GoRoute(
        path: '/me/security',
        builder: (context, state) => const AuthGate(child: SecurityPage()),
        routes: [
          GoRoute(
            path: 'pin',
            builder: (context, state) => const AuthGate(child: ChangePinPage()),
          ),
          GoRoute(
            path: 'pin-setup',
            builder: (context, state) => const AuthGate(child: PinSetupPage()),
          ),
          GoRoute(
            path: 'password',
            builder: (context, state) =>
                const AuthGate(child: ChangePasswordPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/me/notifications',
        builder: (context, state) =>
            const AuthGate(child: NotificationSettingsPage()),
      ),
      GoRoute(
        path: '/me/tags',
        builder: (context, state) => const AuthGate(child: TagPage()),
      ),
      GoRoute(
        path: '/me/sessions',
        builder: (context, state) => const AuthGate(child: SessionsPage()),
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
        // Public: the sign-up checkbox links here before anyone is signed in.
        builder: (context, state) => LegalPage(
          document: state.uri.queryParameters['doc'] == 'privacy'
              ? LegalDocument.privacy
              : LegalDocument.terms,
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
