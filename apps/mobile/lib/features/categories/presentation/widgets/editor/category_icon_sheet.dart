import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/text/vietnamese_fold.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_sheet.dart';
import '../category_badge.dart';
import '../category_names.dart';
import 'category_icon_cell.dart';

/// "Biểu tượng" sheet (E, màn 4): search without accents, 36 icons in four
/// groups. Returns the chosen token on "Xong", null when dismissed.
Future<String?> showCategoryIconSheet(
  BuildContext context, {
  required String? selected,
  required String? colorToken,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  // The sheet paints its own surface, handle and shadow.
  backgroundColor: Colors.transparent,
  elevation: 0,
  builder: (_) => _IconSheet(selected: selected, colorToken: colorToken),
);

class _IconSheet extends StatefulWidget {
  const _IconSheet({required this.selected, required this.colorToken});

  final String? selected;
  final String? colorToken;

  @override
  State<_IconSheet> createState() => _IconSheetState();
}

class _IconSheetState extends State<_IconSheet> {
  late String? picked = widget.selected;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final margin = context.screenMargin;
    final folded = foldVietnamese(query.trim());
    bool matches(String token) =>
        folded.isEmpty ||
        foldVietnamese(categoryIconLabel(s, token)).contains(folded);
    final titles = categoryIconGroupTitles(s);
    final groups = [
      for (final (i, group) in categoryIconGroups.indexed)
        (titles[i], group.where(matches).toList()),
    ].where((g) => g.$2.isNotEmpty).toList();
    const radius = BorderRadius.vertical(
      top: Radius.circular(FreevaRadius.sheet),
    );
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .86,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: radius,
          boxShadow: FreevaElevation.sheet,
        ),
        child: Material(
          color: c.sheetBg,
          shape: const RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(margin, 10, margin, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FreevaSheetHandle(),
                // 10 + the 44 header (board: 12 + 40) keeps "Xong" 44 tall.
                const SizedBox(height: 10),
                SizedBox(
                  height: FreevaSize.touch,
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            s.categoryIcon,
                            style: FreevaTypography.titleL.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(picked),
                        style: TextButton.styleFrom(
                          foregroundColor: c.actionPrimary,
                          minimumSize: const Size(
                            FreevaSize.touch,
                            FreevaSize.touch,
                          ),
                          // Text flush with the right margin.
                          padding: const EdgeInsets.only(left: FreevaSpace.s3),
                          textStyle: FreevaTypography.titleM,
                        ),
                        child: Text(s.categoryIconDone),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: FreevaSize.touch,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: c.bgSubtle,
                    borderRadius: BorderRadius.circular(FreevaRadius.smd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: FreevaSize.iconSm,
                        color: c.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Semantics(
                          textField: true,
                          label: s.categoryIconSearchLabel,
                          child: TextField(
                            onChanged: (value) => setState(() => query = value),
                            style: FreevaTypography.body.copyWith(
                              color: c.textPrimary,
                            ),
                            // Zero padding: the theme's field padding must
                            // not push the text off the board's 42 start.
                            decoration: InputDecoration(
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: s.categoryIconSearch,
                              hintStyle: FreevaTypography.body.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FreevaSpace.s3),
                Expanded(
                  child: groups.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: FreevaSpace.s6),
                          child: Text(
                            s.categoryIconNoMatch,
                            textAlign: TextAlign.center,
                            style: FreevaTypography.body.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.only(
                            bottom:
                                FreevaSpace.s6 +
                                MediaQuery.paddingOf(context).bottom,
                          ),
                          children: [
                            for (final (i, (title, tokens))
                                in groups.indexed) ...[
                              if (i > 0) const SizedBox(height: FreevaSpace.s3),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  2,
                                  0,
                                  0,
                                  FreevaSpace.s3,
                                ),
                                child: Text(
                                  title,
                                  style: FreevaTypography.label.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                              IconGridRows(
                                cells: [
                                  for (final token in tokens)
                                    CategoryIconCell(
                                      icon: categoryIcon(token),
                                      label: categoryIconLabel(s, token),
                                      selected: token == picked,
                                      colorToken: widget.colorToken,
                                      onTap: () =>
                                          setState(() => picked = token),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
