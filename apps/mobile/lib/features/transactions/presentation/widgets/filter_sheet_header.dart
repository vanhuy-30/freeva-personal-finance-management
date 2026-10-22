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
    return Row(
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
        TextButton(onPressed: onReset, child: Text(s.txFilterReset)),
      ],
    );
  }
}
