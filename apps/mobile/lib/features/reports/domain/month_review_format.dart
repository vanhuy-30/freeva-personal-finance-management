/// Formats [savingsRateBps] for display (3933 → `39.33%` or `39,33%`).
/// Uses integer math only; [locale] picks the decimal separator.
String formatSavingsRateBps(int bps, String locale) {
  final negative = bps < 0;
  final abs = bps.abs();
  final whole = abs ~/ 100;
  final frac = abs % 100;
  final sep = locale.toLowerCase().startsWith('vi') ? ',' : '.';
  final body = frac == 0
      ? '$whole%'
      : '$whole$sep${frac.toString().padLeft(2, '0')}%';
  return negative ? '−$body' : body;
}
