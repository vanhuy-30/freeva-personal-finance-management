import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../domain/report.dart';
import '../../domain/report_period.dart';
import '../../domain/report_summary.dart';
import '../../domain/report_use_cases.dart';

/// Loads and steps one fiscal-month review. Created per page (not a singleton).
class MonthReviewViewModel extends ChangeNotifier {
  MonthReviewViewModel(
    this._cases,
    this._auth,
    this._profile, {
    String? initialOn,
    DateTime Function()? clock,
  }) : _on = initialOn,
       _clock = clock ?? DateTime.now {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final ReportUseCases _cases;
  final AuthViewModel _auth;
  final ProfileViewModel _profile;
  final DateTime Function() _clock;
  late AuthStage _stage;
  int _epoch = 0;
  String? _on;
  String? _chosenCurrency;

  NamedMonthReview? data;
  bool busy = false;
  AuthFailure? failure;

  String get today => calendarDate(_clock());

  List<String> get currencies => [
    for (final row in data?.report.currencies ?? const []) row.currency,
  ];

  String? get currency => pickCurrency(
    currencies,
    _chosenCurrency,
    _profile.saved?.currency ?? 'VND',
  );

  MonthReviewCurrency? get selected {
    final code = currency;
    if (code == null || data == null) return null;
    return data!.report.currencies
        .where((row) => row.currency == code)
        .firstOrNull;
  }

  bool get atCurrent {
    final period = data?.report.period;
    return period != null && reachesToday(period, today);
  }

  bool get canStep => !busy && data != null;

  bool get canStepNext => canStep && !atCurrent;

  Future<void> load({String? on}) async {
    _on = on ?? _on;
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.loadMonthReview(on: _on);
    if (epoch != _epoch) return;
    result.fold(
      (error) {
        failure = error;
        data = null;
      },
      (named) {
        data = named;
        failure = null;
        if (_chosenCurrency != null &&
            !named.report.currencies.any(
              (row) => row.currency == _chosenCurrency,
            )) {
          _chosenCurrency = null;
        }
      },
    );
    busy = false;
    notifyListeners();
  }

  Future<void> reload() => load(on: _on);

  Future<void> backToCurrent() {
    _on = null;
    return load(on: null);
  }

  Future<void> step(int direction) async {
    final period = data?.report.period;
    if (period == null || !canStep) return;
    if (direction > 0 && !canStepNext) return;
    final next = adjacentPeriod(period, direction);
    if (next == null) return;
    await load(on: next.on);
  }

  void selectCurrency(String code) {
    if (_chosenCurrency == code) return;
    _chosenCurrency = code;
    notifyListeners();
  }

  void _authChanged() {
    if (_auth.stage == _stage) return;
    _stage = _auth.stage;
    data = null;
    failure = null;
    busy = false;
    _chosenCurrency = null;
    _on = null;
    _epoch++;
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
