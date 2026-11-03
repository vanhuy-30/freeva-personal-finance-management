import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../budgets/domain/budget.dart';
import '../../../budgets/domain/budget_use_cases.dart';
import '../../../budgets/presentation/widgets/budget_progress_card.dart';
import '../../domain/report.dart';

/// Month-period budget card, or a CTA to set one when none exists.
class ReportBudgetRow extends StatefulWidget {
  const ReportBudgetRow({
    required this.period,
    required this.currency,
    required this.minorDigits,
    super.key,
  });

  final ReportPeriod period;
  final String currency;
  final int minorDigits;

  @override
  State<ReportBudgetRow> createState() => _ReportBudgetRowState();
}

class _ReportBudgetRowState extends State<ReportBudgetRow> {
  BudgetSummary? _budget;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReportBudgetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period.from != widget.period.from ||
        oldWidget.period.to != widget.period.to) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final result = await getIt<BudgetUseCases>().current(
      on: widget.period.from,
    );
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _loading = false;
        _failed = true;
        _budget = null;
      }),
      (current) => setState(() {
        _loading = false;
        _budget = current.budget;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    if (_loading) return const SkeletonBox(height: 120, radius: 24);
    final budget = _budget;
    final budgetsPath =
        '/budgets?on=${Uri.encodeQueryComponent(widget.period.from)}';
    if (budget != null && budget.currencyCode == widget.currency) {
      return BudgetProgressCard(
        summary: budget,
        minorDigits: widget.minorDigits,
        onTap: () => context.push(budgetsPath),
      );
    }
    if (_failed) return const SizedBox.shrink();
    return FreevaCard(
      list: true,
      onTap: () => context.push(budgetsPath),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.tintBlue,
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
            ),
            child: ExcludeSemantics(
              child: Icon(
                LucideIcons.plus,
                size: FreevaSize.iconInline,
                color: c.tintBlueFg,
              ),
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Text(
              s.reportBudgetSet,
              style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 16, color: c.textSecondary),
        ],
      ),
    );
  }
}
