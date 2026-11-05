import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/forecast/data/forecast_repository_impl.dart';
import 'package:mobile/features/forecast/domain/balance_forecast.dart';
import 'package:mobile/features/forecast/domain/forecast_repository.dart';
import 'package:mobile/features/forecast/domain/forecast_use_cases.dart';
import 'package:mobile/features/forecast/presentation/viewmodels/forecast_view_model.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/core/di/injection.dart';

import '../home/fixtures.dart' show b;
import 'forecast_stub.dart';

const _json = {
  'timezone': 'Asia/Ho_Chi_Minh',
  'currencyCode': 'VND',
  'from': '2026-11-03',
  'to': '2027-01-31',
  'startingBalanceMinor': '48250000',
  'months': [
    {
      'month': '2026-11',
      'openingMinor': '48250000',
      'incomeMinor': '18500000',
      'expenseMinor': '-847000',
      'closingMinor': '65903000',
    },
  ],
  'assumptions': {
    'balanceSource': 'wallets',
    'includesCreditWallets': false,
    'includesOneOffSpending': false,
    'includedRuleIds': ['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'],
    'excludedRuleIds': ['bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'],
    'otherCurrencyRuleIds': <String>[],
  },
};

void main() {
  group('repository', () {
    test('reads money as strings and sends the inputs as a query', () async {
      final api = _Api()..json = _json;
      final result = await ForecastRepositoryImpl(api).forecast(
        months: 6,
        currencyCode: 'VND',
        startingBalanceMinor: BigInt.from(1000),
        excludeRuleIds: const ['b', 'a'],
      );
      final forecast = result.getOrElse(() => throw StateError('missing'));
      expect(forecast.startingBalanceMinor, BigInt.from(48250000));
      expect(forecast.months.single.expenseMinor, BigInt.from(-847000));
      expect(forecast.endingMinor, BigInt.from(65903000));
      expect(forecast.changeMinor, BigInt.from(17653000));
      expect(forecast.assumptions.fromWallets, isTrue);
      expect(forecast.assumptions.excludedRuleIds, hasLength(1));
      final uri = Uri.parse(api.paths.single);
      expect(uri.path, 'forecast');
      expect(uri.queryParameters, {
        'months': '6',
        'currencyCode': 'VND',
        'startingBalanceMinor': '1000',
        'excludeRuleIds': 'b,a',
      });
    });

    test('leaves out inputs that were not set', () async {
      final api = _Api()..json = _json;
      await ForecastRepositoryImpl(api).forecast(months: 3);
      expect(Uri.parse(api.paths.single).queryParameters, {'months': '3'});
    });

    test('maps a JSON number or a bad shape to unavailable', () async {
      final api = _Api()..json = {..._json, 'startingBalanceMinor': 48250000};
      final result = await ForecastRepositoryImpl(api).forecast(months: 3);
      expect(result.fold((e) => e.code, (_) => null), AuthError.unavailable);
    });
  });

  group('use case', () {
    test('rejects months outside 1–12 and bad currency codes', () async {
      final repo = _Repo();
      final cases = DefaultForecastUseCases(repo);
      for (final months in [0, 13, -1]) {
        final r = await cases.load(months: months);
        expect(r.fold((e) => e.code, (_) => null), AuthError.invalidInput);
      }
      final bad = await cases.load(months: 3, currencyCode: 'vnd');
      expect(bad.fold((e) => e.code, (_) => null), AuthError.invalidInput);
      expect(repo.calls, isEmpty);
    });

    test('passes sorted rule ids to the repository', () async {
      final repo = _Repo();
      await DefaultForecastUseCases(repo)
          .load(months: 12, excludeRuleIds: {'b', 'a'});
      expect(repo.calls.single.months, 12);
      expect(repo.calls.single.excluded, ['a', 'b']);
    });
  });

  group('view model', () {
    late FakeForecastUseCases cases;
    late ForecastViewModel model;

    setUp(() async {
      final h = await forecastApp(const SizedBox());
      cases = h.cases;
      model = ForecastViewModel(
        cases,
        h.recurring,
        getIt<AuthViewModel>(),
        getIt<ProfileViewModel>(),
        getIt(),
      );
    });
    tearDown(() {
      model.dispose();
      getIt.reset();
    });

    test('loads three months and the rules the forecast names', () async {
      await model.load();
      expect(model.months, 3);
      expect(model.data!.months, hasLength(3));
      expect(model.data!.endingMinor, b(89200000));
      expect(model.data!.changeMinor, b(40950000));
      expect(model.walletCount, 4);
      expect(model.digits, 0);
      expect(model.rows.map((r) => r.name), [
        'Lương',
        'Tiền nhà',
        'Tiền điện',
        'Học phí',
      ]);
    });

    test('changing the range reloads', () async {
      await model.load();
      await model.selectMonths(12);
      expect(model.months, 12);
      expect(model.data!.months, hasLength(12));
      expect(cases.calls.last.months, 12);
    });

    test('switching a rule off sends it as excluded and back on', () async {
      await model.load();
      final school = model.rows.last;
      await model.toggle(school, counts: false);
      expect(cases.calls.last.excluded, {'school'});
      expect(model.counted(school), isFalse);
      expect(model.data!.assumptions.excludedRuleIds, ['school']);
      await model.toggle(school, counts: true);
      expect(cases.calls.last.excluded, isEmpty);
      expect(model.counted(school), isTrue);
    });

    test('a start balance overrides the wallets and can be reset', () async {
      await model.load();
      await model.setStarting(b(10000000));
      expect(cases.calls.last.start, b(10000000));
      expect(model.data!.startingBalanceMinor, b(10000000));
      expect(model.data!.assumptions.fromWallets, isFalse);
      await model.setStarting(null);
      expect(cases.calls.last.start, isNull);
      expect(model.data!.assumptions.fromWallets, isTrue);
    });

    test('a failed reload keeps the last forecast and the old input', () async {
      await model.load();
      cases.failure = const AuthFailure(AuthError.network);
      await model.selectMonths(6);
      expect(model.months, 3);
      expect(model.data!.months, hasLength(3));
      expect(model.failure!.code, AuthError.network);
      cases.failure = null;
      await model.reload();
      expect(model.failure, isNull);
    });

    test('the first load failing leaves no data and an error', () async {
      cases.failure = const AuthFailure(AuthError.unavailable);
      await model.load();
      expect(model.data, isNull);
      expect(model.failure!.code, AuthError.unavailable);
    });
  });
}

class _Api implements AuthorizedApi {
  Map<String, dynamic> json = {};
  final paths = <String>[];

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    paths.add(path);
    return right(json);
  }
}

class _Repo implements ForecastRepository {
  final calls = <({int months, List<String> excluded})>[];

  @override
  Future<Either<AuthFailure, BalanceForecast>> forecast({
    required int months,
    String? currencyCode,
    BigInt? startingBalanceMinor,
    List<String> excludeRuleIds = const [],
  }) async {
    calls.add((months: months, excluded: excludeRuleIds));
    return left(const AuthFailure(AuthError.unavailable));
  }
}
