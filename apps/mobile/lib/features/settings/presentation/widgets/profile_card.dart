import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/account_labels.dart';
import 'avatar_letter.dart';

/// Top of Cá nhân: avatar, name and masked email. Opens Hồ sơ.
class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.name, required this.email, super.key});

  final String? name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final masked = email == null ? null : maskEmail(email!);
    return FreevaCard(
      onTap: () => context.push('/profile'),
      child: Row(
        children: [
          AvatarLetter(name: name, email: email, size: 52, letterSize: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? masked ?? '',
                  style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
                ),
                if (name != null && masked != null)
                  Text(
                    masked,
                    style: FreevaTypography.bodyS.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 18, color: c.textSecondary),
        ],
      ),
    );
  }
}
