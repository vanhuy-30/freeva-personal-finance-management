import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/feature_flags/feature_flag_service.dart';
import '../../domain/app_limits.dart';
import '../../domain/server_config.dart';
import '../../domain/server_config_repository.dart';

/// MOB-P5-E08: holds the latest server flags and config for the signed-in user.
///
/// - Cached copy loads at boot so flags are right before the network answers.
/// - Fetches on unlock and when the app resumes, at most once per [refreshEvery]
///   unless forced; a new `version` replaces the cached copy.
/// - With no copy at all (never loaded), flags are off and [missing] is true, so a
///   screen that needs a value shows "try again" instead of guessing a number.
/// - Dev builds only: `--dart-define=FEATURE_FLAGS_ON=insights,forecast` turns flags on locally.
@lazySingleton
class ServerConfigViewModel extends ChangeNotifier
    implements FeatureFlagService, AppLimitsSource {
  ServerConfigViewModel(ServerConfigRepository repository, AppConfig appConfig)
    : this.withClock(
        repository,
        devOverlay: devOverlayFor(
          appConfig,
          const String.fromEnvironment('FEATURE_FLAGS_ON'),
        ),
      );

  @visibleForTesting
  ServerConfigViewModel.withClock(
    this._repository, {
    this._devOverlay = const {},
    this._now = DateTime.now,
  });

  static const refreshEvery = Duration(hours: 1);

  final ServerConfigRepository _repository;
  final Set<String> _devOverlay;
  final DateTime Function() _now;

  ServerConfig? _config;
  DateTime? _lastFetch;
  bool _loading = false;
  bool _failed = false;
  int _generation = 0;

  ServerConfig? get config => _config;

  AppLimits? _limits;
  int? _limitsVersion;

  /// Typed numbers for the current config; null with no config or a missing key.
  AppLimits? get limits {
    final config = _config;
    if (config == null) return null;
    if (_limitsVersion != config.version || _limits == null) {
      _limits = AppLimits.from(config);
      _limitsVersion = config.version;
    }
    return _limits;
  }

  /// Inside the signed-in app [ServerConfigBoundary] guarantees a config, so
  /// this never throws there.
  @override
  AppLimits get requireLimits => limits!;

  /// Tests: use [config] as if it had loaded.
  @visibleForTesting
  void debugSetConfig(ServerConfig config) {
    _config = config;
    notifyListeners();
  }

  bool get loading => _loading;

  /// No config to use: never loaded and the last fetch failed.
  bool get missing => _config == null && _failed;

  @override
  bool isEnabled(String key) =>
      _devOverlay.contains(key) || (_config?.flag(key) ?? false);

  /// Overlay keys from a dart-define, honoured only in debug dev builds.
  static Set<String> devOverlayFor(AppConfig appConfig, String raw) {
    if (appConfig.environment != AppEnvironment.dev ||
        kReleaseMode ||
        kProfileMode) {
      return const {};
    }
    return raw
        .split(',')
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet();
  }

  Future<void> loadCached() async {
    final cached = await _repository.readCached();
    if (cached != null && _config == null) {
      _config = cached;
      notifyListeners();
    }
  }

  Future<void> refresh({bool force = false}) async {
    if (_loading) return;
    final last = _lastFetch;
    if (!force && last != null && _now().difference(last) < refreshEvery) {
      return;
    }
    final generation = _generation;
    _loading = true;
    notifyListeners();
    final result = await _repository.fetch();
    // Signed out while the request was in flight: drop the answer.
    if (generation != _generation) return;
    _loading = false;
    await result.fold((_) async => _failed = true, (fresh) async {
      _failed = false;
      _lastFetch = _now();
      if (_config?.version != fresh.version || _config == null) {
        _config = fresh;
        await _repository.writeCached(fresh);
      }
    });
    notifyListeners();
  }

  /// Flags are evaluated per user, so sign-out forgets them.
  Future<void> clear() async {
    _generation += 1;
    _config = null;
    _lastFetch = null;
    _loading = false;
    _failed = false;
    notifyListeners();
    await _repository.clearCached();
  }
}
