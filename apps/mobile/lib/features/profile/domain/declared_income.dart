/// Monthly income the user stated as a band (first-run question 2, Cá nhân),
/// in minor units of the profile currency. Kept apart from actual income,
/// which comes from recorded transactions. [maxMinor] is null for the open
/// top band ("Trên 40 triệu"); an account from before bands has min == max.
class DeclaredIncome {
  DeclaredIncome({required this.minMinor, this.maxMinor, BigInt? midpointMinor})
    : midpointMinor = midpointMinor ?? midpointOf(minMinor, maxMinor);

  final BigInt minMinor;
  final BigInt? maxMinor;

  /// What suggestions use (server rule, mirrored in [midpointOf]).
  final BigInt midpointMinor;

  /// Middle of the band; the open top band counts as a quarter above its
  /// floor (40M+ → 50M).
  static BigInt midpointOf(BigInt min, BigInt? max) => max == null
      ? min * BigInt.from(5) ~/ BigInt.from(4)
      : (min + max) ~/ BigInt.two;

  /// A degenerate band from the time income was an exact amount.
  bool get isExact => maxMinor == minMinor;

  /// Same band as [other], ignoring the midpoint.
  bool sameBand(DeclaredIncome? other) =>
      other != null && other.minMinor == minMinor && other.maxMinor == maxMinor;

  Map<String, dynamic> toJson() => {
    'minMinor': minMinor.toString(),
    'maxMinor': maxMinor?.toString(),
  };

  /// Null when [json] is not a valid band.
  static DeclaredIncome? fromJson(Object? json) {
    if (json is! Map) return null;
    final min = _minor(json['minMinor']);
    final max = json['maxMinor'] == null ? null : _minor(json['maxMinor']);
    if (min == null || (json['maxMinor'] != null && max == null)) return null;
    if (max != null && max < min) return null;
    if (max == null && min <= BigInt.zero) return null;
    return DeclaredIncome(
      minMinor: min,
      maxMinor: max,
      midpointMinor: _minor(json['midpointMinor']),
    );
  }

  static BigInt? _minor(Object? value) {
    if (value is! String || !RegExp(r'^[0-9]{1,18}$').hasMatch(value)) {
      return null;
    }
    return BigInt.parse(value);
  }
}

/// Bands between the configured bounds (server `onboarding.incomeBandsVnd`):
/// [5M, 10M] → under 5M, 5–10M, over 10M. Bounds that are not strictly
/// increasing and positive are dropped.
List<DeclaredIncome> incomeBandsFrom(List<BigInt> bounds) {
  final clean = <BigInt>[];
  for (final b in bounds) {
    if (b > BigInt.zero && (clean.isEmpty || b > clean.last)) clean.add(b);
  }
  if (clean.isEmpty) return const [];
  return [
    DeclaredIncome(minMinor: BigInt.zero, maxMinor: clean.first),
    for (var i = 1; i < clean.length; i++)
      DeclaredIncome(minMinor: clean[i - 1], maxMinor: clean[i]),
    DeclaredIncome(minMinor: clean.last),
  ];
}
