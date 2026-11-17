import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/router/top_location.dart';

void main() {
  testWidgets('MOB-P6-001: a pushed screen is the top location, so Tổng quan '
      'knows it was covered and reloads on return', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const Text('home')),
        GoRoute(path: '/record', builder: (_, _) => const Text('record')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(topLocation(router), '/home');
    router.push('/record?type=expense');
    await tester.pumpAndSettle();
    // The plain uri leaves pushed routes out; this is what broke the reload.
    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    expect(topLocation(router), '/record');
    router.pop();
    await tester.pumpAndSettle();
    expect(topLocation(router), '/home');
  });
}
