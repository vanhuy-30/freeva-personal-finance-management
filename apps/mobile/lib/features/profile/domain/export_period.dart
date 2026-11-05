import '../../transactions/domain/transaction_filter.dart';

/// Time chips of the data export (board `DataExport`).
enum ExportPeriod { thisMonth, last3Months, thisYear, allTime, custom }

/// Date range of [period], or null for all time (and an unset custom range).
/// Months start on the profile's [fiscalDay]; "3 tháng" is this month and the
/// two before it; "Năm nay" is 1 Jan to today.
DateRange? exportRange(
  ExportPeriod period,
  String today,
  int fiscalDay,
  DateRange? custom,
) {
  final month = rangeFor(PeriodPreset.thisMonth, today, fiscalDay, null)!;
  return switch (period) {
    ExportPeriod.thisMonth => month,
    ExportPeriod.last3Months => DateRange(_monthsBack(month.from, 2), month.to),
    ExportPeriod.thisYear => DateRange('${today.substring(0, 4)}-01-01', today),
    ExportPeriod.allTime => null,
    ExportPeriod.custom => custom,
  };
}

String _monthsBack(String date, int months) {
  final y = int.parse(date.substring(0, 4));
  final m = int.parse(date.substring(5, 7));
  final d = int.parse(date.substring(8, 10));
  final back = DateTime.utc(y, m - months, d);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${back.year.toString().padLeft(4, '0')}-${two(back.month)}-${two(back.day)}';
}
