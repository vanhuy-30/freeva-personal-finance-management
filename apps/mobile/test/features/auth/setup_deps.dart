import 'package:dartz/dartz.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/goals/domain/goal_use_cases.dart';
import 'package:mobile/features/onboarding/domain/pending_goal_use_cases.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/wallets/domain/reconcile_result.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_repository.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';

import '../goals/goal_stub.dart';
import '../profile/fakes.dart';
import '../settings/fakes.dart';
import 'fakes.dart';
import '../../support/server_config_fixture.dart';

/// Wallet API stand-in: saves what it is given, can be made to fail.
class MemoryWalletRepository implements WalletRepository {
  final saved = <WalletDraft>[];
  AuthFailure? failure;
  final created = <Wallet>[];
  @override
  Future<Either<AuthFailure, List<Wallet>>> load() async => right(created);
  @override
  Future<Either<AuthFailure, List<WalletCurrency>>> currencies() async =>
      failure != null
      ? left(failure!)
      : right(const [WalletCurrency('VND', 0), WalletCurrency('USD', 2)]);
  @override
  Future<Either<AuthFailure, Wallet>> save(
    WalletDraft draft, {
    Wallet? wallet,
    required String clientId,
  }) async {
    if (failure != null) return left(failure!);
    saved.add(draft);
    final wallet = Wallet(
      id: 'w${saved.length}',
      createdAt: DateTime(2026, 10, 23),
      draft: draft,
      balance: draft.initialBalance,
      version: 1,
      sortOrder: saved.length,
      archived: false,
    );
    created.add(wallet);
    return right(wallet);
  }

  @override
  Future<Either<AuthFailure, Wallet>> update(
    Wallet wallet, {
    bool? archived,
    int? sortOrder,
  }) async => right(wallet);
  @override
  Future<Either<AuthFailure, ReconcileResult>> reconcile(
    Wallet wallet,
    BigInt actualMinor, {
    required String clientId,
    bool dryRun = false,
  }) => throw UnimplementedError();

  @override
  Future<Either<AuthFailure, List<Wallet>>> reorder(
    List<Wallet> active,
  ) async => right(active);
}

/// Auth use cases that only know the signed-in email (pending goal owner).
class EmailAuth implements AuthUseCases {
  EmailAuth([this.email = 'minh@example.test']);
  String? email;
  @override
  Future<Either<AuthFailure, String?>> accountEmail() async => right(email);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What the first-run setup screens take from getIt, with in-memory stores.
class SetupDeps {
  final wallets = MemoryWalletRepository();
  final profiles = MemoryProfiles();
  final preferences = MemoryPreferences();
  final analytics = RecordingAnalytics();
  final goals = FakeGoalUseCases(goals: []);
  late final DefaultSettingsViewModel settings;
}

/// Registers [SetupDeps] on a clean getIt. The caller keeps `AuthViewModel`.
Future<SetupDeps> registerSetupDeps() async {
  final deps = SetupDeps();
  final cases = DefaultSettingsUseCases(
    SettingsRepositoryImpl(deps.preferences),
  );
  deps.settings = DefaultSettingsViewModel(
    cases,
    DefaultAuthUseCases(
      AuthRepositoryImpl(
        FakeApi(),
        MemoryVault(),
        FakeBiometrics(),
        testServerConfigModel(),
      ),
      testServerConfigModel(),
    ),
    deps.analytics,
  );
  await deps.settings.load();
  final walletCases = DefaultWalletUseCases(
    deps.wallets,
    testServerConfigModel(),
  );
  final auth = EmailAuth();
  getIt
    ..registerSingleton<ProfileUseCases>(
      ProfileUseCases(deps.profiles, testServerConfigModel()),
    )
    ..registerSingleton<WalletUseCases>(walletCases)
    ..registerSingleton<GoalUseCases>(deps.goals)
    ..registerSingleton<PendingGoalUseCases>(
      PendingGoalUseCases(cases, deps.goals, walletCases, auth),
    )
    ..registerSingleton<SettingsUseCases>(cases)
    ..registerSingleton<SettingsViewModel>(deps.settings);
  return deps;
}
