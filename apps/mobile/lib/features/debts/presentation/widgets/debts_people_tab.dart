import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/personal_debt.dart';
import '../viewmodels/debt_view_model.dart';
import 'debt_parts.dart';
import 'debt_row.dart';
import 'debts_empty.dart';

/// Người quen: the two totals, who owes you, whom you owe, and the settled
/// ones behind "Đã xong (n)".
class DebtsPeopleTab extends StatefulWidget {
  const DebtsPeopleTab({required this.model, super.key});

  final DebtViewModel model;

  @override
  State<DebtsPeopleTab> createState() => _DebtsPeopleTabState();
}

class _DebtsPeopleTabState extends State<DebtsPeopleTab> {
  bool _showSettled = false;

  DebtViewModel get model => widget.model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!model.loaded && model.failure != null) {
      return ErrorRetry(
        title: s.debtsLoadError,
        message: s.homeErrorBody,
        onRetry: model.load,
      );
    }
    if (!model.loaded) return const SkeletonRows(count: 3);
    if (model.isEmpty) {
      return DebtsEmpty(
        icon: LucideIcons.handHelping,
        title: s.debtsEmptyTitle,
        body: s.debtsEmptyBody,
        action: s.debtsAdd,
        onAction: () => context.push('/me/debts/new'),
      );
    }
    final owed = model.owedToMe;
    final owe = model.iOwe;
    final settled = model.settled;
    final children = <Widget>[
      _Totals(model: model),
      if (owed.isNotEmpty)
        DebtGroup(
          label: s.debtsGroupOwedToYou,
          children: [for (final d in owed) _row(context, d)],
        ),
      if (owe.isNotEmpty)
        DebtGroup(
          label: s.debtsGroupYouOwe,
          children: [for (final d in owe) _row(context, d)],
        ),
      if (settled.isNotEmpty)
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showSettled = !_showSettled),
            child: Text(
              s.debtsSettledLink(settled.length),
              style: FreevaTypography.bodyM.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.textLink,
              ),
            ),
          ),
        ),
      if (_showSettled && settled.isNotEmpty)
        DebtGroup(
          label: s.debtsGroupSettled,
          children: [for (final d in settled) _row(context, d)],
        ),
    ];
    return RefreshIndicator(
      onRefresh: model.load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, PersonalDebt debt) => DebtRow(
    debt: debt,
    digits: model.digitsOf(debt.currencyCode),
    today: model.today,
    onTap: () => context.push('/me/debts/${debt.id}'),
  );
}

class _Totals extends StatelessWidget {
  const _Totals({required this.model});

  final DebtViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final digits = model.digitsOf(model.totalCurrency);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DebtTotalTile(
              label: s.debtsOwedToYou,
              value: formatMoneyText(model.receivable, digits, locale),
              color: c.moneyIncome,
            ),
          ),
          const SizedBox(width: FreevaSpace.s2),
          Expanded(
            child: DebtTotalTile(
              label: s.debtsYouOwe,
              value: formatMoneyText(model.payable, digits, locale),
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// White card, 14/16 padding: 12 label over a 20/600 amount.
class DebtTotalTile extends StatelessWidget {
  const DebtTotalTile({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: FreevaCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: FreevaTypography.titleS.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
