import 'package:flutter/foundation.dart';

import '../../../profile/domain/declared_income.dart';
import '../../../profile/domain/profile_use_cases.dart';
import '../../../server_config/domain/app_limits.dart';
import '../../../sync/domain/sync_queue.dart';
import '../../domain/onboarding_answers.dart';
import '../../domain/pending_goal_use_cases.dart';
import '../../../../core/money/currency_catalog.dart';

/// Choices on the three first-run questions. Saving is best effort: the
/// answers only personalise the app, so a failed save never holds anyone on
/// a screen.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel(
    this._profile,
    this._pending, {
    required this._limits,
    this.today,
  });

  /// Server product numbers (MOB-P5-001).
  final AppLimitsSource _limits;
  final ProfileUseCases _profile;
  final PendingGoalUseCases _pending;

  /// Fixed date for tests; null = device date.
  final DateTime? today;

  /// Server `onboarding.maxGoals` (all six by default).
  int get maxGoals => _limits.requireLimits.onboardingMaxGoals;

  /// Income bands of question 2, from server `onboarding.incomeBandsVnd`.
  List<DeclaredIncome> get incomeBands =>
      incomeBandsFrom(_limits.requireLimits.onboardingIncomeBandsVnd);

  /// Goal kinds offered on question 3 in display order (server
  /// `onboarding.goalKinds`); `custom` = "Khác".
  List<String> get savingKinds => _limits.requireLimits.onboardingGoalKinds;

  /// Longest goal name the server takes ("Khác").
  int get goalNameMaxLength => _limits.requireLimits.goalNameMaxLength;

  /// Profile currency; the first run happens in it. Until the profile loads,
  /// the currency new accounts start in (server).
  String currency = CurrencyCatalog.current.defaultCode;
  int get digits => CurrencyCatalog.current.digits(currency);

  final List<OnboardingGoal> goals = [];

  /// Picked band; null with nothing picked or with [incomeNotShared].
  DeclaredIncome? income;

  /// "Không muốn chia sẻ" is picked.
  bool incomeNotShared = false;

  String? savingKind;

  /// Name typed for "Khác".
  String customName = '';
  BigInt _targetMinor = BigInt.zero;

  /// `YYYY-MM-DD`; null until picked.
  String? savingDate;

  /// Loads the profile currency; keeps the default when it cannot.
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
    // Saved in the board's order, whatever the tap order was.
    final ordered = [
      for (final goal in OnboardingGoal.values)
        if (goals.contains(goal)) goal,
    ];
    await _profile.saveOnboarding(OnboardingAnswers(goals: ordered));
  }

  // Question 2 ---------------------------------------------------------------

  void pickIncome(DeclaredIncome band) {
    income = band;
    incomeNotShared = false;
    notifyListeners();
  }

  void pickNotShared() {
    income = null;
    incomeNotShared = true;
    notifyListeners();
  }

  /// Saves the picked band; "Không muốn chia sẻ" and nothing picked send
  /// nothing.
  Future<void> saveIncome() async {
    final band = income;
    if (band == null) return;
    await _profile.saveOnboarding(OnboardingAnswers(declaredIncome: band));
  }

  /// "Để sau" on question 2 drops the pick.
  void clearIncome() {
    income = null;
    incomeNotShared = false;
    notifyListeners();
  }

  // Question 3 ---------------------------------------------------------------

  BigInt get targetMinor => _targetMinor;

  DateTime get _today => today ?? DateTime.now();

  /// Earliest date the picker allows: tomorrow.
  DateTime get firstDate {
    final now = _today;
    return DateTime(now.year, now.month, now.day + 1);
  }

  bool get isCustom => savingKind == 'custom';

  void pickKind(String kind) {
    savingKind = savingKind == kind ? null : kind;
    notifyListeners();
  }

  void setCustomName(String value) {
    customName = value;
    notifyListeners();
  }

  /// From the "Số tiền" field, already in minor units; null = empty.
  void setTargetMinor(BigInt? value) {
    final next = value != null && value > BigInt.zero ? value : BigInt.zero;
    if (next == _targetMinor) return;
    _targetMinor = next;
    notifyListeners();
  }

  /// [day] is `YYYY-MM-DD` from the calendar sheet; null clears it.
  void pickDate(String? day) {
    savingDate = day;
    notifyListeners();
  }

  /// A goal is kept only with a kind, an amount, a date and, for "Khác", a
  /// name.
  bool get savingReady =>
      savingKind != null &&
      targetMinor > BigInt.zero &&
      savingDate != null &&
      (!isCustom || customName.trim().isNotEmpty);

  /// Keeps the goal until a wallet exists (wallets are added in the app).
  /// [kindLabel] is the kind's label in the user's language, the name of any
  /// kind but "Khác".
  Future<void> keepSavingGoal(String kindLabel) async {
    if (!savingReady) return;
    await _pending.keep(
      clientId: newSyncOpId(),
      kind: savingKind!,
      name: isCustom ? customName.trim() : kindLabel,
      currency: currency,
      targetMinor: targetMinor,
      targetDate: savingDate!,
    );
  }

  /// Skipping question 3 forgets the goal.
  void clearSaving() {
    savingKind = null;
    customName = '';
    _targetMinor = BigInt.zero;
    savingDate = null;
    notifyListeners();
  }
}
