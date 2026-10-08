import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/category_use_cases.dart';
import '../../domain/finance_category.dart';

abstract class CategoryViewModel extends ChangeNotifier {
  List<FinanceCategory> get categories;
  CategoryOptions get options;
  bool get busy;
  bool get needsReload;
  AuthFailure? get failure;
  String newClientId();
  Future<void> load();
  Future<bool> save(
    CategoryDraft draft,
    String clientId, {
    FinanceCategory? category,
  });
  Future<bool> archive(FinanceCategory category);
  Future<bool> remove(
    FinanceCategory category, {
    String? replacementCategoryId,
  });
}

@LazySingleton(as: CategoryViewModel)
class DefaultCategoryViewModel extends CategoryViewModel {
  DefaultCategoryViewModel(this._cases, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }
  final CategoryUseCases _cases;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _epoch = 0;
  @override
  List<FinanceCategory> categories = const [];
  @override
  CategoryOptions options = const CategoryOptions();
  @override
  bool busy = false;
  @override
  bool needsReload = false;
  @override
  AuthFailure? failure;

  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    _epoch++;
    categories = const [];
    options = const CategoryOptions();
    failure = null;
    busy = false;
    needsReload = false;
    notifyListeners();
    if (_stage == AuthStage.unlocked) load();
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  @override
  String newClientId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  Future<void> load() async {
    if (busy || _stage != AuthStage.unlocked) return;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.manage();
    if (epoch != _epoch) return;
    result.fold(_fail, (value) {
      categories = value.items;
      options = value.options;
      needsReload = false;
    });
    if (epoch != _epoch) return;
    busy = false;
    notifyListeners();
  }

  bool get _canWrite => !busy && !needsReload && _stage == AuthStage.unlocked;

  void _replace(FinanceCategory value) {
    final items = [...categories];
    final index = items.indexWhere((item) => item.id == value.id);
    if (index < 0) {
      items.add(value);
    } else {
      items[index] = value;
    }
    items.sort((a, b) {
      final created = (a.createdAt ?? DateTime.utc(0)).compareTo(
        b.createdAt ?? DateTime.utc(0),
      );
      return created != 0 ? created : a.id.compareTo(b.id);
    });
    categories = List.unmodifiable(items);
  }

  @override
  Future<bool> save(
    CategoryDraft draft,
    String clientId, {
    FinanceCategory? category,
  }) async {
    if (!_canWrite) return false;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.save(
      draft,
      categories,
      options,
      category: category,
      clientId: clientId,
    );
    if (epoch != _epoch) return false;
    result.fold((error) {
      needsReload = error.code == AuthError.conflict;
      _fail(error);
    }, _replace);
    if (epoch != _epoch) return false;
    busy = false;
    notifyListeners();
    return result.isRight();
  }

  @override
  Future<bool> archive(FinanceCategory category) async {
    if (!_canWrite) return false;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.update(
      category,
      categories,
      archived: !category.archived,
    );
    if (epoch != _epoch) return false;
    result.fold((error) {
      needsReload = error.code == AuthError.conflict;
      _fail(error);
    }, _replace);
    if (epoch != _epoch) return false;
    busy = false;
    notifyListeners();
    return result.isRight();
  }

  @override
  Future<bool> remove(
    FinanceCategory category, {
    String? replacementCategoryId,
  }) async {
    if (!_canWrite) return false;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.delete(
      category,
      categories,
      replacementCategoryId: replacementCategoryId,
    );
    if (epoch != _epoch) return false;
    result.fold(
      (error) {
        needsReload = error.code == AuthError.conflict;
        _fail(error);
      },
      (_) {
        categories = List.unmodifiable(
          categories.where((item) => item.id != category.id),
        );
      },
    );
    if (epoch != _epoch) return false;
    busy = false;
    notifyListeners();
    return result.isRight();
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
