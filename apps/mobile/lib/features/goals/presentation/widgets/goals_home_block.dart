import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/goal.dart';
import '../viewmodels/goal_view_model.dart';
import 'goal_look.dart';

/// "Mục tiêu · Xem tất cả" under the balance card: up to two goals with a
/// thin bar. Shown for people who picked "Tiết kiệm" and have a goal; takes
/// no space otherwise. [spacing] below it only when it shows.
class GoalsHomeBlock extends StatefulWidget {
  const GoalsHomeBlock({this.spacing = 22, super.key});

  final double spacing;

  @override
  State<GoalsHomeBlock> createState() => _GoalsHomeBlockState();
}

class _GoalsHomeBlockState extends State<GoalsHomeBlock> {
  late final GoalViewModel model = getIt<GoalViewModel>();

  @override
  void initState() {
    super.initState();
    if (!model.loaded) Future.microtask(model.load);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final goals = model.active.take(2).toList();
      if (goals.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(bottom: widget.spacing),
        child: _Card(model: model, goals: goals),
      );
    },
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.model, required this.goals});

  final GoalViewModel model;
  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return FreevaCard(
      onTap: () => context.push('/me/goals'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  s.goalsHomeTitle,
                  style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
                ),
              ),
              Text(
                s.goalsSeeAll,
                style: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w500,
                  color: c.textLink,
                ),
              ),
            ],
          ),
          for (final goal in goals) ...[
            const SizedBox(height: 14),
            _Item(
              goal: goal,
              digits: model.digitsOf(goal.currencyCode),
              locale: locale,
            ),
          ],
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.goal, required this.digits, required this.locale});

  final Goal goal;
  final int digits;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GoalIconTile(kind: goal.kind, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.bodyM.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    '${money(goal.currentMinor)} / ${money(goal.targetMinor)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              s.goalPercent('${goal.percent}'),
              style: FreevaTypography.bodyM.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: FreevaSpace.s2),
        FreevaProgressBar(
          value: goal.progress,
          height: 6,
          color: goalBarColor(context, goal),
          semanticsLabel: goal.name,
        ),
      ],
    );
  }
}
