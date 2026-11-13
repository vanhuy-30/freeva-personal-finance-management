import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/feature_flags/feature_flag_service.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/auto_suggest/domain/auto_suggest_repository.dart';
import 'package:mobile/features/auto_suggest/domain/merchant_mapping.dart';
import 'package:mobile/features/auto_suggest/presentation/viewmodels/auto_suggest_view_model.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';

/// Board U.1 rows (newest first), padded to [count] with extra shops.
List<MerchantMapping> boardMappings([int count = 12]) {
  const named = [
    ('Highlands Coffee', 'Cà phê', 'coffee'),
    ('Grab', 'Đi lại', 'transport'),
    ('Shopee', 'Mua sắm', 'shopping'),
    ('Phở Thìn', 'Ăn uống', 'food'),
  ];
  return [
    for (var i = 0; i < count; i++)
      MerchantMapping(
        id: 'm$i',
        merchant: i < named.length ? named[i].$1 : 'Cửa hàng $i',
        categoryId: 'c$i',
        categoryName: i < named.length ? named[i].$2 : 'Khác',
        iconToken: i < named.length ? named[i].$3 : null,
        updatedAt: DateTime.utc(2026, 11, 10).subtract(Duration(days: i)),
      ),
  ];
}

class MemoryAutoSuggest implements AutoSuggestRepository {
  List<MerchantMapping> items = boardMappings(6);
  AuthFailure? failure;

  /// When set, only [forget] fails (the list call still works).
  AuthFailure? forgetFailure;
  final enabledCalls = <bool>[];
  final forgotten = <String>[];
  int clears = 0;

  @override
  Future<Either<AuthFailure, Unit>> setEnabled(bool enabled) async {
    enabledCalls.add(enabled);
    return failure == null ? right(unit) : left(failure!);
  }

  @override
  Future<Either<AuthFailure, List<MerchantMapping>>> mappings() async =>
      failure == null ? right(List.of(items)) : left(failure!);

  @override
  Future<Either<AuthFailure, Unit>> forget(String id) async {
    final error = forgetFailure ?? failure;
    if (error != null) return left(error);
    forgotten.add(id);
    items = [...items]..removeWhere((m) => m.id == id);
    return right(unit);
  }

  @override
  Future<Either<AuthFailure, Unit>> clear() async {
    if (failure != null) return left(failure!);
    clears++;
    items = [];
    return right(unit);
  }
}

class FakeFlags extends ChangeNotifier implements FeatureFlagService {
  Set<String> on = {};
  @override
  bool isEnabled(String key) => on.contains(key);
}

class FakeAuth extends ChangeNotifier implements AuthViewModel {
  @override
  AuthStage stage = AuthStage.unlocked;
  int expired = 0;

  @override
  void sessionExpired() => expired++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProfile extends ChangeNotifier implements ProfileViewModel {
  @override
  Profile? saved = const Profile(
    locale: 'vi',
    currency: 'VND',
    timezone: 'Asia/Ho_Chi_Minh',
    fiscalDay: 1,
    version: 1,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Screen stub: fixed state, writes succeed.
class StubAutoSuggestViewModel extends AutoSuggestViewModel {
  StubAutoSuggestViewModel({
    this.mappings = const [],
    this.enabled = true,
    this.available = true,
  });

  @override
  List<MerchantMapping> mappings;
  @override
  bool enabled;
  @override
  bool available;
  @override
  bool get saving => false;
  @override
  bool get loaded => true;
  @override
  Future<void> load() async {}
  @override
  Future<bool> setEnabled(bool value) async {
    enabled = value;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> forget(MerchantMapping mapping) async {
    mappings = [...mappings]..remove(mapping);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> clearAll() async {
    mappings = const [];
    notifyListeners();
    return true;
  }
}
