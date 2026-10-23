import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/brand_symbol.dart';
import '../../../auth/presentation/widgets/session_alert_banner.dart';
import '../../../auth/presentation/widgets/session_controls.dart';
import '../../../reports/presentation/widgets/overview_section.dart';
import '../../../sync/presentation/widgets/sync_status_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey _sessions = GlobalKey();

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
            const SyncStatusBanner(),
            ListTile(
              leading: const Icon(LucideIcons.user),
              title: Text(s.profileTitle),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push('/profile'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.wallet),
              title: Text(s.walletTitle),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push('/wallets'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.shapes),
              title: Text(s.categoryTitle),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push('/categories'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.receipt),
              title: Text(s.transactionTitle),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.go('/transactions'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.chartPie),
              title: Text(s.reportTitle),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.go('/reports'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.settings),
              title: Text(s.settingsTitle),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.go('/me'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => context.push('/record'),
                icon: const Icon(LucideIcons.plus),
                label: Text(s.transactionRecord),
              ),
            ),
            SessionAlertBanner(scrollTarget: _sessions),
            SessionControls(key: _sessions),
            const BrandSymbol(size: 96),
          ],
        ),
      ),
    );
  }
}
