import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../domain/recurring_rule.dart';
import '../viewmodels/recurring_view_model.dart';

class RecurringPage extends StatefulWidget {
  const RecurringPage({super.key});

  @override
  State<RecurringPage> createState() => _RecurringPageState();
}

class _RecurringPageState extends State<RecurringPage> {
  late final RecurringViewModel model = getIt<RecurringViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(model.load);
  }

  void _failed() {
    final s = S.of(context);
    final conflict = model.failure?.code == AuthError.conflict;
    showFreevaToast(context, message: conflict ? s.meConflict : s.meSaveError);
    if (conflict) model.load();
  }

  String _unitLabel(S s, RecurringRule rule) {
    final every = rule.interval == 1
        ? null
        : s.recurringEvery(rule.interval.toString());
    final unit = switch (rule.unit) {
      'day' => s.recurringUnitDay,
      'week' => s.recurringUnitWeek,
      'month' => s.recurringUnitMonth,
      _ => s.recurringUnitYear,
    };
    return every == null ? unit : '$every · $unit';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final currency = getIt<ProfileViewModel>().saved?.currency ?? 'VND';
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.recurringTitle,
        onLeading: () => context.popOrGo('/me'),
        action: FreevaIconButton(
          icon: LucideIcons.plus,
          label: s.recurringAdd,
          onPressed: model.loaded ? () => context.push('/me/recurring/new') : null,
        ),
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          if (!model.loaded && model.failure != null) {
            return ErrorRetry(
              title: s.recurringLoadError,
              message: s.homeErrorBody,
              onRetry: model.load,
            );
          }
          if (!model.loaded) {
            return const Padding(
              padding: EdgeInsets.all(FreevaSpace.s4),
              child: SkeletonRows(count: 4),
            );
          }
          if (model.rules.isEmpty) {
            return EmptyState(
              title: s.recurringEmptyTitle,
              message: s.recurringEmptyBody,
              actionLabel: s.recurringAdd,
              onAction: () => context.push('/me/recurring/new'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(FreevaSpace.s4),
            itemCount: model.rules.length,
            separatorBuilder: (_, _) => const SizedBox(height: FreevaSpace.s3),
            itemBuilder: (context, index) {
              final rule = model.rules[index];
              final amount = formatMoneyText(rule.amountMinor.abs(), 0, locale);
              return FreevaCard(
                onTap: () => context.push('/me/recurring/${rule.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${rule.type == 'income' ? '+' : rule.type == 'expense' ? '−' : '↔'} '
                            '$amount $currency',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: FreevaSpace.s1),
                          Text(
                            '${_unitLabel(s, rule)} · ${s.recurringNext(rule.nextExecutionDate)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: rule.active,
                      onChanged: (value) async {
                        if (!await model.setActive(rule, value) && mounted) {
                          _failed();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
