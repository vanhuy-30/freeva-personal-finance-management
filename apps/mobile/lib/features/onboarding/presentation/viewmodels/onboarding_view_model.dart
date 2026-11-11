import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../budgets/domain/budget.dart';
import '../../../server_config/domain/app_limits.dart';
import '../../../budgets/domain/budget_use_cases.dart';
import '../../../goals/domain/goal.dart';
import '../../../goals/domain/goal_use_cases.dart';
import '../../../profile/domain/profile_use_cases.dart';
import '../../../settings/domain/app_preferences.dart';
import '../../../settings/domain/settings_use_cases.dart';
import '../../../sync/domain/sync_queue.dart';
import '../../domain/onboarding_answers.dart';
import '../../domain/pending_goal_use_cases.dart';

/// Monthly split the first budget suggestion shows (minor units).
class BudgetSuggestion {
  const BudgetSuggestion({
    required this.income,
    required this.saving,
    required this.spending,
    required this.fromGoal,
  });
  final BigInt income;
  final BigInt saving;
  final BigInt spending;

  /// True when [saving] is the goal's monthly need; false = 20% of income.
  final bool fromGoal;
}

/// Choices on the three first-run questions and the budget suggestion.
/// Saving is best effort: the answers only personalise the app, so a failed
/// save never holds anyone on a screen.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel(
    this._profile,
    this._settings,
    this._goals,
    this._pending,
    this._budgets, {
    required this._limits,
    this.today,
    this.previewDelay = const Duration(milliseconds: 300),
  });

  /// Server product numbers (MOB-P5-001).
  final AppLimitsSource _limits;
  final ProfileUseCases _profile;
  final SettingsUseCases _settings;
  final GoalUseCases _goals;
  final PendingGoalUseCases _pending;

  /// Null when the budget module is not registered (some tests).
  final BudgetUseCases? _budgets;

  /// Fixed date for tests; null = device date.
  final DateTime? today;
  final Duration previewDelay;

  static const maxGoals = 2;
  static const maxAmountDigits = 12;

  /// Quick income amounts, in whole VND (shown only for VND).
  static const incomeSuggestions = [10000000, 15000000, 25000000, 40000000];

  /// Goal kinds offered on question 3, in board order; `custom` = "Khác".
  static const savingKinds = [
    'emergency',
    'home',
    'car',
    'travel',
    'education',
    'wedding',
    'custom',
  ];

  /// Profile currency; the first run happens in it.
  String currency = 'VND';
  int get digits => currency == 'VND' ? 0 : 2;

  final List<OnboardingGoal> goals = [];

  String _incomeDigits = '';
  String? savingKind;
  BigInt _targetMinor = BigInt.zero;

  /// `YYYY-MM-DD`; null until picked.
  String? savingDate;

  /// Server numbers for the saving goal; null until both fields are set.
  GoalPreview? preview;
  Timer? _previewTimer;
  int _previewEpoch = 0;
  Future<void>? _previewLoad;

  /// Loads the profile currency; keeps VND when it cannot.
  Future<void> load() async {
    final loaded = await _profile.load();
    loaded.fold((_) {}, (profile) => currency = profile.currency);
    notifyListeners();
  }

  // Question 1 ---------------------------------------------------------------

  bool canPickGoal(OnboardingGoal goal) =>
      goals.contains(goal) || goals.length < maxGoals;

  void toggleGoal(OnboardingGoal goal) {
    if (goals.contains(goal)) {
      goals.remove(goal);
    } else if (goals.length < maxGoals) {
      goals.add(goal);
    }
    notifyListeners();
  }

  Future<void> saveGoals() async {
    if (goals.isEmpty) return;
    await _profile.saveOnboarding(OnboardingAnswers(goals: List.of(goals)));
  }

  // Question 2 ---------------------------------------------------------------

  /// Income in whole currency units, 0 when nothing is typed.
  BigInt get income => BigInt.tryParse(_incomeDigits) ?? BigInt.zero;
  BigInt get incomeMinor => income * BigInt.from(10).pow(digits);

  void typeIncome(String keys) => _type(keys, _incomeDigits, (v) {
    _incomeDigits = v;
  });

  void deleteIncomeDigit() {
    if (_incomeDigits.isEmpty) return;
    _incomeDigits = _incomeDigits.substring(0, _incomeDigits.length - 1);
    notifyListeners();
  }

  void setIncome(int value) {
    _incomeDigits = value > 0 ? '$value' : '';
    notifyListeners();
  }

  /// Waited for before question 3, so the server's share of income in the
  /// goal preview uses the number just typed.
  Future<void> saveIncome() async {
    if (incomeMinor <= BigInt.zero) return;
    await _profile.saveOnboarding(
      OnboardingAnswers(monthlyIncomeMinor: incomeMinor),
    );
  }

  /// Skipping question 2 drops what was typed, so no suggestion follows.
  void clearIncome() {
    _incomeDigits = '';
    notifyListeners();
  }

  // Question 3 ---------------------------------------------------------------

  BigInt get targetMinor => _targetMinor;

  DateTime get _today => today ?? DateTime.now();

  /// Earliest date the picker allows: tomorrow (a goal due today needs no
  /// monthly saving).
  DateTime get firstDate {
    final now = _today;
    return DateTime(now.year, now.month, now.day + 1);
  }

  void pickKind(String kind) {
    savingKind = savingKind == kind ? null : kind;
    notifyListeners();
  }

  /// From the "Cần có" field, already in minor units; null = empty.
  void setTargetMinor(BigInt? value) {
    final next = value != null && value > BigInt.zero ? value : BigInt.zero;
    if (next == _targetMinor) return;
    _targetMinor = next;
    _schedulePreview();
    notifyListeners();
  }

  /// [day] is `YYYY-MM-DD` from the calendar sheet; null clears it.
  void pickDate(String? day) {
    savingDate = day;
    _schedulePreview();
    notifyListeners();
  }

  /// "Tiếp tục" on question 3 needs a kind, an amount and a date.
  bool get savingReady =>
      savingKind != null && targetMinor > BigInt.zero && savingDate != null;

  void _schedulePreview() {
    _previewTimer?.cancel();
    _previewEpoch++;
    preview = null;
    if (targetMinor <= BigInt.zero || savingDate == null) return;
    final epoch = _previewEpoch;
    _previewTimer = Timer(previewDelay, () {
      _previewLoad = _loadPreview(epoch);
    });
  }

  /// Fetches a pending preview now and waits for it, so the budget
  /// suggestion after question 3 uses the goal's real monthly need.
  Future<void> settlePreview() async {
    final timer = _previewTimer;
    if (timer != null && timer.isActive) {
      timer.cancel();
      _previewLoad = _loadPreview(_previewEpoch);
    }
    await _previewLoad;
  }

  Future<void> _loadPreview(int epoch) async {
    final result = await _goals.preview(
      currency: currency,
      targetMinor: targetMinor,
      targetDate: savingDate!,
    );
    if (epoch != _previewEpoch) return;
    preview = result.fold((_) => null, (value) => value);
    notifyListeners();
  }

  /// Keeps the goal until a wallet exists (the wallets step comes next);
  /// [name] is the kind's label in the user's language.
  Future<void> keepSavingGoal(String name) async {
    if (!savingReady) return;
    await _pending.keep(
      clientId: newSyncOpId(),
      kind: savingKind!,
      name: name,
      currency: currency,
      targetMinor: targetMinor,
      targetDate: savingDate!,
    );
  }

  /// Skipping question 3 forgets the goal, so the suggestion saves 20%.
  void clearSaving() {
    savingKind = null;
    _targetMinor = BigInt.zero;
    savingDate = null;
    _schedulePreview();
    notifyListeners();
  }

  // Budget suggestion --------------------------------------------------------

  /// Null without income, or when nothing would be left to spend.
  BudgetSuggestion? get suggestion {
    final total = incomeMinor;
    if (total <= BigInt.zero) return null;
    final need = savingReady ? preview?.requiredPerMonthMinor : null;
    final saving = need ?? total * BigInt.from(20) ~/ BigInt.from(100);
    final spending = total - saving;
    if (spending <= BigInt.zero) return null;
    return BudgetSuggestion(
      income: total,
      saving: saving,
      spending: spending,
      fromGoal: need != null,
    );
  }

  /// "Dùng mức này": creates this month's budget; keeps a device draft when
  /// the API is unavailable or a budget already exists.
  Future<void> useSuggestion() async {
    final amount = suggestion?.spending;
    if (amount == null) return;
    final budgets = _budgets;
    if (budgets != null) {
      final current = await budgets.current();
      final created = await current.fold((_) async => false, (value) async {
        if (value.budget != null) return true;
        final put = await budgets.put(
          BudgetDraft(
            limitMinor: amount,
            alertThresholds: List.of(
              _limits.requireLimits.budgetDefaultThresholds,
            ),
            categories: const [],
          ),
        );
        return put.isRight();
      });
      if (created) return;
    }
    final loaded = await _settings.load();
    final prefs = loaded.fold<AppPreferences?>((_) => null, (value) => value);
    if (prefs == null || !amount.isValidInt) return;
    await _settings.save(prefs.copyWith(budgetDraftMinor: amount.toInt()));
  }

  void _type(String keys, String current, void Function(String) set) {
    final next = (current + keys).replaceFirst(RegExp(r'^0+'), '');
    if (next.length > maxAmountDigits) return;
    set(next);
    notifyListeners();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }
}
