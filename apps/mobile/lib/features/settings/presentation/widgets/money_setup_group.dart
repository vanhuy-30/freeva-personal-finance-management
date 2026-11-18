import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../auto_suggest/presentation/viewmodels/auto_suggest_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';

/// THIẾT LẬP: categories, tags, the income-and-period screen and Gợi ý tự
/// động (it picks categories for new transactions).
class MoneySetupGroup extends StatelessWidget {
  const MoneySetupGroup({
    required this.profile,
    this.tagCount,
    this.autoSuggest,
    super.key,
  });

  final ProfileViewModel profile;

  /// Gợi ý tự động row; shown only when one of its server flags is on.
  final AutoSuggestViewModel? autoSuggest;

  /// Tags; null while unknown.
  final int? tagCount;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final saved = profile.saved;
    const rowHeight = 54.0;
    return SettingsGroup(
      title: s.meGroupSetup,
      children: [
        SettingsRow(
          tint: (c.tintCyan, c.tintCyanFg),
          minHeight: rowHeight,
          icon: LucideIcons.layoutGrid,
          title: s.meCategories,
          onTap: () => context.push('/categories'),
        ),
        SettingsRow(
          tint: (c.tintBlue, c.tintBlueFg),
          minHeight: rowHeight,
          icon: LucideIcons.tag,
          title: s.meTags,
          value: tagCount == null ? null : '$tagCount',
          onTap: () => context.push('/me/tags'),
        ),
        SettingsRow(
          tint: (c.tintGreen, c.tintGreenFg),
          minHeight: rowHeight,
          icon: LucideIcons.banknote,
          title: s.meMoneyTitle,
          value: saved == null
              ? null
              : '${saved.currency} · ${s.meFiscalDay(saved.fiscalDay).toLowerCase()}',
          onTap: () => context.push('/me/money'),
        ),
        if (autoSuggest case final auto? when auto.available)
          SettingsRow(
            tint: (c.tintViolet, c.tintVioletFg),
            minHeight: rowHeight,
            icon: LucideIcons.sparkles,
            title: s.autoSuggestTitle,
            value: auto.enabled ? s.autoSuggestOn : s.autoSuggestOff,
            onTap: () => context.push('/me/auto-suggest'),
          ),
      ],
    );
  }
}
