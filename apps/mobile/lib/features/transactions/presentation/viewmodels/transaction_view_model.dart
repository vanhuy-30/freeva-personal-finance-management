import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../categories/domain/category_use_cases.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../profile/domain/profile_use_cases.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/domain/wallet_use_cases.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../../sync/domain/sync_item.dart';
import '../../../sync/presentation/viewmodels/sync_view_model.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_rules.dart';
import '../../domain/transaction_use_cases.dart';
import '../transaction_sync.dart';

abstract class TransactionViewModel extends ChangeNotifier {
  List<TransactionBundle> get rows;
  List<Wallet> get wallets;
  List<WalletCurrency> get currencies;
  List<FinanceCategory> get categories;
  List<FinanceCategory> get recentCategories;
  String? get timeZone;
  bool get busy;
  bool get hasMore;
  bool get needsReload;
  bool get deleted;
  TransactionType? get typeFilter;
  AuthFailure? get failure;
  String newClientId();
  String? today();
  String? preferredAccountId();
  String? preferredCategoryId();
  Future<void> load();
  Future<void> loadMore();
  Future<void> showDeleted(bool value);
  Future<void> filterType(TransactionType? type);
  Future<void> search(String text);
  Future<TransactionBundle?> open(String id);
  Future<bool> save(TransactionDraft draft, {TransactionBundle? existing});
  Future<bool> remove(TransactionBundle bundle);
  Future<bool> restore(TransactionBundle bundle);
}

@LazySingleton(as: TransactionViewModel)
class DefaultTransactionViewModel extends TransactionViewModel {
  DefaultTransactionViewModel(
    this._cases,
    this._categoriesUseCases,
    this._wallets,
    this._walletScreen,
    this._profile,
    this._auth,
    this._analytics,
    this._sync,
  ) {
    _stage = _auth.stage;
    _seenApplied = _sync.appliedEpoch;
    _auth.addListener(_authChanged);
    _sync.addListener(_syncChanged);
    if (_stage == AuthStage.unlocked) Future.microtask(load);
  }

  final TransactionUseCases _cases;
  final CategoryUseCases _categoriesUseCases;
  final WalletUseCases _wallets;
  final WalletViewModel _walletScreen;
  final ProfileUseCases _profile;
  final AuthViewModel _auth;
  final AnalyticsService _analytics;
  final SyncViewModel _sync;
  late AuthStage _stage;
  late int _seenApplied;
  bool _pendingSyncReload = false;
  int _epoch = 0;
  int _page = 1;
  int _total = 0;
  String? _search;
  List<TxLeg> _legs = const [];
  List<TxLeg> _recentLegs = const [];
  final Set<String> _tracked = {};

  @override
  List<Wallet> wallets = const [];
  @override
  List<WalletCurrency> currencies = const [];
  @override
  List<FinanceCategory> categories = const [];
  @override
  List<FinanceCategory> recentCategories = const [];
  @override
  String? timeZone;
  @override
  bool busy = false;
  @override
  bool needsReload = false;
  @override
  bool deleted = false;
  @override
  TransactionType? typeFilter;
  @override
  AuthFailure? failure;
  @override
  List<TransactionBundle> get rows => _group(_legs);
  @override
  bool get hasMore => _legs.length < _total;

  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    _epoch++;
    _reset();
    notifyListeners();
    if (_stage == AuthStage.unlocked) load();
  }

  void _syncChanged() {
    if (_sync.appliedEpoch == _seenApplied) return;
    _pendingSyncReload = true;
    _drainSyncReload();
  }

  void _drainSyncReload() {
    if (!_pendingSyncReload || busy || _stage != AuthStage.unlocked) return;
    _pendingSyncReload = false;
    _seenApplied = _sync.appliedEpoch;
    _walletScreen.load();
    load();
  }

  void _reset() {
    wallets = const [];
    currencies = const [];
    categories = const [];
    recentCategories = const [];
    timeZone = null;
    _legs = const [];
    _recentLegs = const [];
    _page = 1;
    _total = 0;
    failure = null;
    busy = false;
    needsReload = false;
    _tracked.clear();
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  bool get _canWrite => !busy && !needsReload && _stage == AuthStage.unlocked;

  @override
  String newClientId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  String? today() {
    final zone = timeZone;
    if (zone == null) return null;
    return calendarDate(DateTime.now(), zone);
  }

  @override
  String? preferredAccountId() =>
      defaultAccountId(wallets: wallets, recentLegs: _recentLegs);

  @override
  String? preferredCategoryId() => defaultCategoryId(recentCategories);

  Future<bool> _references(int epoch) async {
    final profile = await _profile.load();
    if (epoch != _epoch) return false;
    final profileError = profile.fold<AuthFailure?>(
      (error) {
        _fail(error);
        return error;
      },
      (value) {
        timeZone = value.timezone;
        return null;
      },
    );
    if (profileError != null) return false;
    final walletResult = await _wallets.load();
    if (epoch != _epoch) return false;
    if (walletResult.fold<bool>(
      (error) {
        _fail(error);
        return true;
      },
      (value) {
        wallets = value;
        return false;
      },
    )) {
      return false;
    }
    final currencyResult = await _wallets.currencies();
    if (epoch != _epoch) return false;
    if (currencyResult.fold<bool>(
      (error) {
        _fail(error);
        return true;
      },
      (value) {
        currencies = value;
        return false;
      },
    )) {
      return false;
    }
    final categoryResult = await _categoriesUseCases.load();
    if (epoch != _epoch) return false;
    return categoryResult.fold(
      (error) {
        _fail(error);
        return false;
      },
      (value) {
        categories = value.all;
        recentCategories = value.recent;
        return true;
      },
    );
  }

  Future<void> _pageAt(int epoch, {required bool replace}) async {
    final result = await _cases.list(
      TransactionQuery(
        page: replace ? 1 : _page,
        deleted: deleted,
        type: typeFilter,
        search: _search,
      ),
    );
    if (epoch != _epoch) return;
    result.fold(_fail, (value) {
      _legs = List.unmodifiable(
        replace ? value.legs : [..._legs, ...value.legs],
      );
      _total = value.total;
      _page = value.page;
      if (replace && !deleted && typeFilter == null && _search == null) {
        _recentLegs = value.legs;
      }
    });
  }

  @override
  Future<void> load() async {
    if (busy || _stage != AuthStage.unlocked) return;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final ready = await _references(epoch);
    if (epoch != _epoch) return;
    if (ready) await _pageAt(epoch, replace: true);
    if (epoch != _epoch) return;
    busy = false;
    notifyListeners();
  }

  @override
  Future<void> loadMore() async {
    if (!_canWrite || !hasMore) return;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    _page += 1;
    notifyListeners();
    await _pageAt(epoch, replace: false);
    if (epoch != _epoch) return;
    if (failure != null) _page -= 1;
    busy = false;
    notifyListeners();
  }

  @override
  Future<void> showDeleted(bool value) async {
    if (busy) return;
    deleted = value;
    await load();
  }

  @override
  Future<void> filterType(TransactionType? type) async {
    if (busy) return;
    typeFilter = type;
    await load();
  }

  @override
  Future<void> search(String text) async {
    if (busy) return;
    final trimmed = text.trim();
    _search = trimmed.isEmpty ? null : trimmed;
    await load();
  }

  @override
  Future<TransactionBundle?> open(String id) async {
    if (busy || _stage != AuthStage.unlocked) return null;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.read(id);
    if (epoch != _epoch) return null;
    TransactionBundle? bundle;
    result.fold(_fail, (value) => bundle = value);
    busy = false;
    notifyListeners();
    return bundle;
  }

  Future<bool> _afterWrite(
    int epoch,
    Either<AuthFailure, Object> result,
    void Function() track, {
    String? clientId,
    String? serverId,
  }) async {
    if (epoch != _epoch) return false;
    if (result.isRight()) {
      await _sync.acknowledge(clientId: clientId, serverId: serverId);
      if (epoch != _epoch) return false;
    }
    result.fold(_fail, (_) => track());
    needsReload = failure?.code == AuthError.conflict;
    if (result.isRight()) {
      await _walletScreen.load();
      if (epoch != _epoch) return false;
      await _pageAt(epoch, replace: true);
    }
    if (epoch != _epoch) return false;
    busy = false;
    _drainSyncReload();
    notifyListeners();
    return result.isRight();
  }

  bool _offline(Either<AuthFailure, Object> result) =>
      result.fold((error) => error.code == AuthError.network, (_) => false);

  Future<bool> _queue(
    int epoch,
    Future<void> Function() enqueue,
    void Function() track,
  ) async {
    await enqueue();
    if (epoch != _epoch) return false;
    track();
    busy = false;
    _drainSyncReload();
    notifyListeners();
    return true;
  }

  void _trackSave(TransactionDraft draft, TransactionBundle? existing) {
    if (existing == null) {
      if (_tracked.add(draft.clientIds.first)) {
        _analytics.track(
          AnalyticsEvent.transactionCreated(switch (draft.type) {
            TransactionType.income => TransactionAnalyticsType.income,
            TransactionType.expense => TransactionAnalyticsType.expense,
            TransactionType.transfer => TransactionAnalyticsType.transfer,
          }),
        );
      }
    } else {
      _analytics.track(AnalyticsEvent.transactionEdited);
    }
  }

  @override
  Future<bool> save(
    TransactionDraft draft, {
    TransactionBundle? existing,
  }) async {
    if (!_canWrite) return false;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.save(
      draft,
      wallets,
      currencies,
      categories,
      existing: existing,
    );
    if (epoch != _epoch) return false;
    if (_offline(result)) {
      final prepared = prepareTransaction(
        draft,
        wallets,
        currencies,
        categories,
        existing: existing,
      );
      return prepared.fold(
        (_) async {
          _fail(const AuthFailure(AuthError.network));
          busy = false;
          notifyListeners();
          return false;
        },
        (command) => _queue(
          epoch,
          () => _sync.enqueue(
            mutationFromCommand(command, serverId: existing?.id),
          ),
          () => _trackSave(draft, existing),
        ),
      );
    }
    return _afterWrite(
      epoch,
      result,
      () => _trackSave(draft, existing),
      clientId: draft.clientIds.first,
      serverId: existing?.id,
    );
  }

  @override
  Future<bool> remove(TransactionBundle bundle) async {
    if (!_canWrite || bundle.deleted) return false;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.remove(bundle);
    if (epoch != _epoch) return false;
    if (_offline(result)) {
      return _queue(
        epoch,
        () => _sync.enqueue(mutationFromBundle(bundle, SyncAction.delete)),
        () => _analytics.track(AnalyticsEvent.transactionDeleted),
      );
    }
    return _afterWrite(
      epoch,
      result,
      () => _analytics.track(AnalyticsEvent.transactionDeleted),
      clientId: bundle.legs.first.clientId,
      serverId: bundle.id,
    );
  }

  @override
  Future<bool> restore(TransactionBundle bundle) async {
    if (!_canWrite) return false;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.restore(bundle, wallets);
    if (epoch != _epoch) return false;
    if (_offline(result)) {
      return _queue(
        epoch,
        () => _sync.enqueue(mutationFromBundle(bundle, SyncAction.restore)),
        () {},
      );
    }
    return _afterWrite(
      epoch,
      result,
      () {},
      clientId: bundle.legs.first.clientId,
      serverId: bundle.id,
    );
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    _sync.removeListener(_syncChanged);
    super.dispose();
  }
}

List<TransactionBundle> _group(List<TxLeg> legs) {
  final grouped = <String, List<TxLeg>>{};
  final order = <String>[];
  for (final leg in legs) {
    final key = leg.transferGroupId ?? leg.id;
    if (!grouped.containsKey(key)) order.add(key);
    grouped.putIfAbsent(key, () => []).add(leg);
  }
  return [
    for (final key in order)
      TransactionBundle(
        legs: List.unmodifiable(
          [...grouped[key]!]..sort((a, b) {
            final amount = a.amountMinor.compareTo(b.amountMinor);
            return amount != 0 ? amount : a.id.compareTo(b.id);
          }),
        ),
      ),
  ];
}
