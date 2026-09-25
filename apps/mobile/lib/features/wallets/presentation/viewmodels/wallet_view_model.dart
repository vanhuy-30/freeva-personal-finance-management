import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/wallet.dart';
import '../../domain/wallet_use_cases.dart';

abstract class WalletViewModel extends ChangeNotifier {
  List<Wallet> get wallets;
  List<WalletCurrency> get currencies;
  bool get busy;
  bool get needsReload;
  AuthFailure? get failure;
  String newClientId();
  Future<void> load();
  Future<bool> save(WalletDraft draft, String clientId, {Wallet? wallet});
  Future<void> archive(Wallet wallet);
  Future<void> move(Wallet wallet, int offset);
}

@LazySingleton(as: WalletViewModel)
class DefaultWalletViewModel extends WalletViewModel {
  DefaultWalletViewModel(this._cases, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }
  final WalletUseCases _cases;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _epoch = 0;
  @override
  List<Wallet> wallets = const [];
  @override
  List<WalletCurrency> currencies = const [];
  @override
  bool busy = false;
  @override
  bool needsReload = false;
  @override
  AuthFailure? failure;
  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    _epoch++;
    wallets = const [];
    currencies = const [];
    failure = null;
    busy = false;
    needsReload = false;
    notifyListeners();
    if (_stage == AuthStage.unlocked) load();
  }

  void _fail(AuthFailure e) {
    failure = e;
    if (e.code == AuthError.expired) _auth.sessionExpired();
  }

  @override
  String newClientId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  @override
  Future<void> load() async {
    if (busy || _stage != AuthStage.unlocked) return;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.load();
    if (epoch != _epoch) return;
    result.fold(_fail, (v) {
      wallets = v;
      needsReload = false;
    });
    if (epoch != _epoch) return;
    if (failure == null) {
      final options = await _cases.currencies();
      if (epoch != _epoch) return;
      options.fold(_fail, (v) => currencies = v);
    }
    if (epoch != _epoch) return;
    busy = false;
    notifyListeners();
  }

  bool get _canWrite => !busy && !needsReload && _stage == AuthStage.unlocked;
  void _replace(Wallet value) {
    final items = [...wallets];
    final index = items.indexWhere((w) => w.id == value.id);
    if (index < 0) {
      items.add(value);
    } else {
      items[index] = value;
    }
    items.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      final created = a.createdAt.compareTo(b.createdAt);
      return created != 0 ? created : a.id.compareTo(b.id);
    });
    wallets = List.unmodifiable(items);
  }

  @override
  Future<bool> save(
    WalletDraft draft,
    String clientId, {
    Wallet? wallet,
  }) async {
    if (!_canWrite) return false;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.save(
      draft,
      currencies,
      wallet: wallet,
      clientId: clientId,
    );
    if (epoch != _epoch) return false;
    result.fold(_fail, _replace);
    if (epoch != _epoch) return false;
    needsReload = failure?.code == AuthError.conflict;
    busy = false;
    notifyListeners();
    return result.isRight();
  }

  @override
  Future<void> archive(Wallet wallet) async {
    if (!_canWrite) return;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.update(wallet, archived: !wallet.archived);
    if (epoch != _epoch) return;
    result.fold((e) {
      needsReload = true;
      _fail(e);
    }, _replace);
    if (epoch != _epoch) return;
    busy = false;
    notifyListeners();
  }

  @override
  Future<void> move(Wallet wallet, int offset) async {
    if (!_canWrite || wallet.archived) return;
    final ordered = wallets.where((w) => !w.archived).toList();
    final index = ordered.indexWhere((w) => w.id == wallet.id);
    final target = index + offset;
    if (index < 0 || target < 0 || target >= ordered.length) return;
    ordered.insert(target, ordered.removeAt(index));
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    // API has no atomic reorder. Preserve each returned version; stop on any
    // failure and require a reload before another mutation.
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].sortOrder == i) continue;
      final result = await _cases.update(ordered[i], sortOrder: i);
      if (epoch != _epoch) return;
      result.fold((e) {
        needsReload = true;
        _fail(e);
      }, _replace);
      if (epoch != _epoch) return;
      if (result.isLeft()) break;
    }
    if (failure == null) {
      final byId = {for (final w in wallets) w.id: w};
      wallets = List.unmodifiable([
        ...ordered.map((w) => byId[w.id]!),
        ...wallets.where((w) => w.archived),
      ]);
    }
    busy = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
