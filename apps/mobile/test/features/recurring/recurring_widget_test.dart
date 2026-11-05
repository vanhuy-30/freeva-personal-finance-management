import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/recurring/domain/recurring_rule.dart';
import 'package:mobile/features/recurring/presentation/pages/recurring_editor_page.dart';
import 'package:mobile/features/recurring/presentation/pages/recurring_page.dart';

import 'recurring_stub.dart';

void main() {
  tearDown(() => getIt.reset());

  Future<RecurringHarness> open(
    WidgetTester t,
    Widget page, {
    List<RecurringRule>? rules,
  }) async {
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(() => recurringApp(page, rules: rules)))!;
    await t.pumpWidget(h.app);
    h.router.push('/page');
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    return h;
  }

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('list sums the pending bills from the data it is given', (
    t,
  ) async {
    final h = await open(t, const RecurringPage());
    // 250.000 + 850.000 + 6.230.000, three bills; nothing typed by hand.
    expect(find.text('Cần trả 7.330.000'), findsOneWidget);
    expect(find.text('3 hóa đơn chưa trả · xem trên lịch'), findsOneWidget);
    expect(find.text('Quá hạn'), findsOneWidget);
    expect(find.text('Còn 2 ngày'), findsOneWidget);
    expect(find.text('Hạn 05/11 · khoảng 850.000'), findsOneWidget);
    expect(find.text('Hạn 15/11 · một lần · 6.230.000'), findsOneWidget);
    expect(find.text('Ngày 5 hằng tháng'), findsOneWidget);
    expect(find.text('+18.500.000'), findsOneWidget);
    expect(find.text('−6.000.000'), findsOneWidget);
    expect(find.text('Tạm dừng'), findsOneWidget);
    expect(h.model.dueCount, 3);
  });

  testWidgets('total follows the data, not the artboard', (t) async {
    await open(
      t,
      const RecurringPage(),
      rules: [
        rule('a', 'Nước', mode: 'remind', amount: -123000, next: '2026-11-20'),
      ],
    );
    expect(find.text('Cần trả 123.000'), findsOneWidget);
    expect(find.text('1 hóa đơn chưa trả · xem trên lịch'), findsOneWidget);
    expect(find.text('Hạn 20/11 · 123.000'), findsOneWidget);
  });

  testWidgets('Đã trả asks for the real amount and confirms the due day', (
    t,
  ) async {
    final h = await open(t, const RecurringPage());
    await t.tap(find.text('Đã trả').at(1));
    await settle(t);
    expect(find.text('Đã trả Tiền điện?'), findsOneWidget);
    await t.enterText(find.byType(TextField), '872000');
    await t.pump();
    await t.tap(find.text('Xác nhận đã trả'));
    await settle(t);
    final sent = h.cases.confirms.single;
    expect(sent.occurredOn, '2026-11-05');
    expect(sent.amountMinor, BigInt.from(872000));
    expect(sent.accountId, 'vcb');
    expect(sent.paidOn, isNull);
    expect(sent.transactionId, isNull);
  });

  testWidgets('keeping the estimate sends no amount override', (t) async {
    final h = await open(t, const RecurringPage());
    await t.tap(find.text('Đã trả').at(1));
    await settle(t);
    await t.tap(find.text('Xác nhận đã trả'));
    await settle(t);
    expect(h.cases.confirms.single.amountMinor, isNull);
  });

  testWidgets('new rule defaults to asking first and saves a bill', (t) async {
    final h = await open(t, const RecurringEditorPage());
    expect(find.text('Hỏi trước khi ghi'), findsOneWidget);
    expect(find.text('Số tiền mỗi kỳ có thể khác'), findsOneWidget);
    expect(find.text('Nhắc trước'), findsOneWidget);
    await t.enterText(find.byType(TextField).at(0), 'Tiền điện');
    await t.enterText(find.byType(TextField).at(1), '850000');
    await t.tap(find.text('Số tiền mỗi kỳ có thể khác'));
    await t.pump();
    await t.tap(find.text('7 ngày'));
    await t.pump();
    await t.tap(find.text('Lưu'));
    await settle(t);
    final d = h.cases.created.single;
    expect(d.mode, 'remind');
    expect(d.name, 'Tiền điện');
    expect(d.amountMinor, BigInt.from(-850000));
    expect(d.amountKind, 'estimated');
    expect(d.remindDaysBefore, 7);
    expect(d.repeat, isTrue);
    expect(d.nextExecutionDate, '2026-11-03');
  });

  testWidgets('income cannot ask first, so it records itself', (t) async {
    await open(t, const RecurringEditorPage());
    await t.tap(find.text('Thu'));
    await t.pump();
    expect(find.text('Nhắc trước'), findsNothing);
    expect(find.text('Số tiền mỗi kỳ có thể khác'), findsNothing);
  });

  testWidgets('editing an auto rule shows Tạm dừng and Xoá định kỳ', (t) async {
    await open(t, const RecurringEditorPage(ruleId: 'rent'));
    expect(find.text('Tạm dừng'), findsOneWidget);
    expect(find.text('Xoá định kỳ'), findsOneWidget);
    expect(find.text('Nhắc trước'), findsNothing);
  });
}
