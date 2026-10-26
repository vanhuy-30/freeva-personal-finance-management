import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/press_scale.dart';

/// Four quick actions: Ghi thu · Chuyển ví · Ví của tôi · Danh mục.
/// Always usable, even while the overview is loading or failed.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Action(
          icon: LucideIcons.arrowDownLeft,
          color: c.tintGreenFg,
          label: s.homeQuickIncome,
          onTap: () => context.push('/record?type=income'),
        ),
        _Action(
          icon: LucideIcons.arrowLeftRight,
          color: c.tintBlueFg,
          label: s.homeQuickTransfer,
          onTap: () => context.push('/record?type=transfer'),
        ),
        _Action(
          icon: LucideIcons.wallet,
          color: c.tintVioletFg,
          label: s.homeQuickWallets,
          onTap: () => context.push('/wallets'),
        ),
        _Action(
          icon: LucideIcons.shapes,
          color: c.tintCyanFg,
          label: s.homeQuickCategories,
          onTap: () => context.push('/categories'),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: PressScale(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.bgSurface,
                    borderRadius: BorderRadius.circular(FreevaRadius.lg),
                    boxShadow: FreevaElevation.s1,
                  ),
                  child: Icon(icon, size: FreevaSize.icon, color: color),
                ),
                const SizedBox(height: FreevaSpace.s2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: FreevaTypography.label.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
