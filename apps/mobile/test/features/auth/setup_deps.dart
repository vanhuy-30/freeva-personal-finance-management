import 'package:dartz/dartz.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_repository.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';

import '../profile/fakes.dart';
import '../settings/fakes.dart';
import 'fakes.dart';

/// Wallet API stand-in: saves what it is given, can be made to fail.
class MemoryWalletRepository implements WalletRepository {
  final saved = <WalletDraft>[];
  AuthFailure? failure;
  @override
  Future<Either<AuthFailure, List<Wallet>>> load() async => right([]);
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
    return right(
      Wallet(
        id: 'w${saved.length}',
        createdAt: DateTime(2026, 10, 23),
        draft: draft,
        balance: draft.initialBalance,
        version: 1,
        sortOrder: saved.length,
        archived: false,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Wallet>> update(
    Wallet wallet, {
    bool? archived,
    int? sortOrder,
  }) async => right(wallet);
  @override
  Future<Either<AuthFailure, List<Wallet>>> reorder(
    List<Wallet> active,
  ) async => right(active);
}

/// What the first-run setup screens take from getIt, with in-memory stores.
class SetupDeps {
  final wallets = MemoryWalletRepository();
  final profiles = MemoryProfiles();
  final preferences = MemoryPreferences();
  final analytics = RecordingAnalytics();
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
      AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
    ),
    deps.analytics,
  );
  await deps.settings.load();
  getIt
    ..registerSingleton<ProfileUseCases>(ProfileUseCases(deps.profiles))
    ..registerSingleton<WalletUseCases>(DefaultWalletUseCases(deps.wallets))
    ..registerSingleton<SettingsUseCases>(cases)
    ..registerSingleton<SettingsViewModel>(deps.settings);
  return deps;
}
