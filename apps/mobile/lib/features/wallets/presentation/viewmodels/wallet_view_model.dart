import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../domain/wallet.dart';
import '../../domain/wallet_use_cases.dart';

abstract class WalletViewModel extends ChangeNotifier {
  List<Wallet> get wallets;
  List<WalletCurrency> get currencies;
  bool get busy;
  bool get needsReload;
  AuthFailure? get failure;

  /// Profile currency: the "Tổng số dư" headline.
  String get mainCurrency;

  /// Local date for "còn N ngày" (same clock as Overview).
  DateTime get today;
  List<Wallet> get active => [
    for (final w in wallets)
      if (!w.archived) w,
  ];
  List<Wallet> get hidden => [
    for (final w in wallets)
      if (w.archived) w,
  ];
  Wallet? byId(String id) => wallets.where((w) => w.id == id).firstOrNull;
  WalletCurrency? currencyOf(Wallet wallet) =>
      currencies.where((c) => c.code == wallet.draft.currency).firstOrNull;
  String newClientId();
  Future<void> load();
  Future<bool> save(WalletDraft draft, String clientId, {Wallet? wallet});

  /// Hides an active wallet or restores a hidden one. Undo calls it again
  /// with the returned copy.
  Future<bool> archive(Wallet wallet);

  /// Saves [ordered] (every active wallet) as the new order in one request.
  Future<bool> reorder(List<Wallet> ordered);
}

@LazySingleton(as: WalletViewModel)
class DefaultWalletViewModel extends WalletViewModel {
  DefaultWalletViewModel(
    this._cases,
    this._auth, [
    this._profile,
    @ignoreParam DateTime Function()? clock,
  ]) : _clock = clock ?? DateTime.now {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
    _profile?.addListener(notifyListeners);
  }
  final WalletUseCases _cases;
  final AuthViewModel _auth;
  final ProfileViewModel? _profile;
  final DateTime Function() _clock;
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
  @override
  String get mainCurrency => _profile?.saved?.currency ?? 'VND';
  @override
  DateTime get today => _clock();
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
  Future<bool> archive(Wallet wallet) async {
    if (!_canWrite) return false;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.update(wallet, archived: !wallet.archived);
    if (epoch != _epoch) return false;
    result.fold((e) {
      needsReload = true;
      _fail(e);
    }, _replace);
    if (epoch != _epoch) return false;
    busy = false;
    notifyListeners();
    return result.isRight();
  }

  @override
  Future<bool> reorder(List<Wallet> ordered) async {
    if (!_canWrite) return false;
    if (listEquals(
      [for (final w in active) w.id],
      [for (final w in ordered) w.id],
    )) {
      return true;
    }
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.reorder(ordered);
    if (epoch != _epoch) return false;
    result.fold((e) {
      needsReload = e.code == AuthError.conflict;
      _fail(e);
    }, (saved) => wallets = List.unmodifiable([...saved, ...hidden]));
    busy = false;
    notifyListeners();
    return result.isRight();
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    _profile?.removeListener(notifyListeners);
    super.dispose();
  }
}
