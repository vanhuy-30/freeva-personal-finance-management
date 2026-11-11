import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../categories/presentation/widgets/category_badge.dart';
import '../../domain/category_suggestion.dart';
import '../viewmodels/category_suggest_view_model.dart';

/// Board R.1 under Cửa hàng: 12 below the field, nothing when there is no
/// card. `blue.50` fill with a blue hairline, radius 16, padding 10/10/10/12:
/// 36 icon tile, "Xếp vào Cà phê?" 15/600, "Như 8 lần trước ở đây" 12 muted
/// (only from the user's own history), dark "Dùng" pill.
class CategorySuggestCard extends StatelessWidget {
  const CategorySuggestCard({
    required this.model,
    required this.onUse,
    super.key,
  });

  final CategorySuggestViewModel model;

  /// Puts the suggested category on the form.
  final ValueChanged<String> onUse;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final suggestion = model.visible;
      if (suggestion == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: FreevaSpace.s3),
        child: _Card(
          suggestion: suggestion,
          onUse: () {
            final id = model.use();
            if (id != null) onUse(id);
          },
        ),
      );
    },
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.suggestion, required this.onUse});

  final CategorySuggestion suggestion;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final count = suggestion.matchCount;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        // The 10 right/top/bottom padding sits inside the Dùng tap area.
        padding: const EdgeInsets.only(left: FreevaSpace.s3),
        decoration: BoxDecoration(
          color: c.tintBlue,
          border: Border.all(color: c.dataMuted),
          borderRadius: BorderRadius.circular(FreevaRadius.md),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: FreevaSize.iconButtonS,
                height: FreevaSize.iconButtonS,
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  borderRadius: BorderRadius.circular(FreevaRadius.sm),
                ),
                child: Icon(
                  categoryIcon(suggestion.iconToken),
                  size: 17,
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
                    s.txSuggestTitle(suggestion.categoryName),
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: c.textPrimary,
                    ),
                  ),
                  if (count >= 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      s.txSuggestHistory(count),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 12 to the pill on the board; 10 of it is the tap padding.
            const SizedBox(width: 2),
            _UseButton(label: s.txSuggestUse, onTap: onUse),
          ],
        ),
      ),
    );
  }
}

/// Dark pill 36 high, padding 0 18, 14/600. The card's 10 padding around it
/// is part of the tap area, so it is 56 high.
class _UseButton extends StatelessWidget {
  const _UseButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              height: FreevaSize.buttonCompact,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.buttonInkBg,
                borderRadius: BorderRadius.circular(FreevaRadius.full),
              ),
              child: Text(
                label,
                style: FreevaTypography.bodyM.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: c.buttonInkFg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
