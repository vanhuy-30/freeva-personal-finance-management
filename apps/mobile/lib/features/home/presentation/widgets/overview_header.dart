import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_icon_button.dart';

/// "Thứ Ba, 21/10" · "Chào Minh", search and the notification bell.
class OverviewHeader extends StatelessWidget {
  const OverviewHeader({required this.name, required this.today, super.key});

  final String? name;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat(s.homeDatePattern, locale).format(today);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                toBeginningOfSentenceCase(date),
                style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
              ),
              Semantics(
                header: true,
                child: Text(
                  name == null ? s.homeGreetingAnon : s.homeGreeting(name!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (context.isCompactScreen
                              ? FreevaTypography.headlineCompact
                              : FreevaTypography.headline)
                          .copyWith(color: c.textPrimary),
                ),
              ),
            ],
          ),
        ),
        FreevaIconButton(
          icon: LucideIcons.search,
          label: s.homeSearch,
          onPressed: () => context.go('/transactions'),
        ),
        const SizedBox(width: FreevaSpace.s2),
        FreevaIconButton(
          icon: LucideIcons.bell,
          label: s.homeNotifications,
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }
}
