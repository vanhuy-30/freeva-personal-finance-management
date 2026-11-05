/// What `POST /financial-accounts/{id}/reconcile` answers: the ledger balance
/// now, the one to reach, and their difference (all minor units, signed).
///
/// A credit card is reconciled against debt, so its [targetMinor] is
/// negative. [adjusted] is true once an adjustment was written.
class ReconcileResult {
  const ReconcileResult({
    required this.currentMinor,
    required this.targetMinor,
    required this.deltaMinor,
    required this.adjusted,
  });

  final BigInt currentMinor;
  final BigInt targetMinor;
  final BigInt deltaMinor;
  final bool adjusted;
}
