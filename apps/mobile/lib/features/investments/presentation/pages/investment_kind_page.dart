import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../reports/presentation/widgets/report_labels.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../domain/investment.dart';
import '../viewmodels/investment_view_model.dart';
import '../widgets/investment_asset_card.dart';
import '../widgets/investment_kind_header.dart';
import '../widgets/investment_labels.dart';
import '../widgets/investment_price_sheet.dart';
import '../widgets/investment_sell_sheet.dart';

/// One category (board P.3): what is held in it, each asset with its price,
/// buys and Mua thêm · Bán, and what was already sold.
class InvestmentKindPage extends StatefulWidget {
  const InvestmentKindPage({required this.kind, super.key});

  final InvestmentKind kind;

  @override
  State<InvestmentKindPage> createState() => _InvestmentKindPageState();
}

class _InvestmentKindPageState extends State<InvestmentKindPage> {
  late final InvestmentViewModel model = getIt<InvestmentViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    await model.load();
    if (!mounted) return;
    await model.loadTrades([for (final i in model.ofKind(widget.kind)) i.id]);
  }

  void _buyMore(Investment i) => context.push(
    Uri(
      path: '/me/investments/new',
      queryParameters: {
        'kind': i.kind.apiValue,
        'name': i.name,
        'unit': i.unit,
      },
    ).toString(),
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    return BalancesHiddenBuilder(
      builder: (context, hidden) => ListenableBuilder(
        listenable: model,
        builder: (context, _) => Scaffold(
          appBar: FreevaTopBar(
            title: investmentKindName(s, widget.kind),
            onLeading: () => context.popOrGo('/me/investments'),
            action: FreevaIconButton(
              icon: LucideIcons.plus,
              label: s.investmentAdd,
              onPressed: () => context.push(
                '/me/investments/new?kind=${widget.kind.apiValue}',
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _load,
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
    final locale = Localizations.localeOf(context).toString();
    const gap = SizedBox(height: 12);
    if (!model.loaded) {
      if (model.failure != null && !model.loading) {
        return [
          ErrorRetry(
            title: reportFailure(s, model.failure!),
            message: s.homeErrorBody,
            onRetry: _load,
          ),
        ];
      }
      return const [
        SkeletonBox(height: 200, radius: 24),
        gap,
        SkeletonBox(height: 260, radius: 24),
      ];
    }
    final kind = widget.kind;
    final row = model.kinds.where((r) => r.kind == kind).firstOrNull;
    final assets = model.ofKind(kind);
    if (row == null || assets.isEmpty) return const [];
    final units = {for (final a in assets) a.unit};
    final sum = assets.fold<BigInt>(
      BigInt.zero,
      (a, i) => a + (parseQuantityApi(i.quantity) ?? BigInt.zero),
    );
    final sold = model.soldOf(kind);
    return [
      InvestmentKindHeader(
        row: row,
        quantity: units.length == 1 && !kind.singleLot
            ? investmentQuantityText(s, sum, units.first, locale)
            : null,
        currency: model.currency,
        digits: model.digits,
        hidden: hidden,
      ),
      const SizedBox(height: 14),
      for (final a in assets) ...[
        InvestmentAssetCard(
          investment: a,
          buys: model.buysOf(a.id),
          digits: model.digits,
          hidden: hidden,
          onPrice: () => showInvestmentPriceSheet(context, model, a),
          onBuyMore: () => _buyMore(a),
          onSell: () => showInvestmentSellSheet(context, model, a),
        ),
        gap,
      ],
      if (sold != null)
        _SoldRow(
          text: hidden
              ? s.investmentSold
              : sold.unit == null
              ? s.investmentSoldGain(
                  investmentSigned(sold.realized, model.digits, locale),
                )
              : s.investmentSoldLine(
                  investmentQuantityText(s, sold.quantity, sold.unit!, locale),
                  investmentSigned(sold.realized, model.digits, locale),
                ),
          title: s.investmentSold,
        ),
    ];
  }
}

class _SoldRow extends StatelessWidget {
  const _SoldRow({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => SettingsRow(
    icon: LucideIcons.badgeCheck,
    title: title,
    subtitle: text,
    chevron: false,
  );
}
