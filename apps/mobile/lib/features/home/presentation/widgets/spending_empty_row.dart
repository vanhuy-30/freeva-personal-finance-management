import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';

/// Empty month: "Chưa có khoản chi nào." and a compact primary "Ghi chi" on
/// one row (B5).
class SpendingEmptyRow extends StatelessWidget {
  const SpendingEmptyRow({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            s.homeSpendEmpty,
            style: FreevaTypography.bodyM.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: FreevaSpace.s3),
        FreevaButton(
          label: s.homeSpendRecord,
          size: FreevaButtonSize.compact,
          onPressed: () => context.push('/record'),
        ),
      ],
    );
  }
}
