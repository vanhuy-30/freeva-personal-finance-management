/// A link from an auth email that the app can act on.
sealed class AuthLink {
  const AuthLink();
}

/// Opens the new-password screen for [token] (the reset email).
final class ResetPasswordLink extends AuthLink {
  const ResetPasswordLink(this.token);

  /// 64 lower-case hex characters, single use, valid for 30 minutes.
  final String token;
}

/// A link meant for the app whose token is missing or malformed.
final class InvalidAuthLink extends AuthLink {
  const InvalidAuthLink();
}

/// Turns a URI the OS handed to the app into an [AuthLink].
///
/// Accepts `freeva://reset-password?token=…` (the custom scheme the email
/// page opens) and `https://<host>/reset-password` with the token in the query
/// or the fragment (what a Universal Link / App Link will deliver once the
/// freeva domain exists). Verification links are not handled here: the web
/// page confirms the email by itself.
abstract final class AuthLinkParser {
  static const scheme = 'freeva';
  static const resetSegment = 'reset-password';
  static final _token = RegExp(r'^[a-f0-9]{64}$');

  /// The link for [uri], or null when it is not a link this app handles.
  static AuthLink? parse(Uri uri) {
    if (_segment(uri) != resetSegment) return null;
    final raw = _rawToken(uri)?.trim().toLowerCase();
    if (raw == null || !_token.hasMatch(raw)) return const InvalidAuthLink();
    return ResetPasswordLink(raw);
  }

  /// `freeva://reset-password` carries the segment in the host; an https link
  /// carries it as the only path segment.
  static String? _segment(Uri uri) {
    final lower = uri.scheme.toLowerCase();
    if (lower != scheme && lower != 'https') return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (lower == scheme && uri.host.isNotEmpty) {
      return segments.isEmpty ? uri.host.toLowerCase() : null;
    }
    return segments.length == 1 ? segments.single.toLowerCase() : null;
  }

  static String? _rawToken(Uri uri) {
    final fromQuery = uri.queryParameters['token'];
    if (fromQuery != null) return fromQuery;
    if (uri.fragment.isEmpty) return null;
    try {
      return Uri.splitQueryString(uri.fragment)['token'];
    } on FormatException {
      return null;
    }
  }
}
