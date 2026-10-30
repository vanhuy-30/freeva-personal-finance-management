import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/money/display_converted.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/converted_note.dart';

Widget _app(Widget child, {String locale = 'vi'}) => MaterialApp(
  theme: AppTheme.light,
  locale: Locale(locale),
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: child),
);

final _value = DisplayConverted(
  currency: 'VND',
  minor: BigInt.from(308500),
  rate: '25000.00000000',
  quotedAt: DateTime(2026, 10, 30, 9, 5),
);

void main() {
  testWidgets('shows the converted amount, the rate and when it was typed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(ConvertedNote(value: _value, from: 'USD', minorDigits: 0)),
    );
    expect(find.textContaining('≈ 308.500'), findsOneWidget);
    expect(find.textContaining('VND'), findsWidgets);
    expect(
      find.textContaining('1 USD = 25000.00000000 VND'),
      findsOneWidget,
    );
    expect(find.textContaining('09:05, 30/10'), findsOneWidget);
  });

  testWidgets('hides the number the way a balance is hidden', (tester) async {
    await tester.pumpWidget(
      _app(
        ConvertedNote(value: _value, from: 'USD', minorDigits: 0, hidden: true),
      ),
    );
    expect(find.textContaining('308.500'), findsNothing);
    expect(find.textContaining('••••••'), findsOneWidget);
  });

  test('DisplayConverted reads the server block and rejects bad data', () {
    expect(DisplayConverted.fromJson(null), isNull);
    final parsed = DisplayConverted.fromJson({
      'currencyCode': 'VND',
      'amountMinor': '-308500',
      'rate': '25000.00000000',
      'quotedAt': '2026-10-30T02:00:00.000Z',
    })!;
    expect(parsed.minor, BigInt.from(-308500));
    expect(
      () => DisplayConverted.fromJson({
        'currencyCode': 'vnd',
        'amountMinor': '1',
        'rate': '1',
        'quotedAt': '2026-10-30T02:00:00.000Z',
      }),
      throwsFormatException,
    );
    expect(
      () => DisplayConverted.fromJson({
        'currencyCode': 'VND',
        'amountMinor': '1.5',
        'rate': '1',
        'quotedAt': '2026-10-30T02:00:00.000Z',
      }),
      throwsFormatException,
    );
  });
}
