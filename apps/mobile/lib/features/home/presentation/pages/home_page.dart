import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/brand_symbol.dart';
import '../../../auth/presentation/widgets/session_controls.dart';

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
            const SessionControls(),
            const BrandSymbol(size: 96),
            const SizedBox(height: 16),
            Text(
              s.homePlaceholder,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
