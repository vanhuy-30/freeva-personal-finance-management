import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/analytics/analytics_service.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/money/money_text.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/data/category_repository_impl.dart';
import 'package:mobile/features/reports/data/report_repository_impl.dart';
import 'package:mobile/features/reports/domain/report_use_cases.dart';
import 'package:mobile/features/reports/presentation/pages/report_page.dart';
import 'package:mobile/features/reports/presentation/viewmodels/report_view_model.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';
import 'package:mobile/features/wallets/data/wallet_repository_impl.dart';
import 'package:mobile/features/wallets/domain/wallet_repository.dart';

import '../auth/fakes.dart';
import '../home/home_fakes.dart' show FakeProfileViewModel;
import '../settings/fakes.dart' show MemoryPreferences;
import '../transactions/transaction_view_model_test.dart'
    show RecordingAnalytics;

void main() {
  late ReportTransport api;
  late DefaultAuthViewModel auth;
  late DefaultReportViewModel reports;

  setUp(() async {
    await getIt.reset();
    api = ReportTransport();
    auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
            ),
          )
          ..stage = AuthStage.unlocked
          ..ready = true;
    final wallets = WalletRepositoryImpl(api);
    final cases = DefaultReportUseCases(
      ReportRepositoryImpl(api),
      wallets,
      CategoryRepositoryImpl(api),
    );
    reports = DefaultReportViewModel(
      cases,
      auth,
      RecordingAnalytics(),
      FakeProfileViewModel(),
      clock: () => DateTime(2026, 10, 23),
    );
    getIt.registerSingleton<ReportViewModel>(reports);
    getIt.registerSingleton<AuthViewModel>(auth);
    getIt.registerSingleton<WalletRepository>(wallets);
    getIt.registerSingleton<AnalyticsService>(RecordingAnalytics());
  });

  tearDown(() async {
    reports.dispose();
    auth.dispose();
    await getIt.reset();
  });

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app(Widget child, {double scale = 1}) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: child,
    ),
  );

  testWidgets('shows one currency at a time and rolls children into parents', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(app(const ReportPage()));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 10, 2026'), findsOneWidget);
    expect(find.text('01/10 – 31/10'), findsOneWidget);
    expect(find.text('Ăn uống'), findsWidgets);
    expect(find.text('Cà phê'), findsNothing);
    expect(find.textContaining('1.000.000'), findsWidgets);
    expect(find.textContaining('1.050'), findsNothing);
    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('10,50'), findsWidgets);
    expect(find.textContaining('1.000.000'), findsNothing);
    expect(find.textContaining('1001050'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('income tab lists uncategorized income under Khác', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(app(const ReportPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thu').last);
    await tester.pumpAndSettle();
    expect(find.text('Khác · 1 danh mục'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('wallet tab shows what moved through each wallet', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(app(const ReportPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ví'));
    await tester.pumpAndSettle();
    expect(find.text('Tiền mặt'), findsOneWidget);
    expect(find.text('Vào\u00A0+1.000.000 · Ra\u00A0−250.000'), findsOneWidget);
    expect(find.text('Ngoại tệ'), findsNothing);
  });

  testWidgets('trend card and budget stand-in appear on a month', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(app(const ReportPage()));
    await tester.pumpAndSettle();
    expect(find.text('Xu hướng chi'), findsOneWidget);
    expect(find.text('Trung bình 2 tháng: 175.000'), findsOneWidget);
    expect(find.text('T10'), findsOneWidget);
    await tester.tap(find.text('Đặt ngân sách tháng'));
    await tester.pump();
    expect(find.text('Ngân sách sắp có'), findsOneWidget);
  });

  testWidgets('next is disabled on the current month; previous steps back', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(app(const ReportPage()));
    await tester.pumpAndSettle();
    final next = find.bySemanticsLabel('Kỳ sau');
    expect(tester.getSemantics(next).flagsCollection.isEnabled.name, 'isFalse');
    await tester.tap(find.byTooltip('Kỳ trước'));
    await tester.pumpAndSettle();
    expect(
      api.paths.where((p) => p.startsWith('reports/cashflow')).last,
      contains('on=2026-09-30'),
    );
  });

  testWidgets('hiding balances keeps report income and expense visible', (
    tester,
  ) async {
    tall(tester);
    final settings = DefaultSettingsViewModel(
      DefaultSettingsUseCases(SettingsRepositoryImpl(MemoryPreferences())),
      DefaultAuthUseCases(
        AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
      ),
      RecordingAnalytics(),
    );
    await settings.load();
    await settings.setBalancesHidden(true);
    getIt.registerSingleton<SettingsViewModel>(settings);
    addTearDown(settings.dispose);
    await tester.pumpWidget(app(const ReportPage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('••••'), findsNothing);
    expect(
      find.textContaining(formatMoneyText(BigInt.from(1000000), 0, 'vi')),
      findsWidgets,
    );
  });

  testWidgets('report page fits a narrow large-text screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final scale in [1.3, 2.0]) {
      await tester.pumpWidget(app(const ReportPage(), scale: scale));
      await tester.pumpAndSettle();
      expect(find.text('Báo cáo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

class ReportTransport implements AuthorizedApi {
  final paths = <String>[];

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    paths.add(path);
    if (path == 'reports/net-worth') {
      return right({
        'items': [
          {
            'currency': 'VND',
            'assetsMinor': '1500000',
            'liabilitiesMinor': '0',
            'netWorthMinor': '1500000',
          },
          {
            'currency': 'USD',
            'assetsMinor': '2000',
            'liabilitiesMinor': '-500',
            'netWorthMinor': '1500',
          },
        ],
      });
    }
    if (path.startsWith('reports/trend')) return right(_trend);
    if (path.startsWith('reports/cashflow')) return right(_cashflow);
    if (path.startsWith('financial-accounts')) {
      return right({
        'items': [
          _wallet('cash', 'Tiền mặt', 'VND'),
          _wallet('usd', 'Ngoại tệ', 'USD'),
        ],
        'total': 2,
      });
    }
    if (path == 'profile/options') {
      return right({
        'currencies': [
          {'code': 'VND', 'minorDigits': 0},
          {'code': 'USD', 'minorDigits': 2},
        ],
        'timezones': ['Asia/Ho_Chi_Minh'],
      });
    }
    if (path == 'categories/defaults') return right({});
    if (path == 'categories/options') {
      return right({
        'colorTokens': ['color.brand.primary'],
        'iconTokens': ['food'],
      });
    }
    if (path.startsWith('categories?')) {
      return right({
        'items': [
          _category('food', 'Ăn uống'),
          _category('coffee', 'Cà phê', parentId: 'food'),
        ],
        'total': 2,
      });
    }
    return left(const AuthFailure(AuthError.unavailable));
  }
}

Map<String, dynamic> _wallet(String id, String name, String currency) => {
  'id': id,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'name': name,
  'type': 'cash',
  'currencyCode': currency,
  'initialBalanceMinor': '0',
  'creditLimitMinor': null,
  'statementCloseDay': null,
  'paymentDueDay': null,
  'balanceMinor': '0',
  'version': 1,
  'sortOrder': 0,
  'archivedAt': null,
};

Map<String, dynamic> _category(String id, String name, {String? parentId}) => {
  'id': id,
  'name': name,
  'parentId': parentId,
  'clientId': '11111111-1111-4111-8111-111111111111',
  'colorToken': null,
  'iconToken': null,
  'isSystem': false,
  'archivedAt': null,
  'version': 1,
  'createdAt': '2026-01-01T00:00:00.000Z',
};

final Map<String, dynamic> _cashflow = {
  'period': {
    'kind': 'month',
    'from': '2026-10-01',
    'to': '2026-10-31',
    'timezone': 'Asia/Ho_Chi_Minh',
    'fiscalMonthStartDay': 1,
  },
  'totals': [
    {
      'currency': 'VND',
      'incomeMinor': '1000000',
      'expenseMinor': '-250000',
      'netMinor': '750000',
    },
    {
      'currency': 'USD',
      'incomeMinor': '1050',
      'expenseMinor': '-25',
      'netMinor': '1025',
    },
  ],
  'byCategory': [
    {
      'categoryId': null,
      'parentId': null,
      'currency': 'VND',
      'incomeMinor': '1000000',
      'expenseMinor': '0',
      'transactionCount': 1,
    },
    {
      'categoryId': 'coffee',
      'parentId': 'food',
      'currency': 'VND',
      'incomeMinor': '0',
      'expenseMinor': '-250000',
      'transactionCount': 4,
    },
    {
      'categoryId': 'coffee',
      'parentId': 'food',
      'currency': 'USD',
      'incomeMinor': '1050',
      'expenseMinor': '-25',
      'transactionCount': 2,
    },
  ],
  'byAccount': [
    {
      'accountId': 'cash',
      'currency': 'VND',
      'incomeMinor': '1000000',
      'expenseMinor': '-250000',
      'transferMinor': '0',
      'netMinor': '750000',
    },
    {
      'accountId': 'usd',
      'currency': 'USD',
      'incomeMinor': '1050',
      'expenseMinor': '-25',
      'transferMinor': '100',
      'netMinor': '1125',
    },
  ],
};

final Map<String, dynamic> _trend = {
  'kind': 'month',
  'buckets': [
    {
      'from': '2026-09-01',
      'to': '2026-09-30',
      'totals': [
        {'currency': 'VND', 'incomeMinor': '0', 'expenseMinor': '-100000'},
      ],
    },
    {
      'from': '2026-10-01',
      'to': '2026-10-31',
      'totals': [
        {
          'currency': 'VND',
          'incomeMinor': '1000000',
          'expenseMinor': '-250000',
        },
      ],
    },
  ],
};
