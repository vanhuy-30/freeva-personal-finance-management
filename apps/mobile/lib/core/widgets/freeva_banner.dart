import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

enum FreevaBannerTone { info, warning, success, danger }

/// In-flow banner (never covers content). At most one per screen.
class FreevaBanner extends StatelessWidget {
  const FreevaBanner({
    required this.message,
    required this.icon,
    this.tone = FreevaBannerTone.info,
    this.detail,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final IconData icon;
  final FreevaBannerTone tone;

  /// Optional second line.
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      FreevaBannerTone.info => (c.statusInfoBg, c.statusInfo),
      FreevaBannerTone.warning => (c.statusWarningBg, c.statusWarning),
      FreevaBannerTone.success => (c.statusSuccessBg, c.statusSuccess),
      FreevaBannerTone.danger => (c.statusDangerBg, c.statusDanger),
    };
    final style = FreevaTypography.bodyS.copyWith(color: fg);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FreevaRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: FreevaSize.iconInline, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: style.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (detail != null) Text(detail!, style: style),
                ],
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: fg,
                  textStyle: style.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
