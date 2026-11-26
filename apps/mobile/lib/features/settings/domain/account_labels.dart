/// First letter of the name (else of the email), upper-cased, for the avatar.
String avatarLetter(String? name, String? email) {
  for (final source in [name, email]) {
    final text = source?.trim() ?? '';
    if (text.isNotEmpty) {
      return String.fromCharCode(text.runes.first).toUpperCase();
    }
  }
  return '?';
}
