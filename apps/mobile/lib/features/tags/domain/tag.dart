class Tag {
  const Tag({
    required this.id,
    required this.clientId,
    required this.name,
    required this.version,
    this.transactionCount = 0,
  });

  final String id;
  final String clientId;
  final String name;
  final int version;

  /// Transactions carrying the tag (list rows only; 0 otherwise).
  final int transactionCount;

  Tag renamed(String name, int version) => Tag(
    id: id,
    clientId: clientId,
    name: name,
    version: version,
    transactionCount: transactionCount,
  );
}
