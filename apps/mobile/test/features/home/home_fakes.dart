import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/home/domain/overview.dart';
import 'package:mobile/features/home/domain/overview_use_cases.dart';
import 'package:mobile/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';

class FakeOverviewCases implements OverviewUseCases {
  final results = <Either<AuthFailure, OverviewData>>[];
  int calls = 0;
  String? lastDisplayCurrency;

  @override
  Future<Either<AuthFailure, OverviewData>> load(
    DateTime now, {
    String? displayCurrency,
  }) async {
    calls++;
    lastDisplayCurrency = displayCurrency;
    return results.length > 1 ? results.removeAt(0) : results.single;
  }

  @override
  Future<Either<AuthFailure, Unit>>? saveRate(
    String from,
    String to,
    String rate,
  ) => null;
}

class FakeProfileViewModel extends ChangeNotifier implements ProfileViewModel {
  @override
  Profile? saved = const Profile(
    locale: 'vi',
    currency: 'VND',
    timezone: 'Asia/Ho_Chi_Minh',
    fiscalDay: 1,
    version: 1,
    displayName: 'Minh',
  );

  @override
  ProfileOptions? options = ProfileOptions(
    currencies: ['VND', 'USD'],
    timezones: ['Asia/Ho_Chi_Minh'],
  );
  final savedDisplayCurrencies = <String?>[];
  bool saveDisplayCurrencyResult = true;

  @override
  Future<bool> saveDisplayCurrency(String? code) async {
    if (!saveDisplayCurrencyResult) return false;
    savedDisplayCurrencies.add(code);
    saved = saved?.withDisplayCurrency(code);
    notifyListeners();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSyncViewModel extends ChangeNotifier implements SyncViewModel {
  @override
  List<SyncQueueItem> items = const [];
  @override
  List<SyncQueueItem> get attention => [
    for (final i in items)
      if (i.status != SyncItemStatus.pending) i,
  ];
  @override
  List<SyncQueueItem> get waiting => [
    for (final i in items)
      if (i.status == SyncItemStatus.pending) i,
  ];
  @override
  SyncLink link = SyncLink.ok;
  @override
  DateTime? lastSyncedAt;
  @override
  int appliedEpoch = 0;
  @override
  bool syncing = false;
  @override
  bool schemaMismatch = false;
  @override
  SyncDuplicate? duplicate;

  void applied() {
    appliedEpoch++;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Screen-level fake: every state is set directly.
class StubHomeViewModel extends HomeViewModel {
  StubHomeViewModel({
    this.status = HomeStatus.ready,
    this.data,
    this.displayName = 'Minh',
    this.balancesHidden = false,
    this.pending = const [],
    this.hasPin = true,
    this.debtGoal = false,
  });

  @override
  HomeStatus status;
  @override
  OverviewData? data;
  @override
  String? displayName;
  @override
  String currency = 'VND';
  @override
  String displayCurrency = 'VND';
  @override
  List<String> currencyChoices = const ['VND', 'USD'];
  final chosen = <String?>[];
  final rates = <String>[];
  @override
  bool balancesHidden;
  @override
  bool hasPin;
  @override
  List<SyncQueueItem> pending;
  @override
  bool debtGoal;
  @override
  DateTime today = DateTime(2026, 10, 21, 9, 30);
  int loads = 0;

  @override
  Future<void> load() async => loads++;

  @override
  Future<bool> chooseDisplayCurrency(String? code) async {
    chosen.add(code);
    return true;
  }

  @override
  Future<bool> saveRate(String from, String to, String rate) async {
    rates.add('$from>$to=$rate');
    return true;
  }

  @override
  Future<void> toggleBalances() async {
    balancesHidden = !balancesHidden;
    notifyListeners();
  }
}
