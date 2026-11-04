/// Whole calendar months from [today] to [targetDate] (both `YYYY-MM-DD`),
/// counting a started month as a full one: 2026-11-02 → 2026-12-02 is 1,
/// → 2026-12-03 is 2. A date in the past (or today) gives 0. Same rule as the
/// API, so the new-goal preview matches what the server will return.
int goalMonthsLeft(String today, String targetDate) {
  final t = today.split('-').map(int.parse).toList();
  final g = targetDate.split('-').map(int.parse).toList();
  var months = (g[0] - t[0]) * 12 + (g[1] - t[1]);
  if (g[2] > t[2]) months += 1;
  return months > 0 ? months : 0;
}

/// `ceil((target − current) / months)`; zero when reached; null when there is
/// no future date to divide by.
BigInt? goalRequiredPerMonth(BigInt target, BigInt current, int? months) {
  final left = current >= target ? BigInt.zero : target - current;
  if (left == BigInt.zero) return BigInt.zero;
  if (months == null || months <= 0) return null;
  final divisor = BigInt.from(months);
  return (left + divisor - BigInt.one) ~/ divisor;
}

/// Share of [income] the saving takes, in basis points; null without income.
int? goalIncomeShareBps(BigInt? required, BigInt? income) {
  if (required == null || income == null || income <= BigInt.zero) return null;
  return ((required * BigInt.from(10000)) ~/ income).toInt();
}
