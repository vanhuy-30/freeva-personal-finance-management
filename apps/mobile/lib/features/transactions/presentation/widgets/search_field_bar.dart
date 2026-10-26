import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Pill search field focused on open, clear button, and "Huỷ" to go back.
class SearchFieldBar extends StatefulWidget {
  const SearchFieldBar({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  State<SearchFieldBar> createState() => _SearchFieldBarState();
}

class _SearchFieldBarState extends State<SearchFieldBar> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() {});
              widget.onChanged(value);
            },
            style: FreevaTypography.body.copyWith(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: s.txSearchHint,
              prefixIcon: Icon(
                LucideIcons.search,
                size: FreevaSize.iconInline,
                color: c.textSecondary,
              ),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: s.txSearchClear,
                      icon: Icon(
                        LucideIcons.circleX,
                        size: FreevaSize.iconInline,
                        color: c.textSecondary,
                      ),
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                        widget.onChanged('');
                      },
                    ),
              constraints: const BoxConstraints(minHeight: 48),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FreevaRadius.full),
                borderSide: BorderSide(color: c.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FreevaRadius.full),
                borderSide: BorderSide(color: c.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FreevaRadius.full),
                borderSide: BorderSide(
                  color: c.inputBorderFocus,
                  width: FreevaBorder.selected,
                ),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(s.txSearchCancel),
        ),
      ],
    );
  }
}
