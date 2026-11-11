import 'dart:async';

import 'package:mobile/core/money/currency_catalog.dart';

import 'support/server_config_fixture.dart';

/// Every test starts with the server's currency catalog loaded (MOB-P5-001),
/// as the signed-in app does.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  CurrencyCatalog.current = const CurrencyCatalog(testCurrencies);
  await testMain();
}
