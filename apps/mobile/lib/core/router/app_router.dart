import '../../features/wallets/presentation/pages/wallet_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/widgets/auth_gate.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/wallets',
      builder: (context, state) => const AuthGate(child: WalletPage()),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const AuthGate(child: ProfilePage()),
    ),
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) =>
          const SplashPage(),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          NoTransitionPage(
            key: state.pageKey,
            child: const AuthGate(child: HomePage()),
          ),
    ),
  ],
);
