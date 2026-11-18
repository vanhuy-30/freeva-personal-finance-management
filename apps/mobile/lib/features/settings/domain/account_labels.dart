/// "minh@gmail.com" → "m•••@gmail.com". Only the first letter of the part
/// before @ stays; anything that is not an address comes back as it is.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at < 1) return email;
  return '${email.substring(0, 1)}•••${email.substring(at)}';
}

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
