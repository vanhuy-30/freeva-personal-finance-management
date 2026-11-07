import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/net_worth/data/net_worth_repository_impl.dart';
import 'package:mobile/features/net_worth/domain/net_worth_history.dart';
import 'package:mobile/features/net_worth/domain/net_worth_use_cases.dart';
import 'package:mobile/features/net_worth/presentation/pages/net_worth_page.dart';
import 'package:mobile/features/net_worth/presentation/widgets/net_worth_chart.dart';
import 'package:mobile/features/net_worth/presentation/viewmodels/net_worth_view_model.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';

import '../home/fixtures.dart' show b;
import 'net_worth_stub.dart';

class _Api implements AuthorizedApi {
  final json = <String, Map<String, dynamic>>{};
  final paths = <String>[];
  bool fail = false;

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    paths.add(path);
    if (fail && path.contains('investments')) {
      return left(const AuthFailure(AuthError.unavailable));
    }
    return right(json[Uri.parse(path).path]!);
  }
}

Map<String, dynamic> _point(String asOf, List<Map<String, Object>> items) => {
  'from': asOf,
  'to': asOf,
  'asOf': asOf,
  'items': items,
};

void main() {
  group('repository', () {
    test('parses both histories and sends the window', () async {
      final api = _Api()
        ..json['reports/net-worth/history'] = {
          'window': '6m',
          'points': [
            _point('2026-10-31', [
              {
                'currency': 'VND',
                'assetsMinor': '100',
                'liabilitiesMinor': '-10',
                'netWorthMinor': '90',
              },
            ]),
            _point('2026-11-06', const []),
          ],
        }
        ..json['reports/investments/history'] = {
          'window': '6m',
          'points': [
            _point('2026-10-31', [
              {'currency': 'VND', 'valueMinor': '40'},
            ]),
          ],
        };
      final repo = NetWorthRepositoryImpl(api);
      final h = (await repo.history(NetWorthWindow.half)).getOrElse(() => []);
      expect(h, hasLength(2));
      expect(h.first.items.single.netWorthMinor, b(90));
      expect(h.last.items, isEmpty);
      final i = (await repo.investmentHistory(NetWorthWindow.half))
          .getOrElse(() => []);
      expect(i.single.valueByCurrency['VND'], b(40));
      expect(api.paths.first, 'reports/net-worth/history?window=6m');
    });

    test('rejects a JSON number for money', () async {
      final api = _Api()
        ..json['reports/net-worth/history'] = {
          'points': [
            _point('2026-10-31', [
              {
                'currency': 'VND',
                'assetsMinor': 100,
                'liabilitiesMinor': '0',
                'netWorthMinor': '100',
              },
            ]),
          ],
        };
      final r = await NetWorthRepositoryImpl(api).history(NetWorthWindow.week);
      expect(r.isLeft(), isTrue);
    });
  });

  group('use case', () {
    test('picks the currency row, zero when absent, with the split', () async {
      final api = _Api()
        ..json['reports/net-worth/history'] = {
          'points': [
            _point('2026-10-31', const []),
            _point('2026-11-06', [
              {
                'currency': 'VND',
                'assetsMinor': '100',
                'liabilitiesMinor': '-10',
                'netWorthMinor': '90',
              },
              {
                'currency': 'USD',
                'assetsMinor': '1',
                'liabilitiesMinor': '0',
                'netWorthMinor': '1',
              },
            ]),
          ],
        }
        ..json['reports/investments/history'] = {
          'points': [
            _point('2026-11-06', [
              {'currency': 'VND', 'valueMinor': '40'},
            ]),
          ],
        };
      final s = (await DefaultNetWorthUseCases(
        NetWorthRepositoryImpl(api),
      ).load(NetWorthWindow.half, currency: 'VND')).toOption().toNullable()!;
      expect(s.points.first.netWorthMinor, BigInt.zero);
      expect(s.latest!.netWorthMinor, b(90));
      expect(s.latest!.walletMinor, b(60));
      expect(s.changeMinor, b(90));
      expect(s.hasChart, isTrue);
    });

    test('drops the split when the investment call fails', () async {
      final api = _Api()
        ..fail = true
        ..json['reports/net-worth/history'] = {
          'points': [_point('2026-11-06', const [])],
        };
      final s = (await DefaultNetWorthUseCases(
        NetWorthRepositoryImpl(api),
      ).load(NetWorthWindow.all, currency: 'VND')).toOption().toNullable()!;
      expect(s.latest!.investmentMinor, isNull);
      expect(s.latest!.walletMinor, isNull);
      expect(s.hasChart, isFalse);
      expect(s.changeMinor, isNull);
    });

    test('rejects a malformed currency', () async {
      final r = await DefaultNetWorthUseCases(NetWorthRepositoryImpl(_Api()))
          .load(NetWorthWindow.week, currency: 'vnd');
      expect(r.isLeft(), isTrue);
    });
  });

  group('view model', () {
    late FakeNetWorthUseCases cases;
    late NetWorthViewModel model;

    setUp(() async {
      final h = await netWorthApp(const SizedBox());
      cases = h.cases;
      model = NetWorthViewModel(
        cases,
        getIt<AuthViewModel>(),
        getIt<ProfileViewModel>(),
        getIt(),
      );
    });
    tearDown(() {
      model.dispose();
      getIt.reset();
    });

    test('loads six months and shows the latest', () async {
      await model.load();
      expect(model.window, NetWorthWindow.half);
      expect(model.shown!.netWorthMinor, b(929700000));
      expect(model.data!.changeMinor, b(57300000));
      expect(model.digits, 0);
    });

    test('touching a point shows it; a new window clears it', () async {
      await model.load();
      model.select(1);
      expect(model.shown!.netWorthMinor, b(880000000));
      await model.selectWindow(NetWorthWindow.year);
      expect(model.selected, isNull);
      expect(cases.windows.last, NetWorthWindow.year);
    });

    test('a failed window change keeps the old one and data', () async {
      await model.load();
      cases.failure = const AuthFailure(AuthError.unavailable);
      await model.selectWindow(NetWorthWindow.week);
      expect(model.window, NetWorthWindow.half);
      expect(model.data, isNotNull);
      expect(model.failure, isNotNull);
    });
  });

  group('page', () {
    testWidgets(
      'shows today, chips and the split; hides chart under 2 points',
      (tester) async {
        final h = await netWorthApp(const NetWorthPage());
        await tester.pumpWidget(h.app);
        h.router.push('/page');
        await tester.pumpAndSettle();
        expect(find.text('Hôm nay · 06/11'), findsOneWidget);
        expect(find.text('7 ngày'), findsOneWidget);
        expect(find.text('Tất cả'), findsOneWidget);
        expect(find.text('Tài sản'), findsOneWidget);
        expect(find.text('Nợ'), findsOneWidget);
        expect(find.text('TRONG TÀI SẢN'), findsOneWidget);
        expect(find.text('Đầu tư'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Tài sản ròng 6 tháng')),
          findsOneWidget,
        );

        h.cases.build = (w) {
          final s = sixMonths(w);
          return NetWorthSeries(
            window: w,
            currency: 'VND',
            points: [s.points.last],
          );
        };
        await tester.tap(find.text('7 ngày'));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(RegExp('Tài sản ròng 7 ngày')),
          findsNothing,
        );
      },
    );

    testWidgets('touching the chart shows that point', (tester) async {
      final h = await netWorthApp(const NetWorthPage());
      await tester.pumpWidget(h.app);
      h.router.push('/page');
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(NetWorthChart));
      await tester.tapAt(Offset(box.left + 12, box.top + 40));
      await tester.pumpAndSettle();
      expect(find.text('30/06/2026'), findsOneWidget);
    });
  });
}
