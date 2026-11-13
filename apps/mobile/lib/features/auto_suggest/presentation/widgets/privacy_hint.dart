import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Green shield and "Chỉ tính trên sổ của bạn, không gửi ra ngoài.", 13/18
/// muted, 4 in from the card edge.
class PrivacyHint extends StatelessWidget {
  const PrivacyHint({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: FreevaSpace.s1),
      child: Row(
        children: [
          Icon(
            LucideIcons.shield,
            size: FreevaSize.iconChip,
            color: c.statusSuccess,
          ),
          const SizedBox(width: FreevaSpace.s2),
          Expanded(
            child: Text(
              S.of(context).autoSuggestPrivacy,
              style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
