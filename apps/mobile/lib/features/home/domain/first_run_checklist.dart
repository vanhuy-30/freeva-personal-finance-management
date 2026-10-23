import 'overview.dart';

/// "Bắt đầu nào" on Overview for someone who has not set up yet: create a
/// wallet, record a first expense, and (only while there is no PIN) lock the
/// app. Worked out from real data, never stored.
class FirstRunChecklist {
  const FirstRunChecklist({
    required this.walletDone,
    required this.expenseDone,
    required this.hasPin,
  });

  factory FirstRunChecklist.of(
    OverviewData data, {
    required int pending,
    required bool hasPin,
  }) => FirstRunChecklist(
    walletDone: data.wallets.isNotEmpty,
    // Anything recorded counts, including what still waits to sync.
    expenseDone: data.recent.isNotEmpty || pending > 0,
    hasPin: hasPin,
  );

  final bool walletDone;
  final bool expenseDone;
  final bool hasPin;

  /// The PIN line only shows while the app has no PIN.
  bool get showPin => !hasPin;

  int get total => showPin ? 3 : 2;
  int get done => (walletDone ? 1 : 0) + (expenseDone ? 1 : 0);

  /// Goes away once wallet and first expense are done, even without a PIN, so
  /// someone who chose no PIN is not reminded on every visit (Bảo mật still
  /// offers it).
  bool get visible => !walletDone || !expenseDone;
}
