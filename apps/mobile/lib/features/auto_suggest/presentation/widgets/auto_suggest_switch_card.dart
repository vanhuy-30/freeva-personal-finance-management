import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_switch.dart';

/// U.1 top card: one 64-high row with a 36 blue sparkles tile, title,
/// "Danh mục, phân tích, dự báo" and the switch. Tapping the row flips it.
class AutoSuggestSwitchCard extends StatelessWidget {
  const AutoSuggestSwitchCard({
    required this.on,
    required this.onChanged,
    super.key,
  });

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      list: true,
      padding: EdgeInsets.zero,
      onTap: () => onChanged(!on),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FreevaSpace.s4,
            vertical: FreevaSpace.s2,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.tintBlue,
                    borderRadius: BorderRadius.circular(FreevaRadius.sm),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    size: FreevaSize.iconSm,
                    color: c.tintBlueFg,
                  ),
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.autoSuggestTitle,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.autoSuggestSubtitle,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              FreevaSwitch(value: on, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
