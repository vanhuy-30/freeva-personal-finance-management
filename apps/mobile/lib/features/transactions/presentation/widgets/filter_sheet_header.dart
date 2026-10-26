import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

class FilterSheetHeader extends StatelessWidget {
  const FilterSheetHeader({required this.onReset, super.key});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Board: 20 under the handle (the sheet gives 14), row 40 high.
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  s.txFilterAction,
                  style: FreevaTypography.titleL.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: onReset,
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textLink,
                minimumSize: const Size(FreevaSize.touch, 40),
                padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
                tapTargetSize: MaterialTapTargetSize.padded,
                textStyle: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: Text(s.txFilterReset),
            ),
          ],
        ),
      ),
    );
  }
}
