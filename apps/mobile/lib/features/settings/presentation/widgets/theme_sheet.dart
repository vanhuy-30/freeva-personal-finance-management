import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/check_mark.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../domain/app_preferences.dart';
import '../viewmodels/settings_view_model.dart';

/// "Giao diện": three cards with a thumbnail, applied the moment one is picked.
Future<void> showThemeSheet(BuildContext context, SettingsViewModel model) {
  final s = S.of(context);
  return showFreevaSheet<void>(
    context: context,
    title: s.meTheme,
    titleGap: FreevaSpace.s4,
    builder: (context) => ListenableBuilder(
      listenable: model,
      builder: (context, _) => Semantics(
        container: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, option) in [
              (AppThemePreference.light, s.meThemeLight),
              (AppThemePreference.dark, s.meThemeDark),
              (AppThemePreference.system, s.meThemeSystem),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: _ThemeCard(
                  label: option.$2,
                  preference: option.$1,
                  selected: model.theme == option.$1,
                  onTap: () => model.setTheme(option.$1),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.preference,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final AppThemePreference preference;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: FreevaMotion.fast,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              decoration: BoxDecoration(
                color: selected ? c.tintBlue : c.bgSurface,
                borderRadius: BorderRadius.circular(FreevaRadius.lg),
                border: Border.all(
                  color: selected ? c.borderFocus : c.borderDefault,
                  width: selected
                      ? FreevaBorder.selected
                      : FreevaBorder.defaultValue,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Thumbnail(preference),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: FreevaTypography.titleM.copyWith(
                      fontSize: 14,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              PositionedDirectional(
                top: 8,
                end: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.actionPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: CheckMark(color: c.textOnAction),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tiny screen in the colours of the theme: a card, two lines and the
/// bottom bar. "Theo máy" is split down the middle, light on the left.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail(this.preference);

  final AppThemePreference preference;

  @override
  Widget build(BuildContext context) {
    const light = FreevaColors.light;
    const dark = FreevaColors.dark;
    final border = Border.all(color: light.borderDivider);
    final radius = BorderRadius.circular(FreevaRadius.smd);
    Widget screen(FreevaColors p, {bool twoLines = true}) => Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bar(height: 26, radius: 8, color: p.bgWash),
          const SizedBox(height: 6),
          _Bar(height: 10, radius: 4, color: p.borderDefault, widthFactor: .7),
          if (twoLines) ...[
            const SizedBox(height: 6),
            _Bar(
              height: 10,
              radius: 4,
              color: p.borderDefault,
              widthFactor: .5,
            ),
          ],
          const Spacer(),
          _Bar(
            height: 14,
            radius: FreevaRadius.full,
            color: p.navBg,
            shadow: identical(p, light) ? FreevaElevation.segment : null,
          ),
        ],
      ),
    );
    final content = switch (preference) {
      AppThemePreference.light => ColoredBox(
        color: light.bgCanvas,
        child: screen(light),
      ),
      AppThemePreference.dark => ColoredBox(
        color: dark.bgCanvas,
        child: screen(dark),
      ),
      AppThemePreference.system => Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: light.bgCanvas,
            child: screen(light, twoLines: false),
          ),
          ClipRect(
            clipper: const _RightHalf(),
            child: ColoredBox(
              color: dark.bgCanvas,
              child: screen(dark, twoLines: false),
            ),
          ),
        ],
      ),
    };
    return ExcludeSemantics(
      child: Container(
        height: 110,
        clipBehavior: Clip.antiAlias,
        foregroundDecoration: preference == AppThemePreference.dark
            ? null
            : BoxDecoration(border: border, borderRadius: radius),
        decoration: BoxDecoration(borderRadius: radius),
        child: content,
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.radius,
    required this.color,
    this.widthFactor = 1,
    this.shadow,
  });

  final double height;
  final double radius;
  final Color color;
  final double widthFactor;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
    ),
  );
}

class _RightHalf extends CustomClipper<Rect> {
  const _RightHalf();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width / 2, 0, size.width, size.height);

  @override
  bool shouldReclip(_RightHalf oldClipper) => false;
}
