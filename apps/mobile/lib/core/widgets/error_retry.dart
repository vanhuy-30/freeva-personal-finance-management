import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_button.dart';
import 'freeva_card.dart';

/// Block-level load error: what failed, one reassuring line, and "Thử lại".
/// Errors always offer a way out.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    required this.title,
    required this.message,
    required this.onRetry,
    this.icon = LucideIcons.cloudOff,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FreevaCard(
      list: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.statusDangerBg,
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
            ),
            child: Icon(
              icon,
              size: FreevaSize.iconInline,
              color: c.statusDanger,
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FreevaTypography.titleM.copyWith(
                    fontSize: 14,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  message,
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FreevaSpace.s2),
          FreevaButton(
            label: S.of(context).commonRetry,
            onPressed: onRetry,
            variant: FreevaButtonVariant.secondary,
            size: FreevaButtonSize.xs,
          ),
        ],
      ),
    );
  }
}
