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
import '../../../goals/presentation/viewmodels/goal_view_model.dart';
import '../../../goals/presentation/widgets/goals_home_block.dart';
import '../../../notifications/presentation/viewmodels/notification_view_model.dart';
import '../../../onboarding/presentation/viewmodels/first_run_nudges_view_model.dart';
import '../../../onboarding/presentation/widgets/daily_log_ask_sheet.dart';
import '../viewmodels/home_view_model.dart';
import '../../domain/first_run_checklist.dart';
import '../../domain/overview.dart';
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

  /// Not registered in some widget tests.
  final FirstRunNudgesViewModel? _nudges =
      getIt.isRegistered<FirstRunNudgesViewModel>()
      ? getIt<FirstRunNudgesViewModel>()
      : null;
  OverviewData? _checked;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    model.addListener(_modelChanged);
    _nudges?.addListener(_nudgesChanged);
    if (model.data == null) Future.microtask(model.load);
  }

  /// After each fresh load: create the waiting saving goal, maybe offer the
  /// daily log reminder.
  Future<void> _modelChanged() async {
    final data = model.data;
    final nudges = _nudges;
    if (nudges == null || data == null || identical(data, _checked)) return;
    _checked = data;
    final created = await nudges.check(
      trackGoal: model.trackGoal,
      hasTransactions: data.recent.isNotEmpty,
    );
    if (created && model.saveGoal) getIt<GoalViewModel>().load();
  }

  void _nudgesChanged() {
    final nudges = _nudges;
    if (nudges == null || !nudges.askDailyLog || _sheetOpen || !mounted) {
      return;
    }
    // Only over Tổng quan itself, not a screen pushed on top of it.
    if (_lastPath != null && _lastPath != '/home') return;
    _sheetOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDailyLogAskSheet(context, getIt<NotificationViewModel>());
      _sheetOpen = false;
      await nudges.dailyLogAnswered();
    });
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
      if (model.saveGoal) getIt<GoalViewModel>().load();
    }
    _lastPath = path;
  }

  @override
  void dispose() {
    model.removeListener(_modelChanged);
    _nudges?.removeListener(_nudgesChanged);
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
                  if (model.saveGoal) const GoalsHomeBlock(),
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
