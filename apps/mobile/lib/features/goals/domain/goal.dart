/// Goal kinds, in the order the picker shows them.
const goalKinds = [
  'emergency',
  'home',
  'car',
  'travel',
  'education',
  'wedding',
  'retirement',
  'custom',
];

enum GoalStatus { active, reached, overdue }

enum GoalEntryKind { contribute, withdraw, adjust }

class Goal {
  const Goal({
    required this.id,
    required this.clientId,
    required this.kind,
    required this.name,
    required this.currencyCode,
    required this.targetMinor,
    required this.currentMinor,
    required this.remainingMinor,
    required this.percentBps,
    required this.status,
    required this.accountId,
    required this.icon,
    required this.version,
    required this.updatedAt,
    this.colorToken,
    this.targetDate,
    this.monthsLeft,
    this.requiredPerMonthMinor,
    this.monthlyContributionMinor,
    this.incomeShareBps,
    this.archived = false,
  });

  final String id;
  final String clientId;
  final String kind;
  final String name;
  final String currencyCode;
  final BigInt targetMinor;
  final BigInt currentMinor;
  final BigInt remainingMinor;

  /// current × 10000 / target, floored; can exceed 10000.
  final int percentBps;
  final GoalStatus status;
  final String accountId;
  final String icon;
  final String? colorToken;
  final String? targetDate;
  final int? monthsLeft;
  final BigInt? requiredPerMonthMinor;
  final BigInt? monthlyContributionMinor;
  final int? incomeShareBps;
  final bool archived;
  final int version;

  /// Last change; for a reached goal this is when it got there, unless it was edited since.
  final DateTime updatedAt;

  /// 0..1 for progress bars.
  double get progress => (percentBps / 10000).clamp(0, 1).toDouble();

  int get percent => percentBps ~/ 100;

  /// This goal after `DELETE`: archived, version bumped by the server.
  Goal asArchived() => Goal(
    id: id,
    clientId: clientId,
    kind: kind,
    name: name,
    currencyCode: currencyCode,
    targetMinor: targetMinor,
    currentMinor: currentMinor,
    remainingMinor: remainingMinor,
    percentBps: percentBps,
    status: status,
    accountId: accountId,
    icon: icon,
    colorToken: colorToken,
    targetDate: targetDate,
    monthsLeft: monthsLeft,
    requiredPerMonthMinor: requiredPerMonthMinor,
    monthlyContributionMinor: monthlyContributionMinor,
    incomeShareBps: incomeShareBps,
    archived: true,
    version: version + 1,
    updatedAt: updatedAt,
  );
}

class GoalDraft {
  const GoalDraft({
    required this.clientId,
    required this.kind,
    required this.name,
    required this.targetMinor,
    required this.accountId,
    this.currentMinor,
    this.targetDate,
    this.icon,
    this.colorToken,
  });

  final String clientId;
  final String kind;
  final String name;
  final BigInt targetMinor;
  final String accountId;
  final BigInt? currentMinor;
  final String? targetDate;
  final String? icon;
  final String? colorToken;
}

class GoalEntry {
  const GoalEntry({
    required this.id,
    required this.kind,
    required this.transfer,
    required this.occurredOn,
    this.amountMinor,
  });

  final String id;
  final GoalEntryKind kind;

  /// Null for [GoalEntryKind.adjust]: only the number was corrected.
  final BigInt? amountMinor;

  /// Money moved between wallets (not just recorded).
  final bool transfer;
  final String occurredOn;
}

class GoalPreset {
  const GoalPreset({
    required this.kind,
    required this.icon,
    required this.colorToken,
  });
  final String kind;
  final String icon;
  final String? colorToken;
}

class GoalMove {
  const GoalMove({
    required this.clientId,
    required this.amountMinor,
    required this.occurredOn,
    this.accountId,
  });
  final String clientId;
  final BigInt amountMinor;
  final String occurredOn;

  /// Source (contribute) or destination (withdraw) wallet; null = only record.
  final String? accountId;
}
