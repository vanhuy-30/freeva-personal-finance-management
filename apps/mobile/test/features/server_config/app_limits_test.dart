import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/money/currency_catalog.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/server_config/domain/app_limits.dart';
import 'package:mobile/features/server_config/domain/server_config.dart';
import 'package:mobile/features/server_config/domain/server_config_repository.dart';
import 'package:mobile/features/server_config/presentation/viewmodels/server_config_view_model.dart';
import 'package:mobile/features/server_config/presentation/widgets/server_config_boundary.dart';

import '../../core/widgets/widget_test_app.dart';
import '../../support/server_config_fixture.dart';

void main() {
  group('MOB-P5-001 AppLimits', () {
    test('reads every number from the server config', () {
      final limits = testLimits({
        'installment.termOptions': [6, 24],
        'creditCard.dueSoonDays': 5,
      });
      expect(limits.installmentTermOptions, [6, 24]);
      expect(limits.creditDueSoonDays, 5);
      expect(limits.dailyLogDefaultTime, '21:00');
    });

    test('is null when a key is missing, so nothing is guessed', () {
      final values = testConfigValues()..remove('report.topRows');
      final config = ServerConfig(version: 1, flags: const {}, values: values);
      expect(AppLimits.from(config), isNull);
      expect(AppLimits.from(testServerConfig()), isNotNull);
    });

    test('the model rebuilds limits when the version changes', () {
      final model = testServerConfigModel();
      expect(model.requireLimits.reportTopRows, 3);
      model.debugSetConfig(
        ServerConfig(
          version: 2,
          flags: const {},
          values: testConfigValues({'report.topRows': 5}),
        ),
      );
      expect(model.requireLimits.reportTopRows, 5);
    });
  });

  group('MOB-P5-001 ServerConfigBoundary', () {
    Widget app(AuthStage stage, ServerConfigViewModel model) => testApp(
      ServerConfigBoundary(
        auth: _Auth(stage),
        model: model,
        child: const Text('signed-in app'),
      ),
    );

    testWidgets('signed out also runs on (public) config', (tester) async {
      final model = ServerConfigViewModel.withClock(_Repo());
      await tester.pumpWidget(app(AuthStage.signedOut, model));
      expect(find.text('signed-in app'), findsNothing);
      model.debugSetConfig(testServerConfig());
      await tester.pump();
      expect(find.text('signed-in app'), findsOneWidget);
    });

    testWidgets('with a session it shows the app once config is there', (
      tester,
    ) async {
      final model = ServerConfigViewModel.withClock(_Repo());
      await tester.pumpWidget(app(AuthStage.unlocked, model));
      expect(find.text('signed-in app'), findsNothing);
      model.debugSetConfig(testServerConfig());
      await tester.pump();
      expect(find.text('signed-in app'), findsOneWidget);
    });

    testWidgets('signed in it also waits for the currency catalog', (
      tester,
    ) async {
      final saved = CurrencyCatalog.current;
      addTearDown(() => CurrencyCatalog.current = saved);
      CurrencyCatalog.current = const CurrencyCatalog([]);
      final model = ServerConfigViewModel.withClock(_Repo());
      // The public config (before sign-in) has numbers but no currencies.
      model.debugSetConfig(
        ServerConfig(version: 1, flags: const {}, values: testConfigValues()),
      );
      await tester.pumpWidget(app(AuthStage.unlocked, model));
      expect(find.text('signed-in app'), findsNothing);
      model.debugSetConfig(testServerConfig());
      await tester.pump();
      await tester.pump();
      expect(find.text('signed-in app'), findsOneWidget);
      expect(CurrencyCatalog.current.symbol('VND'), '₫');
    });

    testWidgets('a failed first load offers try again', (tester) async {
      final repo = _Repo();
      final model = ServerConfigViewModel.withClock(repo);
      await model.refresh();
      await tester.pumpWidget(app(AuthStage.setup, model));
      expect(find.text('Chưa tải được cài đặt'), findsOneWidget);
      repo.next = right(testServerConfig());
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('signed-in app'), findsOneWidget);
    });
  });
}

class _Auth extends ChangeNotifier implements AuthViewModel {
  _Auth(this.stage);

  @override
  final AuthStage stage;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo implements ServerConfigRepository {
  @override
  Future<Either<AuthFailure, ServerConfig>> fetchPublic() => fetch();

  Either<AuthFailure, ServerConfig> next = left(
    const AuthFailure(AuthError.network),
  );

  @override
  Future<Either<AuthFailure, ServerConfig>> fetch() async => next;
  @override
  Future<ServerConfig?> readCached() async => null;
  @override
  Future<void> writeCached(ServerConfig config) async {}
  @override
  Future<void> clearCached() async {}
}
