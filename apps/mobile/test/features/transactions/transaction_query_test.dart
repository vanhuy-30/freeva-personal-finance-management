import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/transactions/data/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

import 'transaction_fakes.dart';

void main() {
  test('multi-value filters are sent as repeated keys', () async {
    final api = ScriptedApi();
    final repo = TransactionRepositoryImpl(api);
    await repo.list(
      const TransactionQuery(
        pageSize: 1,
        from: '2026-10-01',
        to: '2026-10-31',
        accountIds: ['a', 'b'],
        categoryIds: ['food'],
        tagIds: ['t'],
        search: 'phở bò',
      ),
    );
    final uri = Uri.parse('http://local/${api.calls.single.path}');
    expect(uri.queryParametersAll['accountId'], ['a', 'b']);
    expect(uri.queryParametersAll['categoryId'], ['food']);
    expect(uri.queryParametersAll['tagId'], ['t']);
    expect(uri.queryParameters['from'], '2026-10-01');
    expect(uri.queryParameters['to'], '2026-10-31');
    expect(uri.queryParameters['pageSize'], '1');
    expect(uri.queryParameters['search'], 'phở bò');
  });

  test('summary is parsed, and missing summary reads as empty', () async {
    final api = ScriptedApi()
      ..summary = {
        'count': 3,
        'totals': [
          {'currency': 'VND', 'incomeMinor': '100', 'expenseMinor': '-40'},
        ],
      };
    final page = (await TransactionRepositoryImpl(
      api,
    ).list(const TransactionQuery())).getOrElse(() => throw StateError('list'));
    expect(page.summary.count, 3);
    expect(page.summary.totals.single.income, BigInt.from(100));
    expect(page.summary.totals.single.expense, BigInt.from(-40));
    api.summary = null;
    final empty = (await TransactionRepositoryImpl(
      api,
    ).list(const TransactionQuery())).getOrElse(() => throw StateError('list'));
    expect(empty.summary.count, 0);
  });
}
