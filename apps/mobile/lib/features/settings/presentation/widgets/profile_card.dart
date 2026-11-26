import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import 'avatar_letter.dart';

/// Top of Cá nhân: avatar, name and email. Opens Hồ sơ.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.name,
    required this.email,
    this.image,
    super.key,
  });

  final String? name;
  final String? email;
  final Uint8List? image;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FreevaCard(
      onTap: () => context.push('/profile'),
      child: Row(
        children: [
          AvatarLetter(
            name: name,
            email: email,
            image: image,
            size: 52,
            letterSize: 18,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? email ?? '',
                  style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
                ),
                if (name != null && email != null)
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
