import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/swipe_actions.dart';

import 'widget_test_app.dart';

Widget _row(String name, List<String> log) => SwipeActions(
  actions: [
    SwipeAction(
      icon: Icons.archive,
      label: 'Ẩn',
      onTap: () => log.add('hide $name'),
    ),
    SwipeAction(
      icon: Icons.delete,
      label: 'Xoá',
      danger: true,
      onTap: () => log.add('delete $name'),
    ),
  ],
  child: SizedBox(
    height: 60,
    child: GestureDetector(
      onTap: () => log.add('open $name'),
      child: Align(alignment: Alignment.centerLeft, child: Text(name)),
    ),
  ),
);

void main() {
  testWidgets('slides left to the actions; a tap on the open row closes it', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(testApp(Column(children: [_row('A', log)])));
    await tester.tap(find.text('A'));
    expect(log, ['open A']);

    await tester.drag(find.text('A'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('A')).dx, lessThan(0));

    // Open: a tap on the row closes it instead of opening the item.
    await tester.tapAt(const Offset(10, 30));
    await tester.pumpAndSettle();
    expect(log, ['open A']);
    expect(tester.getTopLeft(find.text('A')).dx, greaterThanOrEqualTo(0));

    await tester.drag(find.text('A'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ẩn'));
    await tester.pumpAndSettle();
    expect(log, ['open A', 'hide A']);
    expect(tester.getTopLeft(find.text('A')).dx, greaterThanOrEqualTo(0));
  });

  testWidgets('opening another row closes the first', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(
      testApp(Column(children: [_row('A', log), _row('B', log)])),
    );
    await tester.drag(find.text('A'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.text('B'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('A')).dx, greaterThanOrEqualTo(0));
    expect(tester.getTopLeft(find.text('B')).dx, lessThan(0));
  });
}
