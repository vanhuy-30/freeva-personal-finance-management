import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/freeva_toast.dart';

Widget _app({required void Function(BuildContext) onTap}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    // A bottom bar and a short body: the old SnackBar could not fit here.
    bottomNavigationBar: const SizedBox(height: 90),
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => onTap(context),
          child: const Text('go'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('shows under the status bar and leaves after its time', (
    t,
  ) async {
    await t.pumpWidget(
      _app(onTap: (c) => showFreevaToast(c, message: 'Đã lưu', success: true)),
    );
    await t.tap(find.text('go'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Đã lưu'), findsOneWidget);
    expect(t.getTopLeft(find.text('Đã lưu')).dy, lessThan(120));
    expect(t.takeException(), isNull);
    await t.pump(const Duration(seconds: 5));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Đã lưu'), findsNothing);
  });

  testWidgets('a new toast replaces the current one; the action runs', (
    t,
  ) async {
    var undone = 0;
    var n = 0;
    await t.pumpWidget(
      _app(
        onTap: (c) {
          n++;
          showFreevaToast(
            c,
            message: 'Toast $n',
            actionLabel: 'Hoàn tác',
            onAction: () => undone++,
          );
        },
      ),
    );
    await t.tap(find.text('go'));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('go'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Toast 1'), findsNothing);
    expect(find.text('Toast 2'), findsOneWidget);
    await t.tap(find.text('Hoàn tác'));
    await t.pump(const Duration(milliseconds: 400));
    expect(undone, 1);
    expect(find.text('Toast 2'), findsNothing);
  });
}
