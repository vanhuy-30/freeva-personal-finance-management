import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Centred red text action with a leading glyph ("Đăng xuất", "Xoá tài
/// khoản"): 44 high, 16 at the sides, 18 glyph, 15/600.
class DangerTextButton extends StatelessWidget {
  const DangerTextButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: FreevaSize.iconSm),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: c.statusDanger,
          minimumSize: const Size(FreevaSize.touch, FreevaSize.touch),
          padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
          textStyle: FreevaTypography.titleM,
          splashFactory: NoSplash.splashFactory,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
