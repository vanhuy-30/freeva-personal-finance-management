import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/logging/app_logger.dart';
import 'auth_link.dart';

/// Where the OS delivers links the app was opened with (wrapped so tests can
/// feed links without a platform channel).
abstract class LinkSource {
  /// The link that launched the app, if any.
  Future<Uri?> initialLink();

  /// Links that arrive while the app is running.
  Stream<Uri> get links;
}

/// Holds the latest email link until the UI can act on it.
///
/// A link can arrive before the app is ready (cold start, splash, locked), so
/// it waits here instead of being routed. It is kept in memory only: the token
/// is a short-lived secret and must not be written to disk. A newer link
/// replaces an older one; the same token delivered twice (some platforms
/// replay the launch link on the stream) counts once.
@lazySingleton
class DeepLinkService extends ChangeNotifier {
  DeepLinkService(this._source, this._logger);

  final LinkSource _source;
  final AppLogger _logger;
  StreamSubscription<Uri>? _subscription;
  bool _started = false;
  bool _disposed = false;
  AuthLink? _pending;

  /// The link waiting to be handled, or null.
  AuthLink? get pending => _pending;

  /// Reads the launch link and starts listening. Safe to call more than once;
  /// never throws, because a broken link channel must not stop the app booting.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _subscription = _source.links.listen(
        handle,
        onError: (Object error, StackTrace stack) =>
            _logger.error('deep link stream failed', error, stack),
      );
      final initial = await _source.initialLink();
      if (initial != null) handle(initial);
    } catch (error, stack) {
      _logger.error('deep link start failed', error, stack);
    }
  }

  /// Parses [uri] and, if it is an auth link, makes it the pending one.
  void handle(Uri uri) {
    if (_disposed) return;
    final link = AuthLinkParser.parse(uri);
    if (link == null) return;
    final current = _pending;
    if (link is ResetPasswordLink &&
        current is ResetPasswordLink &&
        current.token == link.token) {
      return;
    }
    // Never log the URI or token (single-use secret).
    _logger.op('auth link received');
    _pending = link;
    notifyListeners();
  }

  /// Drops [link] if it is still the pending one. Returns whether it was.
  bool consume(AuthLink link) {
    if (!identical(_pending, link)) return false;
    _pending = null;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
