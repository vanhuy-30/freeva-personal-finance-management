import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../settings/domain/settings_use_cases.dart';
import '../../domain/pending_goal_use_cases.dart';

/// Follow-ups of the first-run answers shown on Tổng quan: creates the saving
/// goal once a wallet exists, and offers the daily log reminder once after
/// the first transaction to people who picked "Quản lý chi tiêu".
@lazySingleton
class FirstRunNudgesViewModel extends ChangeNotifier {
  FirstRunNudgesViewModel(this._pending, this._settings);

  final PendingGoalUseCases _pending;
  final SettingsUseCases _settings;

  bool _checking = false;
  bool _asking = false;

  /// Called after each Overview load. Returns true when the saving goal was
  /// created now (the goals block should reload). Sets [askDailyLog].
  Future<bool> check({
    required bool trackGoal,
    required bool hasTransactions,
  }) async {
    if (_checking) return false;
    _checking = true;
    try {
      final created = await _pending.flush();
      if (trackGoal && hasTransactions && !_asking) {
        final prefs = (await _settings.load()).fold((_) => null, (p) => p);
        if (prefs != null && !prefs.dailyLogAsked) {
          _asking = true;
          notifyListeners();
        }
      }
      return created;
    } finally {
      _checking = false;
    }
  }

  /// True while the reminder sheet should open (once).
  bool get askDailyLog => _asking;

  /// The sheet was answered or closed: never offer it again.
  Future<void> dailyLogAnswered() async {
    _asking = false;
    final prefs = (await _settings.load()).fold((_) => null, (p) => p);
    if (prefs != null && !prefs.dailyLogAsked) {
      await _settings.save(prefs.copyWith(dailyLogAsked: true));
    }
    notifyListeners();
  }
}
