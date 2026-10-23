import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/wallets/data/wallet_repository_impl.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';
import 'package:mobile/core/money/money_text.dart';

import '../auth/fakes.dart';

Map<String, dynamic> row(String id, {int order = 0, int version = 1}) => {
  'id': id,
  'createdAt': '2026-09-25T00:00:00Z',
  'name': id,
  'type': 'cash',
  'currencyCode': 'VND',
  'initialBalanceMinor': '9223372036854775807',
  'balanceMinor': '18446744073709551614',
  'creditLimitMinor': null,
  'statementCloseDay': null,
  'paymentDueDay': null,
  'sortOrder': order,
  'version': version,
  'archivedAt': null,
};

class WalletTransport implements AuthorizedApi {
  final calls = <({String method, String path, Map<String, dynamic>? body})>[];
  final rows = [row('a'), row('b'), row('c')];
  AuthFailure? failure;
  int? failWrite;
  int writes = 0;
  Completer<void>? pending;
  bool paginate = false;
  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method: method, path: path, body: body));
    if (pending != null) await pending!.future;
    if (failure != null) return left(failure!);
    if (path == 'profile/options') {
      return right({
        'currencies': [
          {'code': 'VND', 'minorDigits': 0},
          {'code': 'USD', 'minorDigits': 2},
        ],
      });
    }
    if (method == 'GET') {
      final page = int.parse(Uri.parse(path).queryParameters['page']!);
      return right({
        'items': paginate
            ? [rows[page - 1]]
            : rows.map((r) => Map<String, dynamic>.from(r)).toList(),
        'total': rows.length,
      });
    }
    writes++;
    if (writes == failWrite) return left(const AuthFailure(AuthError.network));
    if (method == 'POST') return right({...row('new'), ...body!});
    if (method == 'PUT' && path == 'financial-accounts/order') {
      final items = (body!['items'] as List).cast<Map<String, dynamic>>();
      final byId = {for (final r in rows) r['id']: r};
      if (items.any((i) => byId[i['id']]?['version'] != i['version'])) {
        return left(const AuthFailure(AuthError.conflict));
      }
      for (final (index, item) in items.indexed) {
        final r = byId[item['id']]!;
        if (r['sortOrder'] == index) continue;
        r['sortOrder'] = index;
        r['version'] = (r['version'] as int) + 1;
      }
      return right({
        'items': [
          for (final item in items)
            Map<String, dynamic>.from(byId[item['id']]!),
        ],
      });
    }
    final r = rows.firstWhere((r) => path.endsWith('/${r['id']}'));
    if (r['version'] != body!['version']) {
      return left(const AuthFailure(AuthError.conflict));
    }
    r.addAll(body);
    r['version'] = (r['version'] as int) + 1;
    if (body.containsKey('archived')) {
      r['archivedAt'] = body['archived'] == true
          ? '2026-09-25T00:00:00Z'
          : null;
    }
    return right(Map<String, dynamic>.from(r));
  }
}

BigInt? _parse(String text, WalletCurrency c, String locale) =>
    parseMoneyText(text, c.minorDigits, locale);
String _format(BigInt minor, WalletCurrency c, String locale) =>
    formatMoneyText(minor, c.minorDigits, locale);

void main() {
  test('money conversion is exact for int64, large derived balances and locale fractions', () {
    const vnd = WalletCurrency('VND', 0), usd = WalletCurrency('USD', 2);
    expect(
      _parse('9223372036854775807', vnd, 'vi'),
      BigInt.parse('9223372036854775807'),
    );
    expect(_parse('-0,01', usd, 'vi'), BigInt.from(-1));
    expect(_parse('10.50', usd, 'en'), BigInt.from(1050));
    for (final text in ['1.5', '1,000', '1e3', 'NaN', '']) {
      expect(_parse(text, vnd, 'en'), isNull);
    }
    expect(_parse('1.001', usd, 'en'), isNull);
    expect(
      _format(BigInt.parse('18446744073709551614'), vnd, 'vi'),
      '18.446.744.073.709.551.614',
    );
    expect(_format(BigInt.from(-1), usd, 'en'), '-0.01');
  });
  test(
    'repository reads all pages and preserves string money and versions',
    () async {
      final api = WalletTransport()..paginate = true;
      final repo = WalletRepositoryImpl(api);
      final rows = (await repo.load()).getOrElse(() => []);
      expect(rows.length, 3);
      expect(rows.first.balance, BigInt.parse('18446744073709551614'));
      await repo.save(rows.first.draft, wallet: rows.first, clientId: 'unused');
      expect(
        api.calls.last.body!['initialBalanceMinor'],
        '9223372036854775807',
      );
      expect(api.calls.last.body!['version'], 1);
      expect(api.calls.last.body!.containsKey('clientId'), false);
      api.rows[0]['balanceMinor'] = 1.5;
      expect((await repo.load()).isLeft(), true);
    },
  );
  test('use case rejects overflow, invalid days, currency and card fields before writing', () async {
    final api = WalletTransport();
    final cases = DefaultWalletUseCases(WalletRepositoryImpl(api));
    final currencies = [const WalletCurrency('VND', 0)];
    for (final draft in [
      WalletDraft(
        name: 'x',
        type: WalletType.cash,
        currency: 'VND',
        initialBalance: BigInt.parse('9223372036854775808'),
      ),
      WalletDraft(
        name: 'x',
        type: WalletType.cash,
        currency: 'VND',
        initialBalance: BigInt.zero,
        closeDay: 1,
      ),
      WalletDraft(
        name: 'x',
        type: WalletType.credit,
        currency: 'VND',
        initialBalance: BigInt.zero,
        closeDay: 29,
      ),
      WalletDraft(
        name: 'x',
        type: WalletType.credit,
        currency: 'VND',
        initialBalance: BigInt.zero,
        creditLimit: BigInt.from(-1),
      ),
      WalletDraft(
        name: ' ',
        type: WalletType.cash,
        currency: 'VND',
        initialBalance: BigInt.zero,
      ),
      WalletDraft(
        name: 'x',
        type: WalletType.cash,
        currency: 'XXX',
        initialBalance: BigInt.zero,
      ),
    ]) {
      expect(
        (await cases.save(draft, currencies, clientId: 'id')).isLeft(),
        true,
      );
    }
    expect(api.writes, 0);
    expect(
      (await cases.save(
        WalletDraft(
          name: 'x',
          type: WalletType.credit,
          currency: 'VND',
          initialBalance: BigInt.parse('-9223372036854775808'),
          closeDay: 1,
          dueDay: 28,
        ),
        currencies,
        clientId: 'id',
      )).isRight(),
      true,
    );
  });
  group('view model', () {
    late WalletTransport api;
    late DefaultAuthViewModel auth;
    late DefaultWalletViewModel model;
    setUp(() async {
      api = WalletTransport();
      auth = DefaultAuthViewModel(
        DefaultAuthUseCases(
          AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
        ),
      )
        ..stage = AuthStage.unlocked
        ..hasPin = true;
      model = DefaultWalletViewModel(
        DefaultWalletUseCases(WalletRepositoryImpl(api)),
        auth,
      );
      await model.load();
    });
    tearDown(() {
      model.dispose();
      auth.dispose();
    });
    test('reorder saves the whole order in one request; archive/restore use latest versions', () async {
      final w = model.wallets;
      expect(await model.reorder([w[0], w[2], w[1]]), isTrue);
      expect(model.wallets.map((w) => w.id), ['a', 'c', 'b']);
      expect(api.rows.map((r) => r['sortOrder']), [0, 2, 1]);
      expect(api.writes, 1);
      expect(api.calls.last.body, {
        'items': [
          {'id': 'a', 'version': 1},
          {'id': 'c', 'version': 1},
          {'id': 'b', 'version': 1},
        ],
      });
      expect(await model.reorder(model.active), isTrue);
      expect(api.writes, 1);
      await model.archive(model.wallets[1]);
      final hidden = model.wallets.firstWhere((w) => w.id == 'c');
      expect(hidden.archived, true);
      await model.archive(hidden);
      expect(model.wallets.firstWhere((w) => w.id == 'c').archived, false);
      expect(model.failure, isNull);
    });
    test(
      'stale reorder needs a reload; a network failure keeps the old order',
      () async {
        final w = model.wallets;
        api.failWrite = 1;
        expect(await model.reorder([w[2], w[0], w[1]]), isFalse);
        expect(model.needsReload, false);
        expect(model.wallets.map((w) => w.id), ['a', 'b', 'c']);
        api.rows[0]['version'] = 5;
        expect(await model.reorder([w[2], w[0], w[1]]), isFalse);
        expect(model.needsReload, true);
        await model.archive(model.wallets.first);
        expect(api.writes, 2);
        await model.load();
        expect(model.needsReload, false);
        expect(model.wallets.first.version, 5);
      },
    );
    test(
      'lock clears financial data and discards late response; reorder stops',
      () async {
        api.pending = Completer<void>();
        final w = model.wallets;
        final work = model.reorder([w[0], w[2], w[1]]);
        auth.lock();
        expect(model.wallets, isEmpty);
        expect(model.currencies, isEmpty);
        api.pending!.complete();
        await work;
        expect(model.wallets, isEmpty);
        expect(api.writes, 1);
        expect(model.busy, false);
      },
    );
    test(
      'creation retries keep clientId and conflict requires reload',
      () async {
        final id = model.newClientId();
        expect(
          id,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        final draft = model.wallets.first.draft;
        api.failure = const AuthFailure(AuthError.network);
        expect(await model.save(draft, id), false);
        api.failure = null;
        expect(await model.save(draft, id), true);
        final creates = api.calls.where((c) => c.method == 'POST');
        expect(creates.map((c) => c.body!['clientId']), [id, id]);
        api.failure = const AuthFailure(AuthError.conflict);
        await model.save(draft, id, wallet: model.wallets.first);
        expect(model.needsReload, true);
      },
    );
    test('expired session clears wallets', () async {
      api.failure = const AuthFailure(AuthError.expired);
      await model.load();
      expect(model.wallets, isEmpty);
      expect(auth.stage, AuthStage.signedOut);
    });
  });
}
