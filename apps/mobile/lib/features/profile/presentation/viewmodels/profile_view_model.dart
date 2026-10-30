import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/account_export_use_case.dart';
import '../../domain/profile.dart';
import '../../domain/profile_use_cases.dart';

abstract class ProfileViewModel extends ChangeNotifier {
  Profile? get saved;
  Profile? get draft;
  ProfileOptions? get options;
  String get locale;
  bool get loading;
  bool get succeeded;
  bool get dirty;
  AuthFailure? get failure;
  void edit(Profile value);
  void cancel();
  Future<void> load();
  Future<void> save();

  /// Saves the Overview display currency on the account (null = default).
  /// Returns false when the server refused or the session changed.
  Future<bool> saveDisplayCurrency(String? code);

  /// True while an export is being fetched or handed to the OS.
  bool get exporting;
  Future<bool> exportData();
}

@LazySingleton(as: ProfileViewModel)
class DefaultProfileViewModel extends ProfileViewModel {
  DefaultProfileViewModel(this._useCases, this._auth, this._export) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
    if (_stage == AuthStage.unlocked) Future.microtask(load);
  }
  final ProfileUseCases _useCases;
  final AuthViewModel _auth;
  final AccountExportUseCase _export;
  late AuthStage _stage;
  int _epoch = 0;
  @override
  Profile? saved;
  @override
  Profile? draft;
  @override
  ProfileOptions? options;
  @override
  String locale = 'vi';
  @override
  bool loading = false;
  @override
  bool succeeded = false;
  @override
  AuthFailure? failure;
  @override
  bool get dirty =>
      draft != null && saved != null && !draft!.samePreferences(saved!);
  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    _epoch++;
    saved = null;
    draft = null;
    options = null;
    failure = null;
    loading = false;
    succeeded = false;
    if (_stage == AuthStage.signedOut) locale = 'vi';
    if (_stage == AuthStage.unlocked) {
      load();
    } else {
      notifyListeners();
    }
  }

  Future<void> _fail(AuthFailure error) async {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  @override
  Future<void> load() async {
    if (loading || _stage != AuthStage.unlocked) return;
    final epoch = ++_epoch;
    loading = true;
    failure = null;
    succeeded = false;
    notifyListeners();
    final profile = await _useCases.load();
    if (epoch != _epoch) return;
    final error = profile.fold<AuthFailure?>((e) => e, (_) => null);
    if (error != null) {
      await _fail(error);
    } else {
      final choices = await _useCases.options();
      if (epoch != _epoch) return;
      await choices.fold((e) => _fail(e), (value) async {
        saved = profile.getOrElse(() => throw StateError('Missing profile'));
        draft = saved;
        unawaited(_auth.rememberName(saved!.displayName));
        // Preserve a valid legacy IANA alias even if absent from the canonical list.
        options = ProfileOptions(
          currencies: value.currencies,
          timezones: {...value.timezones, saved!.timezone}.toList()..sort(),
        );
        locale = saved!.locale;
      });
    }
    if (epoch != _epoch) return;
    loading = false;
    notifyListeners();
  }

  @override
  void edit(Profile value) {
    if (loading || saved == null) return;
    draft = value;
    succeeded = false;
    failure = null;
    notifyListeners();
  }

  @override
  void cancel() {
    if (loading) return;
    draft = saved;
    succeeded = false;
    failure = null;
    notifyListeners();
  }

  @override
  Future<void> save() async {
    if (loading || !dirty || options == null || _stage != AuthStage.unlocked) {
      return;
    }
    final epoch = ++_epoch;
    loading = true;
    failure = null;
    succeeded = false;
    notifyListeners();
    final result = await _useCases.save(draft!, options!);
    if (epoch != _epoch) return;
    await result.fold((e) => _fail(e), (value) async {
      saved = value;
      draft = value;
      unawaited(_auth.rememberName(value.displayName));
      locale = value.locale;
      succeeded = true;
    });
    if (epoch != _epoch) return;
    loading = false;
    notifyListeners();
  }

  @override
  Future<bool> saveDisplayCurrency(String? code) async {
    final current = saved;
    final choices = options;
    if (current == null || choices == null || _stage != AuthStage.unlocked) {
      return false;
    }
    final epoch = _epoch;
    final result = await _useCases.saveDisplayCurrency(code, choices);
    if (epoch != _epoch) return false;
    return result.fold(
      (e) {
        unawaited(_fail(e));
        notifyListeners();
        return false;
      },
      (_) {
        saved = current.withDisplayCurrency(code);
        draft = draft?.withDisplayCurrency(code);
        notifyListeners();
        return true;
      },
    );
  }

  @override
  bool exporting = false;

  @override
  Future<bool> exportData() async {
    if (exporting || _stage != AuthStage.unlocked) return false;
    final epoch = _epoch;
    exporting = true;
    failure = null;
    notifyListeners();
    final result = await _export(DateTime.now());
    if (epoch != _epoch) return false;
    exporting = false;
    var shared = false;
    await result.fold((e) => _fail(e), (value) async => shared = value);
    notifyListeners();
    return shared;
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
