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
import 'package:mobile/features/reports/presentation/viewmodels/overview_view_model.dart';
import 'package:mobile/features/reports/presentation/viewmodels/report_view_model.dart';
import 'package:mobile/features/reports/presentation/widgets/overview_section.dart';
import 'package:mobile/features/wallets/data/wallet_repository_impl.dart';
import 'package:mobile/features/wallets/domain/wallet_repository.dart';

import '../auth/fakes.dart';
import '../transactions/transaction_view_model_test.dart'
    show RecordingAnalytics;

void main() {
  late ReportTransport api;
  late DefaultAuthViewModel auth;
  late DefaultReportViewModel reports;
  late DefaultOverviewViewModel overview;

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
    reports = DefaultReportViewModel(cases, auth, RecordingAnalytics());
    overview = DefaultOverviewViewModel(cases, auth);
    getIt.registerSingleton<ReportViewModel>(reports);
    getIt.registerSingleton<OverviewViewModel>(overview);
    getIt.registerSingleton<AuthViewModel>(auth);
    getIt.registerSingleton<WalletRepository>(wallets);
    getIt.registerSingleton<AnalyticsService>(RecordingAnalytics());
  });

  tearDown(() async {
    reports.dispose();
    overview.dispose();
    auth.dispose();
    await getIt.reset();
  });

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

  testWidgets('keeps currencies separate and labels uncategorized income', (
    tester,
  ) async {
    await tester.pumpWidget(app(const ReportPage()));
    await tester.pumpAndSettle();
    expect(find.text('Chưa phân loại'), findsOneWidget);
    expect(find.text('Ăn uống'), findsWidgets);
    expect(find.text('Cà phê'), findsNWidgets(2));
    final vnd = formatMoneyText(BigInt.from(1000000), 0, 'vi');
    final usd = formatMoneyText(BigInt.from(1050), 2, 'vi');
    expect(find.textContaining(vnd), findsWidgets);
    expect(find.textContaining(usd), findsWidgets);
    expect(find.textContaining('1001050'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overview shows each currency on its own card', (tester) async {
    await tester.pumpWidget(app(const OverviewSection()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('overview-VND')), findsOneWidget);
    expect(find.byKey(const ValueKey('overview-USD')), findsOneWidget);
    expect(
      find.textContaining(formatMoneyText(BigInt.from(1500000), 0, 'vi')),
      findsWidgets,
    );
    expect(
      find.textContaining(formatMoneyText(BigInt.from(2000), 2, 'vi')),
      findsWidgets,
    );
    expect(find.textContaining('1502000'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report page fits a narrow large-text screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const ReportPage(), scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    },
    {
      'categoryId': 'coffee',
      'parentId': 'food',
      'currency': 'VND',
      'incomeMinor': '0',
      'expenseMinor': '-250000',
    },
    {
      'categoryId': 'coffee',
      'parentId': 'food',
      'currency': 'USD',
      'incomeMinor': '1050',
      'expenseMinor': '-25',
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
