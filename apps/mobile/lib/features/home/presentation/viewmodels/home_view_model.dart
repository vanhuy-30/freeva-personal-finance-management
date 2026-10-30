import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../settings/presentation/viewmodels/settings_view_model.dart';
import '../../../sync/domain/sync_item.dart';
import '../../../sync/presentation/viewmodels/sync_view_model.dart';
import '../../domain/overview.dart';
import '../../domain/overview_use_cases.dart';

enum HomeStatus {
  /// First load, nothing to show yet: skeletons.
  loading,

  /// Fresh data.
  ready,

  /// Reload failed but earlier data is kept: shown with "Số liệu lúc …".
  offline,

  /// Nothing loaded and the load failed: error card with "Thử lại".
  error,
}

abstract class HomeViewModel extends ChangeNotifier {
  HomeStatus get status;
  OverviewData? get data;
  String? get displayName;
  String get currency;

  /// Currency the balance card converts into: the saved choice, else
  /// [currency].
  String get displayCurrency;

  /// Currency codes the user may pick; empty until the profile options load.
  List<String> get currencyChoices;
  bool get balancesHidden;

  /// Whether this device has a PIN (the checklist asks for one if not).
  bool get hasPin;

  /// Whether the user's goal is "Quản lý khoản nợ": credit cards go above
  /// "Chi tháng".
  bool get debtGoal => false;

  /// Today, for the greeting date.
  DateTime get today;

  /// Transactions recorded on this device that are still waiting to sync.
  List<SyncQueueItem> get pending;
  Future<void> load();
  Future<void> toggleBalances();

  /// Saves the display currency on the account and reloads. False on failure.
  Future<bool> chooseDisplayCurrency(String? code);

  /// Saves a typed rate (1 [from] = [rate] [to]) and reloads. False when the
  /// rate is invalid or the save failed.
  Future<bool> saveRate(String from, String to, String rate);
}

@LazySingleton(as: HomeViewModel)
class DefaultHomeViewModel extends HomeViewModel {
  DefaultHomeViewModel(
    this._cases,
    this._auth,
    this._profile,
    this._settings,
    this._sync, {
    @ignoreParam DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _stage = _auth.stage;
    _seenApplied = _sync.appliedEpoch;
    _auth.addListener(_authChanged);
    _profile.addListener(notifyListeners);
    _settings.addListener(notifyListeners);
    _sync.addListener(_syncChanged);
  }

  final OverviewUseCases _cases;
  final AuthViewModel _auth;
  final ProfileViewModel _profile;
  final SettingsViewModel _settings;
  final SyncViewModel _sync;
  final DateTime Function() _clock;
  late AuthStage _stage;
  late int _seenApplied;
  int _epoch = 0;
  bool _busy = false;

  @override
  HomeStatus status = HomeStatus.loading;
  @override
  OverviewData? data;

  @override
  String? get displayName => _profile.saved?.displayName;

  @override
  bool get debtGoal => _profile.saved?.goals.contains('debt') ?? false;
  @override
  String get currency => _profile.saved?.currency ?? 'VND';
  @override
  String get displayCurrency => _profile.saved?.overviewCurrency ?? 'VND';
  @override
  List<String> get currencyChoices => _profile.options?.currencies ?? const [];
  @override
  bool get balancesHidden => _settings.balancesHidden;
  @override
  bool get hasPin => _auth.hasPin;
  @override
  DateTime get today => _clock();
  @override
  List<SyncQueueItem> get pending => [
    for (final item in _sync.items)
      if (item.action == SyncAction.create) item,
  ];

  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    // Balances never outlive the unlocked session (memory only).
    _epoch++;
    data = null;
    status = HomeStatus.loading;
    _busy = false;
    notifyListeners();
    if (_stage == AuthStage.unlocked) load();
  }

  void _syncChanged() {
    if (_sync.appliedEpoch != _seenApplied) {
      _seenApplied = _sync.appliedEpoch;
      load();
    } else {
      notifyListeners();
    }
  }

  @override
  Future<void> load() async {
    if (_busy || _stage != AuthStage.unlocked) return;
    final epoch = ++_epoch;
    _busy = true;
    if (data == null) {
      status = HomeStatus.loading;
      notifyListeners();
    }
    final result = await _cases.load(
      _clock(),
      displayCurrency: displayCurrency,
    );
    if (epoch != _epoch) return;
    _busy = false;
    result.fold(
      (failure) {
        if (failure.code == AuthError.expired) _auth.sessionExpired();
        status = data == null ? HomeStatus.error : HomeStatus.offline;
      },
      (value) {
        data = value;
        status = HomeStatus.ready;
      },
    );
    notifyListeners();
  }

  @override
  Future<bool> chooseDisplayCurrency(String? code) async {
    if (!await _profile.saveDisplayCurrency(code)) return false;
    await _reload();
    return true;
  }

  @override
  Future<bool> saveRate(String from, String to, String rate) async {
    final saving = _cases.saveRate(from, to, rate);
    if (saving == null) return false;
    final result = await saving;
    final saved = result.isRight();
    if (result.fold((f) => f.code == AuthError.expired, (_) => false)) {
      _auth.sessionExpired();
    }
    if (saved) await _reload();
    return saved;
  }

  /// Fetches again even while a load is running; its answer is dropped by the
  /// epoch guard in [load].
  Future<void> _reload() async {
    _busy = false;
    await load();
  }

  @override
  Future<void> toggleBalances() =>
      _settings.setBalancesHidden(!_settings.balancesHidden);

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    _profile.removeListener(notifyListeners);
    _settings.removeListener(notifyListeners);
    _sync.removeListener(_syncChanged);
    super.dispose();
  }
}
