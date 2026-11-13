import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/time/calendar_date.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_filter.dart';
import '../../../transactions/domain/transaction_use_cases.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/domain/wallet_use_cases.dart';
import '../../domain/export_period.dart';
import '../../domain/profile_use_cases.dart';
import '../../domain/transactions_csv_export_use_case.dart';
import 'profile_view_model.dart';
import '../../../server_config/domain/app_limits.dart';

/// Which file the user is exporting (board `DataExport`).
enum ExportKind { table, fullCopy }

/// `MOB-P3-010`: Xuất dữ liệu. A filtered transactions CSV, or the full JSON
/// copy that `ProfileViewModel.exportData` already produces.
abstract class DataExportViewModel extends ChangeNotifier {
  ExportKind get kind;
  ExportPeriod get period;
  DateRange? get custom;
  Set<String> get accountIds;
  List<Wallet> get wallets;

  /// Range the CSV covers; null means every day.
  DateRange? get range;

  /// Rows the CSV would have; null while unknown or loading.
  int? get count;
  bool get loading;
  bool get exporting;
  AuthFailure? get failure;

  /// Above server `export.csvMaxRows`: the user has to narrow the range.
  bool get tooMany;
  bool get canExport;

  Future<void> load();
  void selectKind(ExportKind kind);
  void selectPeriod(ExportPeriod period, {DateRange? custom});
  void selectWallets(Set<String> ids);

  /// True when a file was shared; false on failure or a dismissed sheet.
  Future<bool> export({String? password});
}

@injectable
class DefaultDataExportViewModel extends DataExportViewModel {
  DefaultDataExportViewModel(
    this._profileUseCases,
    this._wallets,
    this._transactions,
    this._csv,
    this._profile,
    this._auth,
    this._limits,
  );

  /// Server limits (MOB-P5-001).
  final AppLimitsSource _limits;
  final ProfileUseCases _profileUseCases;
  final WalletUseCases _wallets;
  final TransactionUseCases _transactions;
  final TransactionsCsvExportUseCase _csv;
  final ProfileViewModel _profile;
  final AuthViewModel _auth;

  int _epoch = 0;
  int _countEpoch = 0;
  bool _disposed = false;
  String _today = '';
  int _fiscalDay = 1;

  @override
  ExportKind kind = ExportKind.table;
  @override
  ExportPeriod period = ExportPeriod.thisMonth;
  @override
  DateRange? custom;
  @override
  Set<String> accountIds = const {};
  @override
  List<Wallet> wallets = const [];
  @override
  int? count;
  @override
  bool loading = false;
  @override
  bool exporting = false;
  @override
  AuthFailure? failure;

  @override
  DateRange? get range => exportRange(period, _today, _fiscalDay, custom);

  @override
  bool get tooMany =>
      count != null && count! > _limits.requireLimits.exportCsvMaxRows;

  @override
  bool get canExport {
    if (exporting || loading) return false;
    if (kind == ExportKind.fullCopy) return true;
    if (period == ExportPeriod.custom && custom == null) return false;
    return count != 0 && !tooMany;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  @override
  Future<void> load() async {
    final epoch = ++_epoch;
    loading = true;
    failure = null;
    _notify();
    final profile = await _profileUseCases.load();
    final walletResult = await _wallets.load();
    if (epoch != _epoch) return;
    profile.fold(_fail, (value) {
      _fiscalDay = value.fiscalDay;
      final now = DateTime.now();
      _today =
          calendarDate(now, value.timezone) ??
          now.toIso8601String().substring(0, 10);
    });
    walletResult.fold(_fail, (value) => wallets = value);
    loading = false;
    _notify();
    if (failure == null) await _refreshCount();
  }

  Future<void> _refreshCount() async {
    if (_today.isEmpty) return;
    if (period == ExportPeriod.custom && custom == null) {
      count = null;
      _notify();
      return;
    }
    final epoch = ++_countEpoch;
    count = null;
    _notify();
    final range = this.range;
    final result = await _transactions.list(
      TransactionQuery(
        pageSize: 1,
        from: range?.from,
        to: range?.to,
        accountIds: accountIds.toList()..sort(),
      ),
    );
    if (epoch != _countEpoch) return;
    result.fold(_fail, (page) => count = page.total);
    _notify();
  }

  @override
  void selectKind(ExportKind next) {
    if (kind == next) return;
    kind = next;
    _notify();
  }

  @override
  void selectPeriod(ExportPeriod next, {DateRange? custom}) {
    period = next;
    this.custom = next == ExportPeriod.custom ? custom : null;
    failure = null;
    _notify();
    _refreshCount();
  }

  @override
  void selectWallets(Set<String> ids) {
    accountIds = ids;
    failure = null;
    _notify();
    _refreshCount();
  }

  @override
  Future<bool> export({String? password}) async {
    if (!canExport) return false;
    final epoch = _epoch;
    exporting = true;
    failure = null;
    _notify();
    var shared = false;
    if (kind == ExportKind.fullCopy) {
      shared = await _profile.exportData(password: password);
      if (_profile.failure != null) failure = _profile.failure;
    } else {
      final result = await _csv(
        now: DateTime.now(),
        range: range,
        accountIds: accountIds,
      );
      result.fold(_fail, (value) => shared = value);
    }
    if (epoch != _epoch) return false;
    exporting = false;
    _notify();
    return shared;
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _countEpoch++;
    super.dispose();
  }
}
