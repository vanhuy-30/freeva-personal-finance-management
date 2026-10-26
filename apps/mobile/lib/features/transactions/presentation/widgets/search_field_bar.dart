import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import 'search_box.dart';

/// Search box focused on open with its clear button, and "Huỷ" to go back.
class SearchFieldBar extends StatelessWidget {
  const SearchFieldBar({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: SearchBox(
            hint: s.txSearchHint,
            onChanged: onChanged,
            autofocus: true,
            clearable: true,
          ),
        ),
        const SizedBox(width: FreevaSpace.s1),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: c.textLink,
            minimumSize: const Size(FreevaSize.touch, FreevaSize.touch),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            textStyle: FreevaTypography.body.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          child: Text(s.txSearchCancel),
        ),
      ],
    );
  }
}
