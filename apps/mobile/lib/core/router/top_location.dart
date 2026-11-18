import 'package:go_router/go_router.dart';

/// Path of the screen on top, pushed screens included (`/record` over
/// `/home`). `currentConfiguration.uri` leaves out `context.push` routes, so a
/// tab could not tell it was covered and came back (MOB-P6-001).
String? topLocation(GoRouter router) {
  final top = router.routerDelegate.currentConfiguration.lastOrNull;
  return top == null ? null : Uri.parse(top.matchedLocation).path;
}
