import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../reports/presentation/widgets/report_labels.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/net_worth_history.dart';
import '../../domain/net_worth_use_cases.dart';
import '../viewmodels/net_worth_view_model.dart';
import '../widgets/net_worth_breakdown.dart';
import '../widgets/net_worth_chart.dart';
import '../widgets/net_worth_summary.dart';
import '../widgets/net_worth_labels.dart';

/// Board Q.1, opened from the "Tài sản ròng" tile in Cá nhân: net worth
/// today, how it moved over a window, and what it is made of.
class NetWorthPage extends StatefulWidget {
  const NetWorthPage({super.key});

  @override
  State<NetWorthPage> createState() => _NetWorthPageState();
}

class _NetWorthPageState extends State<NetWorthPage> {
  late final NetWorthViewModel model = NetWorthViewModel(
    getIt<NetWorthUseCases>(),
    getIt<AuthViewModel>(),
    getIt<ProfileViewModel>(),
    getIt<WalletViewModel>(),
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(model.load);
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
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
            title: s.netWorthTitle,
            onLeading: () => context.popOrGo('/me'),
          ),
          body: RefreshIndicator(
            onRefresh: model.reload,
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
    const gap = SizedBox(height: FreevaSpace.s4);
    final series = model.data;
    final shown = model.shown;
    if (series == null || shown == null) {
      if (model.failure != null && !model.busy) {
        return [
          ErrorRetry(
            title: reportFailure(s, model.failure!),
            message: s.homeErrorBody,
            onRetry: model.reload,
          ),
        ];
      }
      return const [SkeletonBox(height: 300, radius: 24)];
    }
    return [
      AnimatedOpacity(
        opacity: model.busy ? 0.6 : 1,
        duration: FreevaMotion.fast,
        child: FreevaCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NetWorthSummary(
                series: series,
                shown: shown,
                latest: model.selected == null,
                currency: model.currency,
                digits: model.digits,
                hidden: hidden,
              ),
              if (series.hasChart) ...[
                const SizedBox(height: 20),
                NetWorthChart(
                  series: series,
                  digits: model.digits,
                  hidden: hidden,
                  selected: model.selected,
                  onSelect: model.select,
                ),
              ],
            ],
          ),
        ),
      ),
      if (model.failure != null) ...[
        const SizedBox(height: FreevaSpace.s2),
        Text(
          reportFailure(s, model.failure!),
          style: FreevaTypography.bodyS.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
      gap,
      _Ranges(model: model),
      gap,
      NetWorthBreakdown(
        point: shown,
        currency: model.currency,
        digits: model.digits,
        hidden: hidden,
      ),
    ];
  }
}

class _Ranges extends StatelessWidget {
  const _Ranges({required this.model});

  final NetWorthViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Semantics(
      container: true,
      label: s.netWorthRangeSemantics,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final w in NetWorthWindow.values) ...[
              if (w != NetWorthWindow.values.first) const SizedBox(width: 8),
              FreevaChip(
                label: netWorthRangeLabel(s, w),
                selected: w == model.window,
                onTap: model.busy ? null : () => model.selectWindow(w),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
