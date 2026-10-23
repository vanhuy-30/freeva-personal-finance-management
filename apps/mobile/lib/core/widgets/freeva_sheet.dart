import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Bottom sheet: radius 28, drag handle, ink scrim. For quick picks (wallet,
/// category, date) and quick views (transaction detail).
Future<T?> showFreevaSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  String? subtitle,
  bool scrollable = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollable,
    useSafeArea: true,
    builder: (context) => FreevaSheetBody(
      title: title,
      subtitle: subtitle,
      child: builder(context),
    ),
  );
}

class FreevaSheetBody extends StatelessWidget {
  const FreevaSheetBody({
    required this.child,
    this.title,
    this.subtitle,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final margin = context.screenMargin;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        margin,
        0,
        margin,
        FreevaSpace.s6 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Semantics(
              header: true,
              child: Text(
                title!,
                style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: FreevaTypography.bodyS.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: FreevaSpace.s3),
          ],
          Flexible(child: child),
        ],
      ),
    );
  }
}
