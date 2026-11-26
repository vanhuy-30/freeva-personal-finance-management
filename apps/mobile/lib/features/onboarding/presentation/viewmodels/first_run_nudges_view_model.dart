import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../budgets/domain/budget.dart';
import '../../../budgets/domain/budget_use_cases.dart';
import '../../../notifications/domain/notification_models.dart';
import '../../../notifications/domain/notification_use_cases.dart';
import '../../../server_config/domain/app_limits.dart';
import '../../../settings/domain/settings_use_cases.dart';
import '../../domain/pending_goal_use_cases.dart';

/// Follow-ups of the first run shown on Tổng quan: creates the saving goal
/// once a wallet exists, offers the monthly budget once (board BudgetAsk)
/// when there is none, and offers the daily log reminder once after the
/// first transaction to people who picked "Quản lý thu nhập và chi tiêu".
@lazySingleton
class FirstRunNudgesViewModel extends ChangeNotifier {
  FirstRunNudgesViewModel(
    this._pending,
    this._settings,
    this._budgets,
    this._limits,
    this._notifications,
  );

  final PendingGoalUseCases _pending;
  final SettingsUseCases _settings;
  final BudgetUseCases _budgets;
  final AppLimitsSource _limits;
  final NotificationUseCases _notifications;

  bool _checking = false;
  bool _askingLog = false;
  bool _askingBudget = false;

  /// Called after each Overview load. Returns true when the saving goal was
  /// created now (the goals block should reload). Sets [askBudget] or
  /// [askDailyLog]; the budget comes first.
  /// [incomeMidpointMinor] is the declared income's midpoint in the profile
  /// currency, null when not shared.
  Future<bool> check({
    required bool trackGoal,
    required bool hasTransactions,
    BigInt? incomeMidpointMinor,
  }) async {
    if (_checking) return false;
    _checking = true;
    try {
      final created = await _pending.flush();
      final prefs = (await _settings.load()).fold((_) => null, (p) => p);
      if (prefs == null) return created;
      if (!prefs.budgetAsked && !_askingBudget && !_askingLog) {
        final current = await _budgets.current();
        final none = current.fold((_) => false, (c) => c.budget == null);
        if (none) {
          budgetSuggestion = _suggest(incomeMidpointMinor);
          _askingBudget = true;
          notifyListeners();
          return created;
        }
      }
      if (trackGoal &&
          hasTransactions &&
          !_askingLog &&
          !_askingBudget &&
          !prefs.dailyLogAsked) {
        // "Asked" lives on this phone only; the reminder itself is on the
        // account. After a reinstall it may already be on: do not ask again.
        final on = await _reminderOn();
        if (on == null) return created;
        if (on) {
          await _settings.save(prefs.copyWith(dailyLogAsked: true));
          return created;
        }
        _askingLog = true;
        notifyListeners();
      }
      return created;
    } finally {
      _checking = false;
    }
  }

  /// Whether the account has the daily reminder on; null when that could
  /// not be read (offline), so nothing is asked or remembered this time.
  Future<bool?> _reminderOn() async {
    final result = await _notifications.preferences();
    return result.fold<bool?>(
      (_) => null,
      (p) => p.toggle(NotificationKind.dailyLog)?.enabled ?? false,
    );
  }

  /// Spending part of the declared income: midpoint minus the default
  /// savings share (server `onboarding.savingsSharePercent`).
  BigInt? _suggest(BigInt? midpoint) {
    if (midpoint == null || midpoint <= BigInt.zero) return null;
    final share = _limits.requireLimits.onboardingSavingsSharePercent;
    final spend = midpoint * BigInt.from(100 - share) ~/ BigInt.from(100);
    return spend > BigInt.zero ? spend : null;
  }

  /// Amount the budget sheet starts with; null leaves the field empty.
  BigInt? budgetSuggestion;

  /// True while the budget sheet should open (once).
  bool get askBudget => _askingBudget;

  /// True while the reminder sheet should open (once).
  bool get askDailyLog => _askingLog;

  /// "Đặt ngân sách": this month's budget with the default alerts. False
  /// when it could not be saved (the sheet stays open).
  Future<bool> setBudget(BigInt limitMinor) async {
    final result = await _budgets.put(
      BudgetDraft(
        limitMinor: limitMinor,
        alertThresholds: List.of(_limits.requireLimits.budgetDefaultThresholds),
        categories: const [],
      ),
    );
    return result.isRight();
  }

  /// The budget sheet was answered or closed: never offer it again.
  Future<void> budgetAnswered() async {
    _askingBudget = false;
    final prefs = (await _settings.load()).fold((_) => null, (p) => p);
    if (prefs != null && !prefs.budgetAsked) {
      await _settings.save(prefs.copyWith(budgetAsked: true));
    }
    notifyListeners();
  }

  /// The reminder sheet was answered or closed: never offer it again.
  Future<void> dailyLogAnswered() async {
    _askingLog = false;
    final prefs = (await _settings.load()).fold((_) => null, (p) => p);
    if (prefs != null && !prefs.dailyLogAsked) {
      await _settings.save(prefs.copyWith(dailyLogAsked: true));
    }
    notifyListeners();
  }
}
