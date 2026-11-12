import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/insights/presentation/pages/insights_page.dart';
import 'package:mobile/features/insights/presentation/viewmodels/insights_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../home/fixtures.dart';
import '../home/home_fakes.dart';
import '../home/home_test_app.dart';
import 'insights_fakes.dart';

/// Board S.1 InsHome: Thứ Hai 10/11, four wallets, October in review.
StubHomeViewModel boardHome() => StubHomeViewModel(
  data: overview(
    net: [worth('VND', 70530000)],
    wallets: [
      wallet('vcb', 'Vietcombank', balance: 54680000),
      wallet('cash', 'Tiền mặt', type: WalletType.cash, balance: 3700000),
      wallet('momo', 'MoMo', type: WalletType.ewallet, balance: 2150000),
      wallet('tcb', 'Techcombank', balance: 10000000),
    ],
    flow: month(
      expense: 5400000,
      rows: [
        spend('food', 2160000),
        spend('home', 1800000),
        spend('bus', 1440000),
      ],
      from: '2026-11-01',
      to: '2026-11-30',
    ),
    previous: month(expense: 11480000),
  ),
)..today = DateTime(2026, 11, 10, 9, 30);

// Boards S.1 InsHome (Overview card) and S.2 InsAnalysis (list only; the
// forecast card on top is MOB-P5-E06). macOS only.
// Update: flutter test --update-goldens test/features/insights/insights_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  for (final dark in [false, true]) {
    final name = dark ? 's1_ins_home_dark' : 's1_ins_home';
    testWidgets('S.1 $name', skip: !Platform.isMacOS, (t) async {
      t.view.physicalSize = const Size(390, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final app = await homeApp(boardHome(), dark: dark);
      getIt.registerSingleton<InsightsViewModel>(StubInsightsViewModel());
      await t.pumpWidget(app);
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }

  testWidgets('S.2 list', skip: !Platform.isMacOS, (t) async {
    t.view.physicalSize = const Size(390, 960);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    getIt.registerSingleton<InsightsViewModel>(StubInsightsViewModel());
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const InsightsPage(),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/s2_ins_analysis.png'),
    );
  });
}
