import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/nav_back.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final items = [
      (s.faqWalletQ, s.faqWalletA),
      (s.faqTransactionQ, s.faqTransactionA),
      (s.faqProfileQ, s.faqProfileA),
      (s.faqLockQ, s.faqLockA),
      (s.faqThemeQ, s.faqThemeA),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(s.faqTitle),
        leading: IconButton(
          tooltip: s.settingsBack,
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.popOrGo('/me'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final item in items)
            ExpansionTile(
              title: Text(item.$1),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(item.$2),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
