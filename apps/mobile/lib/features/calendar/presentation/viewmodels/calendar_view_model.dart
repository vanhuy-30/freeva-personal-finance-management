import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/calendar_month.dart';
import '../../domain/calendar_use_cases.dart';

@LazySingleton()
class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel(this._cases, this._auth);

  final CalendarUseCases _cases;
  final AuthViewModel _auth;

  CalendarMonth? month;
  String selectedMonth = _currentMonth();
  bool loading = false;
  bool loaded = false;
  AuthFailure? failure;
  bool _disposed = false;

  static String _currentMonth() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    return '${now.year}-$m';
  }

  Future<void> load([String? value]) async {
    if (loading) return;
    final target = value ?? selectedMonth;
    loading = true;
    failure = null;
    selectedMonth = target;
    notifyListeners();
    final result = await _cases.month(target);
    result.fold(_fail, (data) {
      month = data;
      loaded = true;
    });
    loading = false;
    _notify();
  }

  Future<void> shiftMonth(int delta) async {
    final parts = selectedMonth.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);
    final next = DateTime(year, monthNum + delta, 1);
    final m = next.month.toString().padLeft(2, '0');
    await load('${next.year}-$m');
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
