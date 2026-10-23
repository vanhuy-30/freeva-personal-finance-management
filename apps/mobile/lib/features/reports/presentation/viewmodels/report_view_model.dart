import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../domain/report.dart';
import '../../domain/report_period.dart';
import '../../domain/report_summary.dart';
import '../../domain/report_use_cases.dart';

abstract class ReportViewModel extends ChangeNotifier {
  ReportPeriodKind get kind;
  NamedCashflow? get data;

  /// Totals of the period before [data]; null while loading or when missing.
  CashflowReport? get previous;
  TrendReport? get trend;
  ReportPeriodKind get trendKind;
  bool get trendFailed;
  bool get busy;
  AuthFailure? get failure;
  bool get canStep;

  /// Later periods are locked once the viewed one reaches today.
  bool get canStepNext;
  bool get atCurrent;
  List<String> get currencies;
  String? get currency;
  ReportSummary? get summary;
  String get today;
  void beginVisit();
  Future<void> load(ReportPeriodQuery query);
  Future<void> reload();
  Future<void> select(ReportPeriodKind kind);
  Future<void> backToCurrent();
  Future<void> step(int direction);
  void selectCurrency(String code);
  Future<void> selectTrend(ReportPeriodKind kind);
  Future<void> applyRange(String from, String to);
}

@LazySingleton(as: ReportViewModel)
class DefaultReportViewModel extends ReportViewModel {
  DefaultReportViewModel(
    this._cases,
    this._auth,
    this._analytics,
    this._profile, {
    @ignoreParam DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final ReportUseCases _cases;
  final AuthViewModel _auth;
  final AnalyticsService _analytics;
  final ProfileViewModel _profile;
  final DateTime Function() _clock;
  late AuthStage _stage;
  int _epoch = 0;
  bool _viewed = false;
  String? _chosenCurrency;
  ReportPeriodQuery _last = const ReportPeriodQuery.month();

  @override
  ReportPeriodKind kind = ReportPeriodKind.month;
  @override
  NamedCashflow? data;
  @override
  CashflowReport? previous;
  @override
  TrendReport? trend;
  @override
  ReportPeriodKind trendKind = ReportPeriodKind.month;
  @override
  bool trendFailed = false;
  @override
  bool busy = false;
  @override
  AuthFailure? failure;

  @override
  String get today => calendarDate(_clock());

  @override
  bool get canStep =>
      !busy &&
      data != null &&
      kind != ReportPeriodKind.range &&
      data!.report.period.kind == kind;

  @override
  bool get atCurrent {
    final period = data?.report.period;
    return period != null && reachesToday(period, today);
  }

  @override
  bool get canStepNext => canStep && !atCurrent;

  @override
  List<String> get currencies =>
      data == null ? const [] : reportCurrencies(data!.report);

  @override
  String? get currency => pickCurrency(
    currencies,
    _chosenCurrency,
    _profile.saved?.currency ?? 'VND',
  );

  @override
  ReportSummary? get summary {
    final code = currency;
    final report = data?.report;
    if (code == null || report == null) return null;
    return reportSummary(report, code, today, previous: previous);
  }

  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    _epoch++;
    _clear();
    busy = false;
    notifyListeners();
    if (_stage == AuthStage.unlocked) {
      kind = ReportPeriodKind.month;
      load(const ReportPeriodQuery.month());
    }
  }

  void _clear() {
    data = null;
    previous = null;
    trend = null;
    trendFailed = false;
    failure = null;
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  @override
  void beginVisit() {
    _epoch++;
    _viewed = false;
    _chosenCurrency = null;
    kind = ReportPeriodKind.month;
    trendKind = ReportPeriodKind.month;
    _clear();
    busy = false;
    notifyListeners();
  }

  @override
  Future<void> load(ReportPeriodQuery query) async {
    if (busy || _stage != AuthStage.unlocked) return;
    final epoch = ++_epoch;
    _last = query;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.loadCashflow(query);
    if (epoch != _epoch) return;
    result.fold(
      (error) {
        _fail(error);
        data = null;
      },
      (value) {
        data = value;
        kind = value.report.period.kind;
        previous = null;
        trend = null;
        trendFailed = false;
        if (_viewed) return;
        _viewed = true;
        _analytics.track(AnalyticsEvent.reportViewed);
      },
    );
    busy = false;
    notifyListeners();
    final period = data?.report.period;
    if (period != null) await _loadExtras(epoch, period);
  }

  /// The comparison and the trend arrive after the totals and never block
  /// them; either one failing only hides its own block.
  Future<void> _loadExtras(int epoch, ReportPeriod period) async {
    final before = _cases.loadPrevious(period);
    final series = _cases.loadTrend(trendKind, on: period.to);
    final previousResult = await before;
    final trendResult = await series;
    if (epoch != _epoch) return;
    previous = previousResult.fold((_) => null, (value) => value);
    trend = trendResult.fold((_) => null, (value) => value);
    trendFailed = trendResult.isLeft();
    notifyListeners();
  }

  @override
  Future<void> reload() => load(_last);

  @override
  Future<void> select(ReportPeriodKind next) async {
    if (busy || _stage != AuthStage.unlocked) return;
    // A custom range comes from the popup through [applyRange].
    if (next == ReportPeriodKind.range) return;
    kind = next;
    trendKind = next;
    await load(_currentOf(next));
  }

  @override
  Future<void> backToCurrent() =>
      select(kind == ReportPeriodKind.range ? ReportPeriodKind.month : kind);

  @override
  Future<void> step(int direction) async {
    final period = data?.report.period;
    if (!canStep || period == null) return;
    if (direction > 0 && !canStepNext) return;
    final query = adjacentPeriod(period, direction);
    if (query == null) return;
    await load(query);
  }

  @override
  void selectCurrency(String code) {
    if (!currencies.contains(code) || code == currency) return;
    _chosenCurrency = code;
    notifyListeners();
  }

  @override
  Future<void> selectTrend(ReportPeriodKind next) async {
    final period = data?.report.period;
    if (period == null || next == ReportPeriodKind.range) return;
    if (next == trendKind && trend != null) return;
    final epoch = _epoch;
    trendKind = next;
    trend = null;
    trendFailed = false;
    notifyListeners();
    final result = await _cases.loadTrend(next, on: period.to);
    if (epoch != _epoch || trendKind != next) return;
    trend = result.fold((_) => null, (value) => value);
    trendFailed = result.isLeft();
    notifyListeners();
  }

  /// Loads the inclusive range picked in the popup. Ignored while busy.
  @override
  Future<void> applyRange(String from, String to) async {
    if (busy || _stage != AuthStage.unlocked) return;
    await load(ReportPeriodQuery.range(from, to));
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}

ReportPeriodQuery _currentOf(ReportPeriodKind kind) => switch (kind) {
  ReportPeriodKind.week => const ReportPeriodQuery.week(),
  ReportPeriodKind.year => const ReportPeriodQuery.year(),
  _ => const ReportPeriodQuery.month(),
};
