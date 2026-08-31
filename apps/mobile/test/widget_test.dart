import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    await configureDependencies();
  });

  testWidgets('shows splash then home placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const FreevaApp());
    await tester.pump();
    expect(find.text('Freeva'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    expect(find.textContaining('ví'), findsOneWidget);
  });
}
