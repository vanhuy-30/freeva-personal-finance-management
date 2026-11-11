import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/freeva_switch.dart';
import 'package:mobile/features/auto_suggest/domain/merchant_mapping.dart';
import 'package:mobile/features/auto_suggest/presentation/pages/auto_suggest_page.dart';
import 'package:mobile/features/auto_suggest/presentation/viewmodels/auto_suggest_view_model.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'auto_suggest_fakes.dart';

// Boards U.1 AutoSuggest / U.2 AutoSuggestClear (390×844). macOS only.
// Update: flutter test --update-goldens test/features/auto_suggest/auto_suggest_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester t,
    String name, {
    List<MerchantMapping>? mappings,
    bool dark = false,
    Future<void> Function()? then,
  }) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    getIt.registerSingleton<AutoSuggestViewModel>(
      StubAutoSuggestViewModel(mappings: mappings ?? boardMappings()),
    );
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const AutoSuggestPage(),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('U.1 list', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'u1_auto_suggest');
  });
  testWidgets('U.1 list dark', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'u1_auto_suggest_dark', dark: true);
  });
  testWidgets('U.1 nothing remembered', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'u1_auto_suggest_empty', mappings: const []);
  });
  testWidgets('U.2 clear confirm', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'u2_auto_suggest_clear',
      then: () async {
        await t.tap(find.text('Xoá dữ liệu đã học'));
        await t.pumpAndSettle();
      },
    );
  });

  testWidgets('see all expands, × forgets, Xoá clears', (t) async {
    t.view.physicalSize = const Size(390, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final model = StubAutoSuggestViewModel(mappings: boardMappings());
    getIt.registerSingleton<AutoSuggestViewModel>(model);
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: AppTheme.light,
        home: const AutoSuggestPage(),
      ),
    );
    await t.pump();
    expect(find.text('CỬA HÀNG ĐÃ NHỚ · 12'), findsOneWidget);
    expect(find.text('Cửa hàng 5'), findsNothing);
    await t.tap(find.text('Xem cả 12'));
    await t.pump();
    expect(find.text('Cửa hàng 11'), findsOneWidget);
    expect(find.text('Xem cả 12'), findsNothing);

    await t.tap(find.bySemanticsLabel('Quên Grab'));
    await t.pump();
    expect(find.text('Grab'), findsNothing);
    expect(find.text('CỬA HÀNG ĐÃ NHỚ · 11'), findsOneWidget);

    await t.tap(find.byType(FreevaSwitch));
    await t.pump();
    expect(model.enabled, isFalse);

    await t.tap(find.text('Xoá dữ liệu đã học'));
    await t.pumpAndSettle();
    expect(
      find.text('11 cửa hàng đã nhớ sẽ bị xoá. Giao dịch vẫn giữ nguyên.'),
      findsOneWidget,
    );
    await t.tap(find.text('Xoá'));
    await t.pumpAndSettle();
    expect(find.textContaining('CỬA HÀNG ĐÃ NHỚ'), findsNothing);
    expect(find.text('Xoá dữ liệu đã học'), findsNothing);
    expect(
      find.text('Chỉ tính trên sổ của bạn, không gửi ra ngoài.'),
      findsOneWidget,
    );
  });
}
