import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Bottom sheet: radius 28, our own drag handle, ink scrim. For quick picks
/// (wallet, category, date) and quick views (transaction detail).
Future<T?> showFreevaSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  String? subtitle,
  bool scrollable = true,
  double titleGap = FreevaSheetBody.defaultTitleGap,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollable,
    useSafeArea: true,
    // FreevaSheetBody paints the surface and its shadow.
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) => FreevaSheetBody(
      title: title,
      subtitle: subtitle,
      titleGap: titleGap,
      child: builder(context),
    ),
  );
}

/// 36×4 grabber at the top of a sheet.
class FreevaSheetHandle extends StatelessWidget {
  const FreevaSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: context.colors.sheetHandle,
      ),
    ),
  );
}

/// Sheet surface and layout: 10 top, handle, 14, title (+ subtitle), [titleGap],
/// content, 28 + safe area at the bottom.
class FreevaSheetBody extends StatelessWidget {
  const FreevaSheetBody({
    required this.child,
    this.title,
    this.subtitle,
    this.titleGap = defaultTitleGap,
    super.key,
  });

  /// Title → content gap on most sheets (CatParent).
  static const double defaultTitleGap = 14;

  final Widget child;
  final String? title;
  final String? subtitle;

  /// Space between the title block and the content: 14, 16 (TxCategory,
  /// MeTheme) or 20 (TxFilter).
  final double titleGap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final margin = context.screenMargin;
    const radius = BorderRadius.vertical(
      top: Radius.circular(FreevaRadius.sheet),
    );
    // The shadow sits behind a Material so list tiles in the sheet keep
    // their ink.
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: FreevaElevation.sheet,
      ),
      child: Material(
        color: c.sheetBg,
        shape: const RoundedRectangleBorder(borderRadius: radius),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            margin,
            10,
            margin,
            28 +
                MediaQuery.paddingOf(context).bottom +
                MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FreevaSheetHandle(),
              const SizedBox(height: 14),
              if (title != null) ...[
                Semantics(
                  header: true,
                  child: Text(
                    title!,
                    style: FreevaTypography.titleL.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: FreevaSpace.s1),
                    child: Text(
                      subtitle!,
                      style: FreevaTypography.bodyM.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                SizedBox(height: titleGap),
              ],
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
