import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/investments/domain/investment_use_cases.dart';
import 'package:mobile/features/investments/presentation/viewmodels/investment_view_model.dart';
import 'package:mobile/features/net_worth/domain/net_worth_history.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';

import '../auth/fakes.dart';
import '../forecast/forecast_stub.dart' show ForecastWallets;
import '../home/fixtures.dart' show b;
import '../profile/fakes.dart';

Investment position(
  String id,
  InvestmentKind kind,
  String name, {
  int cost = 0,
  int? value,
  int? bps,
  String unit = 'unit',
  String quantity = '1',
  int? price,
  int? rate,
  String? start,
  String? maturity,
}) => Investment(
  id: id,
  clientId: id,
  kind: kind,
  name: name,
  currencyCode: 'VND',
  unit: unit,
  quantity: quantity,
  costBasisMinor: b(cost),
  currentValueMinor: b(value ?? cost),
  valuation: bps == null ? InvestmentValuation.cost : InvestmentValuation.price,
  version: 1,
  unrealizedMinor: bps == null ? null : b((value ?? cost) - cost),
  unrealizedBps: bps,
  latestPriceMinor: price == null ? null : b(price),
  latestPriceAt: price == null ? null : DateTime(2026, 11, 5, 9),
  interestRateBps: rate,
  startDate: start,
  maturityDate: maturity,
);

InvestmentTotal total({
  InvestmentKind? kind,
  required int cost,
  required int value,
  int? bps,
  int? share,
  int count = 1,
}) => InvestmentTotal(
  currencyCode: 'VND',
  costBasisMinor: b(cost),
  currentValueMinor: b(value),
  unrealizedMinor: b(bps == null ? 0 : value - cost),
  unrealizedBps: bps,
  unpricedCount: bps == null ? count : 0,
  kind: kind,
  investmentCount: count,
  shareBps: share,
);

/// Board P.2: real estate, a deposit, gold, and an unpriced stock.
class FakeInvestmentUseCases implements InvestmentUseCases {
  AuthFailure? failure;
  bool historyFails = false;
  List<Investment> items = [
    position(
      're',
      InvestmentKind.realEstate,
      'Đất nền Long An',
      cost: 600000000,
      value: 650000000,
      bps: 833,
    ),
    position(
      'dep',
      InvestmentKind.savingsDeposit,
      'VCB 12 tháng',
      cost: 100000000,
      value: 102813699,
      bps: 281,
      unit: 'deposit',
      rate: 650,
      start: '2026-06-01',
      maturity: '2027-06-01',
    ),
    position(
      'g1',
      InvestmentKind.gold,
      'Vàng SJC',
      cost: 50000000,
      value: 56000000,
      bps: 1200,
      unit: 'chi',
      quantity: '7',
      price: 8000000,
    ),
    position(
      'g2',
      InvestmentKind.gold,
      'Vàng nhẫn 9999',
      cost: 12000000,
      value: 16000000,
      bps: 3333,
      unit: 'chi',
      quantity: '2',
      price: 8000000,
    ),
    position('s1', InvestmentKind.stock, 'VNM', cost: 9000000),
  ];
  InvestmentSummary summaryValue = InvestmentSummary(
    totals: [total(cost: 749000000, value: 800813699, bps: 826)],
    byKind: [
      total(
        kind: InvestmentKind.realEstate,
        cost: 600000000,
        value: 650000000,
        bps: 833,
        share: 8116,
      ),
      total(
        kind: InvestmentKind.savingsDeposit,
        cost: 100000000,
        value: 102813699,
        bps: 281,
        share: 1284,
      ),
      total(
        kind: InvestmentKind.gold,
        cost: 62000000,
        value: 72000000,
        bps: 1613,
        share: 600,
        count: 2,
      ),
      total(kind: InvestmentKind.stock, cost: 9000000, value: 9000000),
    ],
  );
  List<Map<String, int>> history = [
    {'a': 700000000},
    {'a': 760000000},
    {'a': 800813699},
  ];

  @override
  Future<Either<AuthFailure, List<Investment>>> list() async =>
      failure != null ? left(failure!) : right(items);

  @override
  Future<Either<AuthFailure, InvestmentSummary>> summary() async =>
      failure != null ? left(failure!) : right(summaryValue);

  final created = <InvestmentDraft>[];
  final sold = <SellDraft>[];
  final priced = <BigInt>[];
  Map<String, List<InvestmentTrade>> tradeMap = {
    'g1': [
      _trade('b1', TradeSide.buy, 5, 7000000, '2026-09-10', 1429),
      _trade('b2', TradeSide.buy, 2, 7500000, '2026-09-25', 667),
      _trade(
        's1',
        TradeSide.sell,
        6,
        8000000,
        '2026-10-20',
        null,
        realized: 5000000,
      ),
    ],
    'dep': [_trade('d1', TradeSide.buy, 1, 100000000, '2026-06-01', 281)],
    'g2': [
      _trade(
        'b3',
        TradeSide.buy,
        2,
        6000000,
        '2026-08-01',
        3333,
        existing: true,
      ),
    ],
  };

  @override
  Future<Either<AuthFailure, List<InvestmentTrade>>> trades(String id) async =>
      right(tradeMap[id] ?? const []);

  @override
  Future<Either<AuthFailure, Investment>> sell(
    Investment investment,
    SellDraft draft,
  ) async {
    sold.add(draft);
    if (failure != null) return left(failure!);
    return right(investment);
  }

  final updated = <({String name, String? note, String? maturity})>[];
  final deletedTrades = <String>[];

  @override
  Future<Either<AuthFailure, Investment>> update(
    Investment investment, {
    required String name,
    required String? note,
    required String? maturityDate,
  }) async {
    updated.add((name: name, note: note, maturity: maturityDate));
    if (failure != null) return left(failure!);
    return right(investment);
  }

  final edited = <TradeEdit>[];

  @override
  Future<Either<AuthFailure, Investment>> updateTrade(
    Investment investment,
    String tradeId,
    TradeEdit edit,
  ) async {
    edited.add(edit);
    if (failure != null) return left(failure!);
    return right(investment);
  }

  @override
  Future<Either<AuthFailure, Unit>> deleteTrade(
    Investment investment,
    String tradeId,
  ) async {
    deletedTrades.add(tradeId);
    if (failure != null) return left(failure!);
    final buys = (tradeMap[investment.id] ?? const <InvestmentTrade>[])
        .where((t) => t.side == TradeSide.buy)
        .length;
    if (buys <= 1) {
      items = [
        for (final i in items)
          if (i.id != investment.id) i,
      ];
    }
    return right(unit);
  }

  @override
  Future<Either<AuthFailure, Investment>> addPrice(
    Investment investment, {
    required String clientId,
    required BigInt priceMinor,
    required DateTime quotedAt,
  }) async {
    priced.add(priceMinor);
    if (failure != null) return left(failure!);
    return right(investment);
  }

  @override
  Future<Either<AuthFailure, Investment>> create(InvestmentDraft draft) async {
    created.add(draft);
    if (failure != null) return left(failure!);
    final saved = position(
      'new',
      draft.kind,
      draft.name,
      cost: (draft.amountMinor ?? BigInt.zero).toInt(),
    );
    items = [...items, saved];
    return right(saved);
  }

  @override
  Future<Either<AuthFailure, List<InvestmentValuePoint>>> valueLine(
    NetWorthWindow window, {
    required String currency,
  }) async {
    if (historyFails) return left(const AuthFailure(AuthError.unavailable));
    return right([
      for (var i = 0; i < history.length; i++)
        InvestmentValuePoint(
          asOf: '2026-0${i + 1}-28',
          valueMinor: b(history[i]['a']!),
        ),
    ]);
  }
}

Future<
  ({
    FakeInvestmentUseCases cases,
    InvestmentViewModel model,
    Widget app,
    GoRouter router,
  })
>
investmentApp(
  Widget page, {
  bool dark = false,
  FakeInvestmentUseCases? cases,
}) async {
  await getIt.reset();
  final repo = AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics());
  final auth = DefaultAuthViewModel(DefaultAuthUseCases(repo))
    ..stage = AuthStage.unlocked
    ..hasPin = true
    ..ready = true;
  final profiles = MemoryProfiles()
    ..value = const Profile(
      locale: 'vi',
      currency: 'VND',
      timezone: 'Asia/Ho_Chi_Minh',
      fiscalDay: 1,
      version: 1,
      displayName: 'Minh',
    );
  final profile = DefaultProfileViewModel(
    ProfileUseCases(profiles),
    auth,
    exportCase(repo),
  );
  await profile.load();
  final fake = cases ?? FakeInvestmentUseCases();
  final model = InvestmentViewModel(fake, profile, ForecastWallets(), auth);
  getIt
    ..registerSingleton<AuthViewModel>(auth)
    ..registerSingleton<WalletViewModel>(ForecastWallets())
    ..registerSingleton<ProfileViewModel>(profile)
    ..registerSingleton<InvestmentViewModel>(model);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/page', builder: (context, state) => page),
      GoRoute(path: '/me', builder: (context, state) => const SizedBox()),
    ],
  );
  final app = MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    routerConfig: router,
  );
  return (cases: fake, model: model, app: app, router: router);
}

InvestmentTrade _trade(
  String id,
  TradeSide side,
  int chi,
  int price,
  String day,
  int? bps, {
  int? realized,
  bool existing = false,
}) => InvestmentTrade(
  id: id,
  clientId: id,
  side: side,
  quantity: BigInt.from(chi) * BigInt.from(100000000),
  amountMinor: b(chi * price),
  unitPriceMinor: b(price),
  tradedOn: day,
  realizedMinor: realized == null ? null : b(realized),
  accountId: existing || side == TradeSide.sell
      ? (existing ? null : 'vcb')
      : 'vcb',
  currentValueMinor: bps != null && side == TradeSide.buy
      ? b(chi * 8000000)
      : null,
  unrealizedMinor: bps != null && side == TradeSide.buy
      ? b(chi * 8000000 - chi * price)
      : null,
  unrealizedBps: bps,
);
