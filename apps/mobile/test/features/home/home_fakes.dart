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

  @override
  Future<Either<AuthFailure, OverviewData>> load(DateTime now) async {
    calls++;
    return results.length > 1 ? results.removeAt(0) : results.single;
  }
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSyncViewModel extends ChangeNotifier implements SyncViewModel {
  @override
  List<SyncQueueItem> items = const [];
  @override
  int appliedEpoch = 0;
  @override
  bool syncing = false;
  @override
  bool schemaMismatch = false;
  @override
  bool duplicateHint = false;

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
  bool balancesHidden;
  @override
  bool hasPin;
  @override
  List<SyncQueueItem> pending;
  @override
  DateTime today = DateTime(2026, 10, 21, 9, 30);
  int loads = 0;

  @override
  Future<void> load() async => loads++;

  @override
  Future<void> toggleBalances() async {
    balancesHidden = !balancesHidden;
    notifyListeners();
  }
}
