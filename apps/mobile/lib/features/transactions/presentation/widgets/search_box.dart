import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Search box of the C boards: 48 high, radius 16, glyph 14 in, gap 10,
/// 16 px text. Outlined (white, focus border + ring) or [filled]
/// (`bg.subtle`, no border: the category sheet). [clearable] adds the round
/// grey clear button.
class SearchBox extends StatefulWidget {
  const SearchBox({
    required this.hint,
    required this.onChanged,
    this.filled = false,
    this.autofocus = false,
    this.clearable = false,
    this.iconSize = FreevaSize.iconInline,
    this.controller,
    super.key,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final bool filled;
  final bool autofocus;
  final bool clearable;
  final double iconSize;
  final TextEditingController? controller;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late final TextEditingController controller =
      widget.controller ?? TextEditingController();
  final focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final focused = focus.hasFocus && !widget.filled;
    final text = FreevaTypography.body.copyWith(
      fontSize: 16,
      height: 1.25,
      color: c.textPrimary,
    );
    return AnimatedContainer(
      duration: FreevaMotion.fast,
      height: 48,
      padding: EdgeInsets.only(left: 14, right: widget.clearable ? 2 : 14),
      decoration: BoxDecoration(
        color: widget.filled ? c.bgSubtle : c.inputBg,
        borderRadius: BorderRadius.circular(FreevaComponent.inputRadius),
        border: widget.filled
            ? null
            : Border.all(
                color: focused ? c.inputBorderFocus : c.inputBorder,
                width: focused
                    ? FreevaBorder.selected
                    : FreevaBorder.defaultValue,
              ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: c.focusRing.withValues(alpha: .18),
                  spreadRadius: FreevaBorder.focusRing,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.search,
            size: widget.iconSize,
            color: c.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {});
                widget.onChanged(value);
              },
              style: text,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hint,
                hintStyle: text.copyWith(color: c.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (widget.clearable && controller.text.isNotEmpty)
            Tooltip(
              message: s.txSearchClear,
              child: Semantics(
                button: true,
                label: s.txSearchClear,
                excludeSemantics: true,
                child: InkResponse(
                  radius: 22,
                  onTap: () {
                    controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                  // Board: 36 box 6 in from the edge; a 44 touch box 2 in
                  // keeps the 18 circle in the same place.
                  child: SizedBox.square(
                    dimension: FreevaSize.touch,
                    child: Center(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.borderStrong,
                        ),
                        child: Icon(
                          LucideIcons.x,
                          size: 12,
                          color: c.bgSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
