import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_switch.dart';

/// Form row with a switch: white card, at least 60 high, title + hint on the
/// left ("Số tiền mỗi kỳ có thể khác", "Tạm dừng").
class RecSwitchCard extends StatelessWidget {
  const RecSwitchCard({
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FreevaCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: MergeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: FreevaTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FreevaSwitch(value: value, onChanged: onChanged, label: title),
            ],
          ),
        ),
      ),
    );
  }
}
