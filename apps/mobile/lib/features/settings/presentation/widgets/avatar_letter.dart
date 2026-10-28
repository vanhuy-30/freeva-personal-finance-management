import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/account_labels.dart';

/// Round avatar with the first letter of the name. No photo yet.
class AvatarLetter extends StatelessWidget {
  const AvatarLetter({
    required this.name,
    required this.email,
    this.size = 56,
    this.letterSize,
    super.key,
  });

  final String? name;
  final String? email;
  final double size;

  /// Letter size from the boards (18 at 52, 34 at 96); null keeps 40% of
  /// [size] in the headline style.
  final double? letterSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final letter = avatarLetter(name, email);
    return Semantics(
      image: true,
      label: S.of(context).meAvatarSemantics(letter),
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.bgAvatar, shape: BoxShape.circle),
        child: Text(
          letter,
          style: letterSize == null
              ? FreevaTypography.headline.copyWith(
                  fontSize: size * .4,
                  color: c.tintBlueFg,
                )
              : FreevaTypography.titleM.copyWith(
                  fontSize: letterSize,
                  height: 1,
                  color: c.tintBlueFg,
                ),
        ),
      ),
    );
  }
}
