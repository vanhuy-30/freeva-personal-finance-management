import 'package:dartz/dartz.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/insights/domain/insight.dart';
import 'package:mobile/features/insights/domain/insights_repository.dart';
import 'package:mobile/features/insights/presentation/viewmodels/insights_view_model.dart';

const food = InsightCategory(id: 'food', name: 'Ăn uống', iconToken: 'food');
const shopping = InsightCategory(id: 'shop', name: 'Mua sắm');

/// Board S.2 cards in the board's order (the server would put the budget
/// first).
List<Insight> boardInsights() => [
  CategoryChangeInsight(
    category: food,
    currentMinor: BigInt.from(2160000),
    previousMinor: BigInt.from(1600000),
    changePercent: 35,
    up: true,
  ),
  BudgetRiskInsight(
    category: shopping,
    spentMinor: BigInt.from(1800000),
    limitMinor: BigInt.from(2000000),
    percent: 90,
    daysLeft: 20,
  ),
  SpendTrendInsight(
    currentMinor: BigInt.from(5400000),
    previousMinor: BigInt.from(4580000),
    changePercent: 18,
    up: true,
    days: 10,
  ),
  OutlierInsight(
    category: shopping,
    transactionId: 'tx-1',
    merchant: 'Điện máy Xanh',
    occurredOn: '2026-11-08',
    amountMinor: BigInt.from(1250000),
    usualMinor: BigInt.from(420000),
    times: 3,
  ),
];

InsightList boardList() => InsightList(
  currencyCode: 'VND',
  period: const InsightPeriod(
    from: '2026-11-01',
    to: '2026-11-30',
    today: '2026-11-10',
  ),
  items: boardInsights(),
);

class FakeInsightsRepository implements InsightsRepository {
  InsightList answer = InsightList.empty;
  AuthFailure? failure;
  int calls = 0;

  @override
  Future<Either<AuthFailure, InsightList>> list() async {
    calls++;
    return failure == null ? right(answer) : left(failure!);
  }
}

/// Screen stub: fixed items, load does nothing.
class StubInsightsViewModel extends InsightsViewModel {
  StubInsightsViewModel({List<Insight>? items, this.period})
    : items = items ?? boardInsights();

  @override
  final List<Insight> items;
  @override
  final InsightPeriod? period;
  @override
  String? get currencyCode => 'VND';
  @override
  bool get loaded => true;
  @override
  bool get loading => false;
  @override
  AuthFailure? get failure => null;
  int loads = 0;

  @override
  Future<void> load() async => loads++;
}
