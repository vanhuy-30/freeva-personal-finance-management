import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/widgets/brand_symbol.dart';
import 'package:mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    await configureDependencies();
  });

  testWidgets('shows splash then home placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FreevaApp());
    await tester.pump();
    expect(find.byType(BrandSymbol), findsNWidgets(3));
    expect(find.text('FREEVA'), findsOneWidget);
    expect(find.text('Your money. Your freedom.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.textContaining('ví'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.textContaining('ví'), findsOneWidget);
    expect(find.byType(BrandSymbol), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
