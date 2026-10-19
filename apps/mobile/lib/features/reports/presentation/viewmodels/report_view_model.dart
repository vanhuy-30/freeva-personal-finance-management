import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/report.dart';
import '../../domain/report_period.dart';
import '../../domain/report_use_cases.dart';

abstract class ReportViewModel extends ChangeNotifier {
  ReportPeriodKind get kind;
  NamedCashflow? get data;
  bool get busy;
  AuthFailure? get failure;
  String? get rangeFrom;
  String? get rangeTo;
  bool get canStep;
  void beginVisit();
  Future<void> load(ReportPeriodQuery query);
  Future<void> reload();
  Future<void> select(ReportPeriodKind kind);
  Future<void> step(int direction);
  void setRangeEdge({String? from, String? to});
  Future<void> applyRange();
}

@LazySingleton(as: ReportViewModel)
class DefaultReportViewModel extends ReportViewModel {
  DefaultReportViewModel(this._cases, this._auth, this._analytics) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final ReportUseCases _cases;
  final AuthViewModel _auth;
  final AnalyticsService _analytics;
  late AuthStage _stage;
  int _epoch = 0;
  bool _viewed = false;

  @override
  ReportPeriodKind kind = ReportPeriodKind.month;
  @override
  NamedCashflow? data;
  @override
  bool busy = false;
  @override
  AuthFailure? failure;
  @override
  String? rangeFrom;
  @override
  String? rangeTo;

  @override
  bool get canStep =>
      !busy &&
      data != null &&
      kind != ReportPeriodKind.range &&
      data!.report.period.kind == kind;

  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    _epoch++;
    data = null;
    failure = null;
    busy = false;
    notifyListeners();
    if (_stage == AuthStage.unlocked) {
      kind = ReportPeriodKind.month;
      load(const ReportPeriodQuery.month());
    }
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  @override
  void beginVisit() {
    _epoch++;
    _viewed = false;
    kind = ReportPeriodKind.month;
    rangeFrom = null;
    rangeTo = null;
    data = null;
    failure = null;
    busy = false;
    notifyListeners();
  }

  @override
  Future<void> load(ReportPeriodQuery query) async {
    if (busy || _stage != AuthStage.unlocked) return;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.loadCashflow(query);
    if (epoch != _epoch) return;
    result.fold(_fail, (value) {
      data = value;
      kind = value.report.period.kind;
      if (_viewed) return;
      _viewed = true;
      _analytics.track(AnalyticsEvent.reportViewed);
    });
    if (epoch != _epoch) return;
    busy = false;
    notifyListeners();
  }

  @override
  Future<void> reload() async {
    final period = data?.report.period;
    if (period != null && period.kind == kind) {
      await load(switch (period.kind) {
        ReportPeriodKind.week => ReportPeriodQuery.week(on: period.from),
        ReportPeriodKind.month => ReportPeriodQuery.month(on: period.from),
        ReportPeriodKind.range => ReportPeriodQuery.range(
          period.from,
          period.to,
        ),
      });
      return;
    }
    if (kind == ReportPeriodKind.range) {
      await applyRange();
      return;
    }
    await load(
      kind == ReportPeriodKind.week
          ? const ReportPeriodQuery.week()
          : const ReportPeriodQuery.month(),
    );
  }

  @override
  Future<void> select(ReportPeriodKind next) async {
    if (busy || _stage != AuthStage.unlocked) return;
    kind = next;
    if (next == ReportPeriodKind.range) {
      data = null;
      failure = null;
      notifyListeners();
      return;
    }
    await load(
      next == ReportPeriodKind.week
          ? const ReportPeriodQuery.week()
          : const ReportPeriodQuery.month(),
    );
  }

  @override
  Future<void> step(int direction) async {
    final period = data?.report.period;
    if (!canStep || period == null) return;
    final query = adjacentPeriod(period, direction);
    if (query == null) return;
    await load(query);
  }

  @override
  void setRangeEdge({String? from, String? to}) {
    if (from != null) rangeFrom = from;
    if (to != null) rangeTo = to;
    notifyListeners();
  }

  @override
  Future<void> applyRange() async {
    final from = rangeFrom;
    final to = rangeTo;
    if (busy || _stage != AuthStage.unlocked) return;
    kind = ReportPeriodKind.range;
    if (from == null || to == null) {
      failure = const AuthFailure(AuthError.invalidInput);
      notifyListeners();
      return;
    }
    await load(ReportPeriodQuery.range(from, to));
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
