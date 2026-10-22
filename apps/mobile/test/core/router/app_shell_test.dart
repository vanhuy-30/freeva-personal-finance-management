import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/router/app_shell.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/freeva_bottom_nav.dart';

void main() {
  GoRouter router() => GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          for (final path in ['/home', '/transactions', '/reports', '/me'])
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: path,
                  builder: (context, state) =>
                      Scaffold(body: Center(child: Text('root $path'))),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: '/record',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('record'))),
      ),
      GoRoute(
        path: '/wallets',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('wallets'))),
      ),
    ],
  );

  Widget app(GoRouter r) => MaterialApp.router(
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    routerConfig: r,
  );

  testWidgets('bottom nav only on tab roots', (tester) async {
    final r = router();
    await tester.pumpWidget(app(r));
    await tester.pumpAndSettle();
    expect(find.byType(FreevaBottomNav), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('root /reports'), findsOneWidget);
    expect(find.byType(FreevaBottomNav), findsOneWidget);

    r.push('/wallets');
    await tester.pumpAndSettle();
    expect(find.text('wallets'), findsOneWidget);
    expect(find.byType(FreevaBottomNav), findsNothing);

    r.pop();
    await tester.pumpAndSettle();
    expect(find.byType(FreevaBottomNav), findsOneWidget);
  });

  testWidgets('+ opens the record screen without the nav', (tester) async {
    await tester.pumpWidget(app(router()));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ghi giao dịch'));
    await tester.pumpAndSettle();
    expect(find.text('record'), findsOneWidget);
    expect(find.byType(FreevaBottomNav), findsNothing);
  });
}
