/// Saving goal from first-run question 3, kept on the device until the user
/// has a wallet the goal can sit in (the API needs one). [owner] ties it to
/// the account that answered, so another sign-in on this device never gets it.
class PendingGoal {
  const PendingGoal({
    required this.owner,
    required this.clientId,
    required this.kind,
    required this.name,
    required this.currency,
    required this.targetMinor,
    required this.targetDate,
  });

  final String owner;

  /// Fixed up front, so creating it again after a lost reply is a replay.
  final String clientId;
  final String kind;
  final String name;
  final String currency;
  final BigInt targetMinor;

  /// `YYYY-MM-DD`.
  final String targetDate;

  Map<String, String> toJson() => {
    'owner': owner,
    'clientId': clientId,
    'kind': kind,
    'name': name,
    'currency': currency,
    'targetMinor': targetMinor.toString(),
    'targetDate': targetDate,
  };

  /// Null when [json] is not a well-formed draft.
  static PendingGoal? fromJson(Map<String, String> json) {
    final target = BigInt.tryParse(json['targetMinor'] ?? '');
    final fields = [
      json['owner'],
      json['clientId'],
      json['kind'],
      json['name'],
      json['currency'],
      json['targetDate'],
    ];
    if (target == null ||
        target <= BigInt.zero ||
        fields.any((f) => f == null || f.isEmpty)) {
      return null;
    }
    return PendingGoal(
      owner: json['owner']!,
      clientId: json['clientId']!,
      kind: json['kind']!,
      name: json['name']!,
      currency: json['currency']!,
      targetMinor: target,
      targetDate: json['targetDate']!,
    );
  }
}
