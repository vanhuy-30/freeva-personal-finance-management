import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/freeva_dialog_input.dart';

import 'widget_test_app.dart';

void main() {
  Future<void> open(WidgetTester tester, {required bool obscure}) async {
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showFreevaInputDialog(
              context: context,
              title: 'Nhập mật khẩu để tiếp tục',
              label: 'Mật khẩu',
              obscure: obscure,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  bool hidden(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).obscureText;

  testWidgets('password dialog has an eye button that shows and hides', (
    tester,
  ) async {
    await open(tester, obscure: true);
    expect(hidden(tester), isTrue);
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(hidden(tester), isFalse);
    await tester.tap(find.byTooltip('Ẩn mật khẩu'));
    await tester.pump();
    expect(hidden(tester), isTrue);
  });

  testWidgets('plain dialog has no eye button', (tester) async {
    await open(tester, obscure: false);
    expect(find.byTooltip('Hiện mật khẩu'), findsNothing);
  });
}
