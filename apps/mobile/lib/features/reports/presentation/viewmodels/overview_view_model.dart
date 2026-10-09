import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/report.dart';
import '../../domain/report_use_cases.dart';

abstract class OverviewViewModel extends ChangeNotifier {
  OverviewSnapshot? get snapshot;
  bool get busy;
  AuthFailure? get failure;
  Future<void> load();
}

@LazySingleton(as: OverviewViewModel)
class DefaultOverviewViewModel extends OverviewViewModel {
  DefaultOverviewViewModel(this._cases, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final ReportUseCases _cases;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _epoch = 0;

  @override
  OverviewSnapshot? snapshot;
  @override
  bool busy = false;
  @override
  AuthFailure? failure;

  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    _epoch++;
    snapshot = null;
    failure = null;
    busy = false;
    notifyListeners();
    if (_stage == AuthStage.unlocked) load();
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  @override
  Future<void> load() async {
    if (busy || _stage != AuthStage.unlocked) return;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.loadOverview();
    if (epoch != _epoch) return;
    result.fold(_fail, (value) => snapshot = value);
    if (epoch != _epoch) return;
    busy = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
