import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/server_config/data/server_config_repository_impl.dart';
import 'package:mobile/features/server_config/data/server_config_vault.dart';
import 'package:mobile/features/server_config/domain/server_config.dart';
import 'package:mobile/features/server_config/domain/server_config_repository.dart';
import 'package:mobile/features/server_config/presentation/viewmodels/server_config_view_model.dart';
import 'package:mobile/features/server_config/presentation/widgets/server_config_gate.dart';

import '../../core/widgets/widget_test_app.dart';

Map<String, dynamic> _body({int version = 3, bool insights = false}) => {
  'version': version,
  'flags': {'insights': insights, 'forecast': false},
  'config': {
    'forecast.monthOptions': [3, 6, 12],
    'report.topRows': 3,
    'onboarding.incomeSuggestionsVnd': ['10000000', '15000000'],
    'netWorth.defaultWindow': '6m',
    'onboarding.goalKinds': ['home', 'car'],
    'weird.mixed': [1, 'a'],
  },
};

void main() {
  group('MOB-P5-E08 ServerConfig', () {
    test('reads typed values and never guesses', () {
      final config = ServerConfig.fromJson(_body(insights: true));
      expect(config.version, 3);
      expect(config.flag('insights'), isTrue);
      expect(config.flag('unknown'), isFalse);
      expect(config.integers('forecast.monthOptions'), [3, 6, 12]);
      expect(config.integer('report.topRows'), 3);
      expect(config.moneyMinor('onboarding.incomeSuggestionsVnd'), [
        BigInt.from(10000000),
        BigInt.from(15000000),
      ]);
      expect(config.text('netWorth.defaultWindow'), '6m');
      expect(config.texts('onboarding.goalKinds'), ['home', 'car']);
      expect(config.integer('netWorth.defaultWindow'), isNull);
      expect(config.integers('missing.key'), isNull);
      expect(config.values.containsKey('weird.mixed'), isFalse);
    });

    test('round-trips through its JSON and rejects a bad shape', () {
      final config = ServerConfig.fromJson(_body());
      final again = ServerConfig.fromJson(
        jsonDecode(jsonEncode(config.toJson())) as Map<String, dynamic>,
      );
      expect(again.version, config.version);
      expect(again.integers('forecast.monthOptions'), [3, 6, 12]);
      expect(
        () => ServerConfig.fromJson({'version': '3'}),
        throwsFormatException,
      );
    });
  });

  group('MOB-P5-E08 repository', () {
    test('fetches app-config and maps a bad body to unavailable', () async {
      final api = _Api()..json = _body();
      final repo = ServerConfigRepositoryImpl(api, _Vault());
      final ok = await repo.fetch();
      expect(api.paths, ['app-config']);
      expect(ok.getOrElse(() => throw StateError('left')).version, 3);
      api.json = {'nope': true};
      final bad = await repo.fetch();
      expect(bad.fold((f) => f.code, (_) => null), AuthError.unavailable);
    });

    test('caches on the device and treats a broken copy as none', () async {
      final vault = _Vault();
      final repo = ServerConfigRepositoryImpl(_Api(), vault);
      expect(await repo.readCached(), isNull);
      await repo.writeCached(ServerConfig.fromJson(_body(version: 9)));
      expect((await repo.readCached())!.version, 9);
      vault.value = '{not json';
      expect(await repo.readCached(), isNull);
      await repo.clearCached();
      expect(vault.value, isNull);
    });
  });

  group('MOB-P5-E08 view model', () {
    late _Repo repo;
    late DateTime now;
    late ServerConfigViewModel vm;

    setUp(() {
      repo = _Repo();
      now = DateTime(2026, 11, 11, 9);
      vm = ServerConfigViewModel.withClock(repo, now: () => now);
    });

    test('everything is off and missing until a load fails', () async {
      expect(vm.isEnabled('insights'), isFalse);
      expect(vm.missing, isFalse);
      repo.next = left(const AuthFailure(AuthError.network));
      await vm.refresh();
      expect(vm.missing, isTrue);
      expect(vm.config, isNull);
    });

    test('uses the cached copy at boot, then the server copy', () async {
      repo.cached = ServerConfig.fromJson(_body(version: 2, insights: true));
      await vm.loadCached();
      expect(vm.isEnabled('insights'), isTrue);
      repo.next = right(ServerConfig.fromJson(_body(version: 3)));
      await vm.refresh();
      expect(vm.config!.version, 3);
      expect(vm.isEnabled('insights'), isFalse);
      expect(repo.written.map((c) => c.version), [3]);
    });

    test('keeps the cached copy when the network fails', () async {
      repo.cached = ServerConfig.fromJson(_body(version: 2));
      await vm.loadCached();
      repo.next = left(const AuthFailure(AuthError.network));
      await vm.refresh();
      expect(vm.config!.version, 2);
      expect(vm.missing, isFalse);
    });

    test('asks the server at most hourly unless forced', () async {
      repo.next = right(ServerConfig.fromJson(_body()));
      await vm.refresh();
      now = now.add(const Duration(minutes: 59));
      await vm.refresh();
      expect(repo.fetches, 1);
      await vm.refresh(force: true);
      expect(repo.fetches, 2);
      now = now.add(const Duration(hours: 1));
      await vm.refresh();
      expect(repo.fetches, 3);
    });

    test('rewrites the cache only when the version changes', () async {
      repo.next = right(ServerConfig.fromJson(_body(version: 4)));
      await vm.refresh(force: true);
      await vm.refresh(force: true);
      expect(repo.written.map((c) => c.version), [4]);
      repo.next = right(ServerConfig.fromJson(_body(version: 5)));
      await vm.refresh(force: true);
      expect(repo.written.map((c) => c.version), [4, 5]);
    });

    test(
      'sign-out forgets the copy and drops an answer still in flight',
      () async {
        final pending = Completer<Either<AuthFailure, ServerConfig>>();
        repo.pending = pending;
        final refresh = vm.refresh(force: true);
        await vm.clear();
        pending.complete(right(ServerConfig.fromJson(_body(insights: true))));
        await refresh;
        expect(vm.config, isNull);
        expect(vm.isEnabled('insights'), isFalse);
        expect(repo.cleared, 1);
        expect(repo.written, isEmpty);
      },
    );

    test('dev overlay turns flags on only in dev builds', () {
      final overlaid = ServerConfigViewModel.withClock(
        repo,
        devOverlay: {'forecast'},
      );
      expect(overlaid.isEnabled('forecast'), isTrue);
      expect(overlaid.isEnabled('insights'), isFalse);
      AppConfig config(String env) => AppConfig.fromValues(
        environment: env,
        apiBaseUrl: 'https://api.example.test',
      );
      expect(
        ServerConfigViewModel.devOverlayFor(
          config('dev'),
          ' forecast, insights ,',
        ),
        {'forecast', 'insights'},
      );
      expect(
        ServerConfigViewModel.devOverlayFor(config('staging'), 'forecast'),
        isEmpty,
      );
      expect(
        ServerConfigViewModel.devOverlayFor(config('prod'), 'forecast'),
        isEmpty,
      );
    });
  });

  group('MOB-P5-E08 gate', () {
    testWidgets('shows try again with no config and the block once loaded', (
      tester,
    ) async {
      final repo = _Repo()..next = left(const AuthFailure(AuthError.network));
      final vm = ServerConfigViewModel.withClock(repo);
      await vm.refresh();
      await tester.pumpWidget(
        testApp(
          ServerConfigGate(
            model: vm,
            builder: (context, config) =>
                Text('topRows ${config.integer('report.topRows')}'),
          ),
        ),
      );
      expect(find.text('Chưa tải được cài đặt'), findsOneWidget);
      expect(find.text('Kiểm tra mạng rồi thử lại.'), findsOneWidget);

      repo.next = right(ServerConfig.fromJson(_body()));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(repo.fetches, 2);
      expect(find.text('topRows 3'), findsOneWidget);
    });

    testWidgets('shows nothing while the first load runs', (tester) async {
      final vm = ServerConfigViewModel.withClock(_Repo());
      await tester.pumpWidget(
        testApp(
          ServerConfigGate(model: vm, builder: (_, _) => const Text('block')),
        ),
      );
      expect(find.text('block'), findsNothing);
      expect(find.text('Thử lại'), findsNothing);
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

class _Vault implements ServerConfigVault {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String next) async => value = next;

  @override
  Future<void> delete() async => value = null;
}

class _Repo implements ServerConfigRepository {
  Either<AuthFailure, ServerConfig> next = left(
    const AuthFailure(AuthError.network),
  );
  Completer<Either<AuthFailure, ServerConfig>>? pending;
  ServerConfig? cached;
  final written = <ServerConfig>[];
  int fetches = 0;
  int cleared = 0;

  @override
  Future<Either<AuthFailure, ServerConfig>> fetch() {
    fetches += 1;
    final waiting = pending;
    pending = null;
    return waiting?.future ?? Future.value(next);
  }

  @override
  Future<ServerConfig?> readCached() async => cached;

  @override
  Future<void> writeCached(ServerConfig config) async => written.add(config);

  @override
  Future<void> clearCached() async => cleared += 1;
}
