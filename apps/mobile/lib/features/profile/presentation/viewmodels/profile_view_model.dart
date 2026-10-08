import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
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
}

@LazySingleton(as: ProfileViewModel)
class DefaultProfileViewModel extends ProfileViewModel {
  DefaultProfileViewModel(this._useCases, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
    if (_stage == AuthStage.unlocked) Future.microtask(load);
  }
  final ProfileUseCases _useCases;
  final AuthViewModel _auth;
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
      locale = value.locale;
      succeeded = true;
    });
    if (epoch != _epoch) return;
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
