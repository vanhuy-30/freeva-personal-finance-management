import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/feature_flags/feature_flag_service.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../server_config/domain/server_config.dart';
import '../../domain/auto_suggest_repository.dart';
import '../../domain/merchant_mapping.dart';

/// Gợi ý tự động (MOB-P5-002): the switch and the remembered merchants.
/// Writes are optimistic; each returns false after putting the old state back,
/// so the page can show a toast.
abstract class AutoSuggestViewModel extends ChangeNotifier {
  /// Whether the Cá nhân row shows: at least one of the flags it controls is on.
  bool get available;

  /// The switch. Follows the profile until the user flips it here.
  bool get enabled;

  /// True while the switch is being saved.
  bool get saving;

  /// Remembered merchants, newest first; empty until [loaded].
  List<MerchantMapping> get mappings;
  bool get loaded;

  Future<void> load();
  Future<bool> setEnabled(bool value);
  Future<bool> forget(MerchantMapping mapping);
  Future<bool> clearAll();
}

@LazySingleton(as: AutoSuggestViewModel)
class DefaultAutoSuggestViewModel extends AutoSuggestViewModel {
  DefaultAutoSuggestViewModel(
    this._repository,
    this._flags,
    this._profile,
    this._auth,
  ) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
    _profile.addListener(notifyListeners);
    if (_flags case final Listenable flags) flags.addListener(notifyListeners);
  }

  final AutoSuggestRepository _repository;
  final FeatureFlagService _flags;
  final ProfileViewModel _profile;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _epoch = 0;
  bool? _enabled;
  bool _loading = false;

  @override
  bool saving = false;
  @override
  List<MerchantMapping> mappings = const [];
  @override
  bool loaded = false;

  @override
  bool get available => [
    FeatureFlags.categorySuggest,
    FeatureFlags.insights,
    FeatureFlags.forecast,
  ].any(_flags.isEnabled);

  @override
  bool get enabled => _enabled ?? _profile.saved?.autoSuggestEnabled ?? true;

  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    _epoch++;
    _enabled = null;
    _loading = false;
    saving = false;
    mappings = const [];
    loaded = false;
    notifyListeners();
  }

  void _fail(AuthFailure error) {
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  @override
  Future<void> load() async {
    if (_loading) return;
    final epoch = _epoch;
    _loading = true;
    final result = await _repository.mappings();
    if (epoch != _epoch) return;
    _loading = false;
    result.fold(_fail, (value) {
      mappings = value;
      loaded = true;
    });
    notifyListeners();
  }

  @override
  Future<bool> setEnabled(bool value) async {
    if (saving || value == enabled) return true;
    final epoch = _epoch;
    final before = _enabled;
    _enabled = value;
    saving = true;
    notifyListeners();
    final result = await _repository.setEnabled(value);
    if (epoch != _epoch) return false;
    saving = false;
    final ok = result.fold((error) {
      _fail(error);
      _enabled = before;
      return false;
    }, (_) => true);
    notifyListeners();
    return ok;
  }

  @override
  Future<bool> forget(MerchantMapping mapping) async {
    final at = mappings.indexWhere((m) => m.id == mapping.id);
    if (at < 0) return true;
    final epoch = _epoch;
    mappings = List.unmodifiable([...mappings]..removeAt(at));
    notifyListeners();
    final result = await _repository.forget(mapping.id);
    if (epoch != _epoch) return false;
    final error = result.fold<AuthFailure?>((e) => e, (_) => null);
    if (error == null) return true;
    _fail(error);
    // Already gone on the server (MAPPING_NOT_FOUND) counts as forgotten.
    final fresh = await _repository.mappings();
    if (epoch != _epoch) return false;
    final gone = fresh.fold(
      (_) => false,
      (list) => list.every((m) => m.id != mapping.id),
    );
    if (gone) return true;
    if (!mappings.any((m) => m.id == mapping.id)) {
      final restored = [...mappings];
      restored.insert(at.clamp(0, restored.length), mapping);
      mappings = List.unmodifiable(restored);
    }
    notifyListeners();
    return false;
  }

  @override
  Future<bool> clearAll() async {
    final epoch = _epoch;
    final before = mappings;
    mappings = const [];
    notifyListeners();
    final result = await _repository.clear();
    if (epoch != _epoch) return false;
    return result.fold((error) {
      _fail(error);
      mappings = before;
      notifyListeners();
      return false;
    }, (_) => true);
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    _profile.removeListener(notifyListeners);
    if (_flags case final Listenable flags) {
      flags.removeListener(notifyListeners);
    }
    super.dispose();
  }
}
