import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_banner.dart';
import '../../../auth/presentation/widgets/session_alert_banner.dart';
import '../viewmodels/home_view_model.dart';
import '../../domain/first_run_checklist.dart';
import '../widgets/balance_section.dart';
import '../widgets/first_run_card.dart';
import '../widgets/overview_blocks.dart';
import '../widgets/overview_header.dart';
import '../widgets/overview_states.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions.dart';

/// Tổng quan. Partial failures never block the greeting, quick actions or +.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeViewModel model = getIt<HomeViewModel>();
  GoRouter? _router;
  String? _lastPath;

  @override
  void initState() {
    super.initState();
    if (model.data == null) Future.microtask(model.load);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router == _router) return;
    _router?.routerDelegate.removeListener(_routeChanged);
    _router = router?..routerDelegate.addListener(_routeChanged);
  }

  /// Coming back to Overview (after recording, editing a wallet…) refreshes.
  void _routeChanged() {
    final path = _router?.routerDelegate.currentConfiguration.uri.path;
    if (path == '/home' && _lastPath != null && _lastPath != '/home') {
      model.load();
    }
    _lastPath = path;
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_routeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      final data = model.data;
      final margin = context.screenMargin;
      final checklist = data == null
          ? null
          : FirstRunChecklist.of(
              data,
              pending: model.pending.length,
              hasPin: model.hasPin,
            );
      // First run (ObHome): greeting, compact balance, checklist and the
      // empty "Gần đây" hint only.
      final firstRun = checklist != null && checklist.visible;
      final gap = SizedBox(height: firstRun ? FreevaSpace.s5 : 22);
      final offline = model.status == HomeStatus.offline && data != null;
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: model.load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                margin,
                FreevaSpace.s4,
                margin,
                FreevaLayout.navReserve,
              ),
              children: [
                OverviewHeader(
                  name: model.displayName,
                  today: model.today,
                  actions: !firstRun,
                ),
                // The offline banner sits 14 under the header, 22 above the card.
                SizedBox(height: offline ? 14 : gap.height),
                SessionAlertBanner(onReview: () => context.go('/me')),
                if (offline) ...[
                  FreevaBanner(
                    icon: LucideIcons.cloudOff,
                    message: s.homeOfflineHeading,
                    detail: s.homeOfflineDetail(
                      DateFormat.Hm().format(data.loadedAt),
                    ),
                  ),
                  gap,
                ],
                BalanceSection(model: model, compact: firstRun),
                gap,
                if (firstRun) ...[
                  FirstRunCard(checklist: checklist),
                  gap,
                  const RecentEmptyHint(),
                ] else ...[
                  const QuickActions(),
                  gap,
                  if (data != null)
                    OverviewBlocks(model: model, data: data)
                  else if (model.status == HomeStatus.loading)
                    const BlocksSkeleton(),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
