import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../reports/presentation/widgets/report_labels.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../domain/investment.dart';
import '../viewmodels/investment_view_model.dart';
import '../widgets/investment_labels.dart';
import '../widgets/investment_kind_card.dart';
import '../widgets/investment_share_card.dart';
import '../widgets/investment_summary_card.dart';

/// Đầu tư (boards P.1 and P.2), opened from Cá nhân → Quản lý tiền and from
/// "Đầu tư" on the net worth screen: what is held, what it is worth, and how
/// it splits across categories.
class InvestmentsPage extends StatefulWidget {
  const InvestmentsPage({super.key});

  @override
  State<InvestmentsPage> createState() => _InvestmentsPageState();
}

class _InvestmentsPageState extends State<InvestmentsPage> {
  late final InvestmentViewModel model = getIt<InvestmentViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(model.load);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    return BalancesHiddenBuilder(
      builder: (context, hidden) => ListenableBuilder(
        listenable: model,
        builder: (context, _) => Scaffold(
          appBar: FreevaTopBar(
            title: s.investmentsTitle,
            onLeading: () => context.popOrGo('/me'),
            action: model.loaded && !model.isEmpty
                ? FreevaIconButton(
                    icon: LucideIcons.plus,
                    label: s.investmentAdd,
                    onPressed: () => context.push('/me/investments/new'),
                  )
                : null,
          ),
          body: RefreshIndicator(
            onRefresh: model.load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                margin,
                FreevaSpace.s2,
                margin,
                FreevaSpace.s8,
              ),
              children: _body(context, hidden),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, bool hidden) {
    final s = S.of(context);
    final c = context.colors;
    const gap = SizedBox(height: FreevaSpace.s4);
    if (!model.loaded) {
      if (model.failure != null && !model.loading) {
        return [
          ErrorRetry(
            title: reportFailure(s, model.failure!),
            message: s.homeErrorBody,
            onRetry: model.load,
          ),
        ];
      }
      return const [
        SkeletonBox(height: 200, radius: 24),
        gap,
        SkeletonBox(height: 160, radius: 24),
      ];
    }
    final total = model.total;
    if (model.isEmpty || total == null) {
      return [
        const SizedBox(height: 80),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.tintBlue,
              borderRadius: BorderRadius.circular(FreevaRadius.xl),
            ),
            child: SizedBox.square(
              dimension: 72,
              child: Icon(
                LucideIcons.trendingUp,
                size: 32,
                color: c.tintBlueFg,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          s.investmentsEmptyTitle,
          textAlign: TextAlign.center,
          style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          s.investmentsEmptyBody,
          textAlign: TextAlign.center,
          style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in const [
              InvestmentKind.gold,
              InvestmentKind.savingsDeposit,
              InvestmentKind.stock,
            ])
              FreevaChip(
                label: investmentKindName(s, k),
                selected: false,
                icon: investmentKindIcon(k),
                onTap: () =>
                    context.push('/me/investments/new?kind=${k.apiValue}'),
              ),
          ],
        ),
        const SizedBox(height: 28),
        FreevaButton(
          label: s.investmentAdd,
          size: FreevaButtonSize.l,
          expand: true,
          onPressed: () => context.push('/me/investments/new'),
        ),
      ];
    }
    return [
      InvestmentSummaryCard(
        total: total,
        line: model.line,
        currency: model.currency,
        digits: model.digits,
        hidden: hidden,
      ),
      gap,
      InvestmentShareCard(rows: model.kinds, hidden: hidden),
      SectionHeader(s.investmentsKinds),
      for (final row in model.kinds) ...[
        InvestmentKindCard(
          row: row,
          names: model.names(row.kind!),
          digits: model.digits,
          hidden: hidden,
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}
