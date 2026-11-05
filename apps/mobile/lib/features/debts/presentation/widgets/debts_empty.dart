import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';

/// Centred 72 green tile, 20/600 title, 15/22 line, and the main button at
/// the bottom (DebtEmpty; the Khoản vay tab uses the same layout).
class DebtsEmpty extends StatelessWidget {
  const DebtsEmpty({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: c.tintGreen,
                        borderRadius: BorderRadius.circular(FreevaRadius.xl),
                      ),
                      child: Icon(icon, size: 32, color: c.tintGreenFg),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: FreevaTypography.titleS.copyWith(
                        height: 26 / 20,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: FreevaTypography.body.copyWith(
                        height: 22 / 15,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FreevaButton(
            label: action,
            size: FreevaButtonSize.l,
            expand: true,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
