import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/auth_use_cases.dart';
import '../../goals/domain/goal.dart';
import '../../goals/domain/goal_use_cases.dart';
import '../../settings/domain/app_preferences.dart';
import '../../settings/domain/settings_use_cases.dart';
import '../../wallets/domain/wallet.dart';
import '../../wallets/domain/wallet_use_cases.dart';
import 'pending_goal.dart';

/// Keeps the first-run saving goal until a wallet exists, then creates it.
/// Everything here is best effort: a failure leaves the draft for next time.
@injectable
class PendingGoalUseCases {
  PendingGoalUseCases(this._settings, this._goals, this._wallets, this._auth);

  final SettingsUseCases _settings;
  final GoalUseCases _goals;
  final WalletUseCases _wallets;
  final AuthUseCases _auth;

  /// Hash of the signed-in email, so the draft is never created for someone
  /// else who signs in on this device. Null when no account is known.
  Future<String?> _owner() async {
    final email = (await _auth.accountEmail()).fold((_) => null, (e) => e);
    if (email == null || email.isEmpty) return null;
    final hash = await Sha256().hash(utf8.encode(email.trim().toLowerCase()));
    return base64Url.encode(hash.bytes);
  }

  Future<AppPreferences?> _prefs() async =>
      (await _settings.load()).fold((_) => null, (p) => p);

  /// Stores [draft] (its owner is filled in here); replaces any older draft.
  Future<void> keep({
    required String clientId,
    required String kind,
    required String name,
    required String currency,
    required BigInt targetMinor,
    required String targetDate,
  }) async {
    final owner = await _owner();
    final prefs = await _prefs();
    if (owner == null || prefs == null) return;
    final draft = PendingGoal(
      owner: owner,
      clientId: clientId,
      kind: kind,
      name: name,
      currency: currency,
      targetMinor: targetMinor,
      targetDate: targetDate,
    );
    await _settings.save(prefs.copyWith(pendingGoal: draft.toJson()));
  }

  /// Creates the waiting goal in the first wallet that can hold it (savings
  /// kinds first: cash, bank, e-wallet; never a credit card, same currency).
  /// Returns true when a goal was created now.
  Future<bool> flush() async {
    final prefs = await _prefs();
    final raw = prefs?.pendingGoal;
    if (prefs == null || raw == null) return false;
    final draft = PendingGoal.fromJson(raw);
    final owner = await _owner();
    if (draft == null || (owner != null && owner != draft.owner)) {
      await _settings.save(prefs.copyWith(pendingGoal: null));
      return false;
    }
    if (owner == null) return false;
    final wallets = (await _wallets.load()).fold((_) => <Wallet>[], (w) => w);
    final home = wallets
        .where(
          (w) =>
              !w.archived &&
              w.draft.type != WalletType.credit &&
              w.draft.currency == draft.currency,
        )
        .firstOrNull;
    if (home == null) return false;
    final created = await _goals.create(
      GoalDraft(
        clientId: draft.clientId,
        kind: draft.kind,
        name: draft.name,
        targetMinor: draft.targetMinor,
        accountId: home.id,
        targetDate: draft.targetDate,
      ),
    );
    // The server refused the draft itself (say the date has passed): it will
    // never go through, so drop it instead of retrying on every launch.
    final refused = created.fold(
      (e) => e.code == AuthError.invalidInput,
      (_) => false,
    );
    if (created.isLeft() && !refused) return false;
    final latest = await _prefs();
    if (latest != null) {
      await _settings.save(latest.copyWith(pendingGoal: null));
    }
    return !refused;
  }
}
