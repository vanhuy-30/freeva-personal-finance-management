class SessionNoticeDecision {
  const SessionNoticeDecision({required this.alert, required this.seenIds});

  final bool alert;
  final List<String> seenIds;
}

SessionNoticeDecision decideSessionNotice({
  required List<String> seenIds,
  required List<({String id, bool current})> sessions,
}) {
  final active = [for (final session in sessions) session.id];
  if (seenIds.isEmpty) {
    return SessionNoticeDecision(alert: false, seenIds: active);
  }
  final known = seenIds.toSet();
  final alert = sessions.any(
    (session) => !session.current && !known.contains(session.id),
  );
  return SessionNoticeDecision(alert: alert, seenIds: active);
}
