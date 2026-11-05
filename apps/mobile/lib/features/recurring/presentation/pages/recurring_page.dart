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
import '../../../categories/domain/finance_category.dart';
import '../../../categories/presentation/viewmodels/category_view_model.dart';
import '../../domain/recurring_rule.dart';
import '../viewmodels/recurring_view_model.dart';
import '../widgets/due_summary_card.dart';
import '../widgets/recurring_labels.dart';
import '../widgets/recurring_paid_sheet.dart';
import '../widgets/recurring_row.dart';

/// Định kỳ và hóa đơn: bills waiting for "Đã trả" on top, then the rules
/// that post on their own. Numbers come from the API as they are.
class RecurringPage extends StatefulWidget {
  const RecurringPage({super.key});

  @override
  State<RecurringPage> createState() => _RecurringPageState();
}

class _RecurringPageState extends State<RecurringPage> {
  late final RecurringViewModel model = getIt<RecurringViewModel>();
  late final CategoryViewModel categories = getIt<CategoryViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      model.load();
      categories.load();
    });
  }

  FinanceCategory? _category(String? id) =>
      categories.categories.where((item) => item.id == id).firstOrNull;

  Future<void> _paid(RecurringRule rule) async {
    final done = await showRecurringPaidSheet(
      context,
      model,
      rule,
      category: _category(rule.categoryId),
    );
    if (done == true && mounted) {
      showFreevaToast(context, message: S.of(context).recConfirmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.recurringTitle,
        onLeading: () => context.popOrGo('/me'),
        action: FreevaIconButton(
          icon: LucideIcons.plus,
          label: s.recurringAdd,
          onPressed: model.loaded
              ? () => context.push('/me/recurring/new')
              : null,
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([model, categories]),
        builder: (context, _) {
          final margin = context.screenMargin;
          if (!model.loaded && model.failure != null) {
            return ErrorRetry(
              title: s.recurringLoadError,
              message: s.homeErrorBody,
              onRetry: model.load,
            );
          }
          if (!model.loaded) {
            return Padding(
              padding: EdgeInsets.all(margin),
              child: const SkeletonRows(count: 4),
            );
          }
          if (model.due.isEmpty && model.automatic.isEmpty) {
            return EmptyState(
              title: s.recurringEmptyTitle,
              message: s.recurringEmptyBody,
              actionLabel: s.recurringAdd,
              onAction: () => context.push('/me/recurring/new'),
            );
          }
          return _Body(
            model: model,
            category: _category,
            onPaid: _paid,
            margin: margin,
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.model,
    required this.category,
    required this.onPaid,
    required this.margin,
  });

  final RecurringViewModel model;
  final FinanceCategory? Function(String?) category;
  final ValueChanged<RecurringRule> onPaid;
  final double margin;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final totalDigits = model.digitsOf(model.totalCurrency);
    final total = formatMoneyText(model.dueTotal, totalDigits, locale);
    return ListView(
      padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 28),
      children: [
        if (model.dueCount > 0) ...[
          DueSummaryCard(
            total: total,
            count: model.dueCount,
            onTap: () => context.push('/me/calendar'),
          ),
          const SizedBox(height: 14),
        ],
        if (model.due.isNotEmpty)
          _Group(
            label: s.recGroupDue,
            children: [
              for (final rule in model.due) _dueRow(context, s, locale, rule),
            ],
          ),
        if (model.due.isNotEmpty && model.automatic.isNotEmpty)
          const SizedBox(height: 14),
        if (model.automatic.isNotEmpty)
          _Group(
            label: s.recGroupAuto,
            children: [
              for (final rule in model.automatic)
                _autoRow(context, s, locale, rule),
            ],
          ),
      ],
    );
  }

  Widget _dueRow(BuildContext context, S s, String locale, RecurringRule rule) {
    final c = context.colors;
    final cat = category(rule.categoryId);
    final days = daysBetween(model.today, rule.nextExecutionDate);
    final (tag, bg, fg) = !rule.active
        ? (s.recTagPaused, c.bgSubtle, c.textOnWash)
        : rule.overdue
        ? (s.recTagOverdue, c.statusDangerBg, c.statusDanger)
        : days == 0
        ? (s.recTagToday, c.statusWarningBg, c.statusWarning)
        : days > 0 && days <= 7
        ? (s.recTagDays(days), c.statusWarningBg, c.statusWarning)
        : (null, null, null);
    return RecurringRow(
      rule: rule,
      category: cat,
      title: ruleTitle(s, rule, cat),
      subtitle: dueLine(
        s,
        rule,
        digits: model.digitsOf(rule.currencyCode),
        locale: locale,
        currency: rule.currencyCode == model.totalCurrency
            ? null
            : rule.currencyCode,
      ),
      amount: '',
      tag: tag,
      tagBackground: bg,
      tagColor: fg,
      minHeight: 72,
      onTap: () => context.push('/me/recurring/${rule.id}'),
      onPaid: rule.active ? () => onPaid(rule) : null,
      paidLabel: s.recPaid,
    );
  }

  Widget _autoRow(
    BuildContext context,
    S s,
    String locale,
    RecurringRule rule,
  ) {
    final c = context.colors;
    final cat = category(rule.categoryId);
    final sign = switch (rule.type) {
      'income' => '+',
      'expense' => '−',
      _ => '',
    };
    final shown = formatMoneyText(
      rule.amountMinor.abs(),
      model.digitsOf(rule.currencyCode),
      locale,
    );
    return RecurringRow(
      rule: rule,
      category: cat,
      title: ruleTitle(s, rule, cat),
      subtitle: scheduleLabel(s, rule),
      amount: '$sign$shown',
      tag: rule.active ? null : s.recTagPaused,
      tagBackground: c.bgSubtle,
      tagColor: c.textOnWash,
      onTap: () => context.push('/me/recurring/${rule.id}'),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: FreevaTypography.sectionLabel.copyWith(
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FreevaCard(
          list: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: c.listDivider),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
