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
import '../../../../core/widgets/skeleton.dart';
import '../../domain/goal.dart';
import '../viewmodels/goal_view_model.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_kind_chip.dart';
import '../widgets/goal_look.dart';
import '../widgets/goal_mini_tile.dart';

/// Mục tiêu: the list with its totals, or the empty state with three
/// suggested kinds. Reached from Cá nhân → Quản lý tiền and the Overview block.
class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late final GoalViewModel model = getIt<GoalViewModel>();
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(model.load);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final empty = model.loaded && model.active.isEmpty;
        return Scaffold(
          appBar: FreevaTopBar(
            title: s.meGoals,
            onLeading: () => context.popOrGo('/me'),
            action: empty || !model.loaded
                ? null
                : FreevaIconButton(
                    icon: LucideIcons.plus,
                    label: s.goalsAdd,
                    onPressed: () => context.push('/me/goals/new'),
                  ),
          ),
          body: _body(context, s, empty),
        );
      },
    );
  }

  Widget _body(BuildContext context, S s, bool empty) {
    final margin = context.screenMargin;
    if (!model.loaded && model.failure != null) {
      return ErrorRetry(
        title: s.goalsLoadError,
        message: s.homeErrorBody,
        onRetry: model.load,
      );
    }
    if (!model.loaded) {
      return Padding(
        padding: EdgeInsets.all(margin),
        child: const SkeletonRows(count: 3),
      );
    }
    if (empty && model.archived.isEmpty) return _Empty(margin: margin);
    return RefreshIndicator(
      onRefresh: model.load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 28),
        children: [
          if (model.active.isNotEmpty) _Totals(model: model),
          for (final goal in model.active) ...[
            const SizedBox(height: 14),
            _card(context, goal),
          ],
          if (model.archived.isNotEmpty) ...[
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showArchived = !_showArchived),
                child: Text(
                  s.goalsArchivedLink,
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textLink,
                  ),
                ),
              ),
            ),
            if (_showArchived)
              for (final goal in model.archived) ...[
                const SizedBox(height: 14),
                _card(context, goal),
              ],
          ],
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Goal goal) => GoalCard(
    goal: goal,
    digits: model.digitsOf(goal.currencyCode),
    onTap: () => context.push('/me/goals/${goal.id}'),
  );
}

class _Totals extends StatelessWidget {
  const _Totals({required this.model});

  final GoalViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final currency = model.totalCurrency;
    final digits = model.digitsOf(currency);
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.goalsSaved,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: FreevaSpace.s3),
          MoneyDisplay(
            minor: model.savedTotal,
            currency: currency,
            minorDigits: digits,
            style: FreevaTypography.moneyL.copyWith(
              fontSize: 30,
              height: 34 / 30,
              letterSpacing: -0.9,
            ),
            currencySize: 15,
            currencyColor: c.textOnWash,
          ),
          const SizedBox(height: FreevaSpace.s3),
          Row(
            children: [
              Expanded(
                child: GoalMiniTile(
                  label: s.goalsCountLabel,
                  value: '${model.active.length}',
                ),
              ),
              const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: GoalMiniTile(
                  label: s.goalsNeededMonth,
                  value: formatMoneyText(model.neededThisMonth, digits, locale),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.margin});

  final double margin;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(margin, 0, margin, 28),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: c.tintViolet,
                        borderRadius: BorderRadius.circular(FreevaRadius.xl),
                      ),
                      child: Icon(
                        LucideIcons.target,
                        size: 32,
                        color: c.tintVioletFg,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      s.goalsEmptyTitle,
                      textAlign: TextAlign.center,
                      style: FreevaTypography.titleS.copyWith(
                        height: 26 / 20,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.goalsEmptyBody,
                      textAlign: TextAlign.center,
                      style: FreevaTypography.body.copyWith(
                        height: 22 / 15,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: FreevaSpace.s2,
                      runSpacing: FreevaSpace.s2,
                      children: [
                        for (final kind in const [
                          'emergency',
                          'travel',
                          'home',
                        ])
                          GoalKindChip(
                            kind: kind,
                            label: goalKindLabel(s, kind),
                            onTap: () =>
                                context.push('/me/goals/new?kind=$kind'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          FreevaButton(
            label: s.goalsCreate,
            size: FreevaButtonSize.l,
            expand: true,
            onPressed: () => context.push('/me/goals/new'),
          ),
        ],
      ),
    );
  }
}
