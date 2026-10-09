import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/brand_symbol.dart';
import '../../../auth/presentation/widgets/session_controls.dart';
import '../../../reports/presentation/widgets/overview_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.appTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OverviewSection(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(s.profileTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(s.walletTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/wallets'),
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(s.categoryTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/categories'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(s.transactionTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/transactions'),
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart_outline),
              title: Text(s.reportTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/reports'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(s.settingsTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => context.go('/transactions?record=1'),
                icon: const Icon(Icons.add),
                label: Text(s.transactionRecord),
              ),
            ),
            const SessionControls(),
            const BrandSymbol(size: 96),
          ],
        ),
      ),
    );
  }
}
