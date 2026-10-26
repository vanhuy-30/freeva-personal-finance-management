import 'package:timezone/timezone.dart' as tz;

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
    if (text.isNotEmpty) return String.fromCharCode(text.runes.first).toUpperCase();
  }
  return '?';
}

/// "GMT+7" or "GMT+5:30" for an IANA zone, or the city when the zone is not in
/// the bundled database.
String gmtLabel(String zone, DateTime now) {
  try {
    final offset = tz.getLocation(zone).timeZone(now.millisecondsSinceEpoch).offset;
    final minutes = offset ~/ 60000;
    final sign = minutes < 0 ? '-' : '+';
    final hours = minutes.abs() ~/ 60;
    final rest = minutes.abs() % 60;
    return 'GMT$sign$hours${rest == 0 ? '' : ':${rest.toString().padLeft(2, '0')}'}';
  } catch (_) {
    return zone.split('/').last.replaceAll('_', ' ');
  }
}
