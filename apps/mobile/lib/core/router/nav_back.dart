import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension NavBack on BuildContext {
  /// Back from a pushed screen; falls back to [fallback] after a deep link.
  void popOrGo(String fallback) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}
