import 'package:dartz/dartz.dart';

import '../../support/server_config_fixture.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/goals/domain/goal.dart';
import 'package:mobile/features/goals/domain/goal_forecast.dart';
import 'package:mobile/features/goals/domain/goal_use_cases.dart';
import 'package:mobile/features/goals/presentation/viewmodels/goal_forecast_view_model.dart';
import 'package:mobile/features/goals/presentation/viewmodels/goal_view_model.dart';
import 'package:mobile/features/server_config/domain/server_config.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';

import '../auth/fakes.dart';
import '../auto_suggest/auto_suggest_fakes.dart' show FakeFlags;
import '../home/fixtures.dart' show b, wallet;
import '../profile/fakes.dart';
import '../wallets/d1_stub.dart' show StubWalletViewModel;

/// A goal like the I artboards. Percent and remaining follow from the amounts.
Goal goal({
  String id = 'home',
  String kind = 'home',
  String name = 'Mua nhà',
  int target = 120000000,
  int current = 40000000,
  String? targetDate,
  int? monthsLeft,
  int? perMonth,
  GoalStatus status = GoalStatus.active,
  String accountId = 'vcb',
  bool archived = false,
  int? incomeShareBps,
  DateTime? updatedAt,
}) => Goal(
  id: id,
  clientId: 'client-$id',
  kind: kind,
  name: name,
  currencyCode: 'VND',
  targetMinor: b(target),
  currentMinor: b(current),
  remainingMinor: b(current >= target ? 0 : target - current),
  percentBps: current * 10000 ~/ target,
  status: status,
  accountId: accountId,
  icon: 'housing',
  targetDate: targetDate,
  monthsLeft: monthsLeft,
  requiredPerMonthMinor: perMonth == null ? null : b(perMonth),
  incomeShareBps: incomeShareBps,
  archived: archived,
  version: 1,
  updatedAt: updatedAt ?? DateTime.utc(2026, 9, 12),
);

/// The three goals of GoalList: on track, overdue, reached.
List<Goal> canvasGoals() => [
  goal(
    targetDate: '2027-08-21',
    monthsLeft: 10,
    perMonth: 8000000,
    incomeShareBps: 3200,
  ),
  goal(
    id: 'trip',
    kind: 'travel',
    name: 'Du lịch Đà Nẵng',
    target: 15000000,
    current: 12000000,
    targetDate: '2026-09-30',
    status: GoalStatus.overdue,
    monthsLeft: 0,
  ),
  goal(
    id: 'fund',
    kind: 'emergency',
    name: 'Quỹ khẩn cấp',
    target: 20000000,
    current: 20000000,
    status: GoalStatus.reached,
    perMonth: 0,
    updatedAt: DateTime.utc(2026, 9, 12),
  ),
];

List<GoalEntry> canvasEntries() => [
  GoalEntry(
    id: 'e1',
    kind: GoalEntryKind.contribute,
    amountMinor: b(5000000),
    transfer: true,
    occurredOn: '2026-10-01',
  ),
  GoalEntry(
    id: 'e2',
    kind: GoalEntryKind.contribute,
    amountMinor: b(5000000),
    transfer: false,
    occurredOn: '2026-09-01',
  ),
  const GoalEntry(
    id: 'e3',
    kind: GoalEntryKind.adjust,
    transfer: false,
    occurredOn: '2026-08-15',
  ),
];

/// Wallets of the GoalAdd and GoalMove artboards.
List<Wallet> goalWallets() => [
  wallet('vcb', 'Vietcombank', balance: 17288000),
  wallet('cash', 'Tiền mặt', type: WalletType.cash, balance: 12300000),
  wallet('momo', 'MoMo', type: WalletType.ewallet, balance: 2150000),
];

class FakeGoalUseCases implements GoalUseCases {
  FakeGoalUseCases({List<Goal>? goals, List<GoalEntry>? entries})
    : goals = goals ?? canvasGoals(),
      entries_ = entries ?? canvasEntries();

  List<Goal> goals;
  List<GoalEntry> entries_;
  AuthFailure? failure;
  final created = <GoalDraft>[];
  final moves = <(String, GoalMove)>[];
  final adjusted = <BigInt>[];
  final archivedIds = <String>[];

  Either<AuthFailure, T> _ok<T>(T value) =>
      failure == null ? right(value) : left(failure!);

  @override
  Future<Either<AuthFailure, List<Goal>>> list({
    bool includeArchived = false,
  }) async => _ok([
    for (final g in goals)
      if (includeArchived || !g.archived) g,
  ]);

  @override
  Future<Either<AuthFailure, Goal>> find(String id) async =>
      _ok(goals.firstWhere((g) => g.id == id));

  @override
  Future<Either<AuthFailure, Goal>> create(GoalDraft draft) async {
    created.add(draft);
    return _ok(
      goal(
        id: 'new',
        kind: draft.kind,
        name: draft.name,
        target: draft.targetMinor.toInt(),
        current: (draft.currentMinor ?? BigInt.zero).toInt(),
        accountId: draft.accountId,
        targetDate: draft.targetDate,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Goal>> update(
    Goal g, {
    String? kind,
    String? name,
    BigInt? targetMinor,
    String? targetDate,
    bool clearTargetDate = false,
    String? icon,
    String? colorToken,
  }) async => _ok(
    goal(
      id: g.id,
      kind: kind ?? g.kind,
      name: name ?? g.name,
      target: (targetMinor ?? g.targetMinor).toInt(),
      current: g.currentMinor.toInt(),
      accountId: g.accountId,
    ),
  );

  @override
  Future<Either<AuthFailure, Unit>> archive(Goal g) async {
    archivedIds.add(g.id);
    return _ok(unit);
  }

  @override
  Future<Either<AuthFailure, Goal>> contribute(Goal g, GoalMove move) async {
    moves.add(('in', move));
    return _ok(
      goal(
        id: g.id,
        name: g.name,
        target: g.targetMinor.toInt(),
        current: (g.currentMinor + move.amountMinor).toInt(),
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Goal>> withdraw(Goal g, GoalMove move) async {
    moves.add(('out', move));
    return _ok(
      goal(
        id: g.id,
        name: g.name,
        target: g.targetMinor.toInt(),
        current: (g.currentMinor - move.amountMinor).toInt(),
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Goal>> adjust(Goal g, BigInt currentMinor) async {
    adjusted.add(currentMinor);
    return _ok(
      goal(
        id: g.id,
        name: g.name,
        target: g.targetMinor.toInt(),
        current: currentMinor.toInt(),
      ),
    );
  }

  @override
  Future<Either<AuthFailure, List<GoalEntry>>> entries(String id) async =>
      _ok(entries_);

  @override
  Future<Either<AuthFailure, List<GoalPreset>>> presets() async =>
      _ok(const []);

  /// What [preview] answers; the default is the A3 board example.
  GoalPreview previewResult = GoalPreview(
    monthsLeft: 10,
    requiredPerMonthMinor: BigInt.from(6000000),
    incomeShareBps: 2400,
  );
  final previews = <(String, BigInt, String)>[];

  @override
  Future<Either<AuthFailure, GoalPreview>> preview({
    required String currency,
    required BigInt targetMinor,
    required String targetDate,
  }) async {
    previews.add((currency, targetMinor, targetDate));
    return _ok(previewResult);
  }

  /// What [forecast] answers; null (no card) by default.
  GoalForecast? forecastResult;
  AuthFailure? forecastFailure;
  final forecastCalls = <String>[];

  @override
  Future<Either<AuthFailure, GoalForecast?>> forecast(String id) async {
    forecastCalls.add(id);
    return forecastFailure == null
        ? right(forecastResult)
        : left(forecastFailure!);
  }
}

class GoalHarness {
  GoalHarness._(this.cases, this.model, this.flags, this.app);
  final FakeGoalUseCases cases;
  final GoalViewModel model;

  /// `forecast` is on.
  final FakeFlags flags;
  final Widget app;
}

/// [page] over a real [GoalViewModel] fed by [FakeGoalUseCases], stub wallets
/// and a profile with the given monthly income.
Future<GoalHarness> goalsApp(
  Widget page, {
  List<Goal>? goals,
  List<GoalEntry>? entries,
  List<String> profileGoals = const ['save'],
  BigInt? income,
  bool dark = false,
  double scale = 1,
  GoalForecast? forecast,
  DateTime? today,
}) async {
  await getIt.reset();
  registerTestServerConfig();
  final auth =
      DefaultAuthViewModel(
          DefaultAuthUseCases(
            AuthRepositoryImpl(
              FakeApi(),
              MemoryVault(),
              FakeBiometrics(),
              testServerConfigModel(),
            ),
            testServerConfigModel(),
          ),
        )
        ..stage = AuthStage.unlocked
        ..hasPin = true
        ..ready = true;
  final profiles = MemoryProfiles()
    ..value = Profile(
      locale: 'vi',
      currency: 'VND',
      timezone: 'Asia/Ho_Chi_Minh',
      fiscalDay: 1,
      version: 1,
      displayName: 'Minh',
      goals: profileGoals,
      monthlyIncomeMinor: income,
    );
  final profile = DefaultProfileViewModel(
    ProfileUseCases(profiles, testServerConfigModel()),
    auth,
    exportCase(
      AuthRepositoryImpl(
        FakeApi(),
        MemoryVault(),
        FakeBiometrics(),
        testServerConfigModel(),
      ),
    ),
  );
  await profile.load();
  final wallets = StubWalletViewModel(wallets: goalWallets(), today: today);
  final cases = FakeGoalUseCases(goals: goals, entries: entries)
    ..forecastResult = forecast;
  final model = GoalViewModel(cases, wallets, profile, auth);
  final flags = FakeFlags()..on = {FeatureFlags.forecast};
  getIt
    ..registerSingleton<AuthViewModel>(auth)
    ..registerSingleton<WalletViewModel>(wallets)
    ..registerSingleton<ProfileViewModel>(profile)
    ..registerSingleton<GoalViewModel>(model)
    ..registerFactory<GoalForecastViewModel>(
      () => GoalForecastViewModel(cases, flags, auth),
    );
  Widget scaled(Widget child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: child,
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => scaled(page)),
      for (final path in const [
        '/me',
        '/me/goals',
        '/me/goals/new',
        '/me/goals/:id',
      ])
        GoRoute(path: path, builder: (context, state) => const SizedBox()),
    ],
  );
  final app = MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    routerConfig: router,
  );
  return GoalHarness._(cases, model, flags, app);
}
