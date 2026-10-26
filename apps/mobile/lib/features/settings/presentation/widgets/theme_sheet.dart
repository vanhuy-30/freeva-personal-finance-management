import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../domain/app_preferences.dart';
import '../viewmodels/settings_view_model.dart';

/// "Giao diện": three cards with a thumbnail, applied the moment one is picked.
Future<void> showThemeSheet(BuildContext context, SettingsViewModel model) {
  final s = S.of(context);
  return showFreevaSheet<void>(
    context: context,
    title: s.meTheme,
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: FreevaMotion.fast,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? c.tintBlue : c.bgSurface,
            borderRadius: BorderRadius.circular(FreevaRadius.md),
            border: Border.all(
              color: selected ? c.borderSelected : c.borderDefault,
              width: selected
                  ? FreevaBorder.selected
                  : FreevaBorder.defaultValue,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: _Thumbnail(preference)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: FreevaTypography.bodyS.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 4),
                    Icon(LucideIcons.check, size: 14, color: c.actionPrimary),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny phone: canvas, a card and two lines, in the colours of the theme.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail(this.preference);

  final AppThemePreference preference;

  @override
  Widget build(BuildContext context) {
    Widget phone(FreevaColors c) => Container(
      color: c.bgCanvas,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 5, width: 24, color: c.textPrimary),
          const SizedBox(height: 5),
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 4, color: c.bgTrack),
          const SizedBox(height: 3),
          Container(height: 4, width: 30, color: c.bgTrack),
        ],
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 64,
        child: switch (preference) {
          AppThemePreference.light => phone(FreevaColors.light),
          AppThemePreference.dark => phone(FreevaColors.dark),
          AppThemePreference.system => Row(
            children: [
              Expanded(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: .5,
                    child: SizedBox(
                      width: 90,
                      child: phone(FreevaColors.light),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: .5,
                    child: SizedBox(width: 90, child: phone(FreevaColors.dark)),
                  ),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
