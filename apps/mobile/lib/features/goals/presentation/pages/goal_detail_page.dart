import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/goal.dart';
import '../viewmodels/goal_forecast_view_model.dart';
import '../viewmodels/goal_view_model.dart';
import '../widgets/goal_forecast_card.dart';
import '../widgets/goal_history.dart';
import '../widgets/goal_look.dart';
import '../widgets/goal_mini_tile.dart';
import '../widgets/goal_move_sheet.dart';

/// One goal: how much is saved, what it needs each month, when it is likely
/// reached at the recent pace, Góp thêm / Rút ra and the history.
class GoalDetailPage extends StatefulWidget {
  const GoalDetailPage({required this.goalId, super.key});

  final String goalId;

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  late final GoalViewModel model = getIt<GoalViewModel>();
  late final GoalForecastViewModel _forecast = getIt<GoalForecastViewModel>();
  List<GoalEntry>? entries;
  bool _entriesFailed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!model.loaded) await model.load();
      if (!mounted) return;
      await Future.wait([_loadEntries(), _forecast.load(widget.goalId)]);
    });
  }

  @override
  void dispose() {
    _forecast.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final goal = model.byId(widget.goalId);
    if (goal == null) return;
    final items = await model.entries(goal);
    if (!mounted) return;
    setState(() {
      entries = items;
      _entriesFailed = items == null;
    });
  }

  Future<void> _move(Goal goal, {required bool out}) async {
    final moved = await showGoalMoveSheet(context, model, goal, out: out);
    if (moved != true || !mounted) return;
    await Future.wait([_loadEntries(), _forecast.load(goal.id)]);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([model, _forecast]),
      builder: (context, _) {
        final goal = model.byId(widget.goalId);
        if (goal == null) {
          return Scaffold(
            appBar: FreevaTopBar(
              title: s.meGoals,
              onLeading: () => context.popOrGo('/me/goals'),
            ),
            body: model.loaded || model.failure != null
                ? ErrorRetry(
                    title: s.goalsLoadError,
                    message: s.homeErrorBody,
                    onRetry: model.load,
                  )
                : const SizedBox.shrink(),
          );
        }
        return Scaffold(
          appBar: FreevaTopBar(
            title: goal.name,
            onLeading: () => context.popOrGo('/me/goals'),
            action: goal.archived
                ? null
                : FreevaIconButton(
                    icon: LucideIcons.penLine,
                    iconSize: FreevaSize.iconSm,
                    label: s.goalsEdit,
                    onPressed: () => context.push('/me/goals/${goal.id}/edit'),
                  ),
          ),
          body: _body(context, s, goal),
        );
      },
    );
  }

  Widget _body(BuildContext context, S s, Goal goal) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final digits = model.digitsOf(goal.currencyCode);
    String money(BigInt value) => formatMoneyText(value, digits, locale);
    final margin = context.screenMargin;
    final wallet = model.wallets
        .where((w) => w.id == goal.accountId)
        .firstOrNull;
    final line = goal.status == GoalStatus.reached
        ? s.goalProgressDone('${goal.percent}')
        : s.goalProgressLine('${goal.percent}', money(goal.remainingMinor));
    const dash = '—';
    final need = goal.requiredPerMonthMinor;
    return ListView(
      padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 28),
      children: [
        FreevaCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GoalIconTile(kind: goal.kind, size: 44),
                  const SizedBox(width: FreevaSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.goalHave,
                          style: FreevaTypography.label.copyWith(
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                          ),
                        ),
                        // Scales down as one line when the amounts do not fit
                        // (large text, long numbers) instead of overflowing.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              MoneyDisplay(
                                minor: goal.currentMinor,
                                currency: goal.currencyCode,
                                minorDigits: digits,
                                showCurrency: false,
                                style: FreevaTypography.moneyL.copyWith(
                                  fontSize: 26,
                                  height: 30 / 26,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.goalOf(money(goal.targetMinor)),
                                maxLines: 1,
                                style: FreevaTypography.bodyM.copyWith(
                                  color: c.textSecondary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FreevaSpace.s3),
              FreevaProgressBar(
                value: goal.progress,
                color: goalBarColor(context, goal),
                height: 10,
                semanticsLabel: goal.name,
              ),
              const SizedBox(height: FreevaSpace.s3),
              Text(
                line,
                style: FreevaTypography.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Grid(
          tiles: [
            GoalMiniTile(
              label: s.goalNeedPerMonth,
              value: need == null || need == BigInt.zero ? dash : money(need),
            ),
            GoalMiniTile(
              label: s.goalLeft,
              value: goal.monthsLeft == null
                  ? dash
                  : s.goalMonths(goal.monthsLeft!),
            ),
            GoalMiniTile(
              label: s.goalDue,
              value: goal.targetDate == null
                  ? dash
                  : goalMonthLabel(goal.targetDate!, locale),
            ),
            GoalMiniTile(
              label: s.goalWallet,
              value: wallet?.draft.name ?? dash,
            ),
          ],
        ),
        if (_forecast.shown case final forecast?) ...[
          const SizedBox(height: 14),
          GoalForecastCard(
            forecast: forecast,
            goal: goal,
            today: model.today,
            digits: digits,
          ),
        ],
        if (!goal.archived) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FreevaButton(
                  label: s.goalContribute,
                  size: FreevaButtonSize.dialog,
                  icon: LucideIcons.plus,
                  expand: true,
                  onPressed: () => _move(goal, out: false),
                ),
              ),
              const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: FreevaButton(
                  label: s.goalWithdraw,
                  size: FreevaButtonSize.dialog,
                  variant: FreevaButtonVariant.secondary,
                  icon: LucideIcons.arrowUpToLine,
                  expand: true,
                  onPressed: goal.currentMinor == BigInt.zero
                      ? null
                      : () => _move(goal, out: true),
                ),
              ),
            ],
          ),
        ],
        if (entries?.isNotEmpty ?? false) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              s.goalHistory.toUpperCase(),
              style: FreevaTypography.sectionLabel.copyWith(
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          GoalHistory(entries: entries!, digits: digits),
        ] else if (_entriesFailed) ...[
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _loadEntries,
              child: Text(s.commonRetry),
            ),
          ),
        ],
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < tiles.length; i += 2) ...[
        if (i > 0) const SizedBox(height: FreevaSpace.s2),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}
