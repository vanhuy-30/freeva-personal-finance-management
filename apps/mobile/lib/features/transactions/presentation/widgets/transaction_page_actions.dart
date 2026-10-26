import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_icon_button.dart';

/// Search and filter buttons; a primary dot marks active filters.
class TransactionPageActions extends StatelessWidget {
  const TransactionPageActions({
    required this.filtered,
    required this.onFilter,
    super.key,
  });

  final bool filtered;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FreevaIconButton(
          icon: LucideIcons.search,
          label: s.txSearchAction,
          onPressed: () => context.push('/transactions/search'),
        ),
        const SizedBox(width: FreevaSpace.s2),
        Badge(
          isLabelVisible: filtered,
          smallSize: 8,
          backgroundColor: context.colors.actionPrimary,
          child: FreevaIconButton(
            icon: LucideIcons.slidersHorizontal,
            label: filtered ? s.txFilterActive : s.txFilterAction,
            onPressed: onFilter,
          ),
        ),
      ],
    );
  }
}
