import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/logging/log_scrub.dart';

void main() {
  test('summarizePayload redacts email password token and money', () {
    expect(
      summarizePayload({
        'email': 'user@example.com',
        'password': 'secret',
        'amountMinor': 150000,
        'locale': 'vi',
      }),
      '{email=$logRedactCensor, password=$logRedactCensor, '
      'amountMinor=$logRedactCensor, locale=vi}',
    );
  });

  test('summarizePayload handles empty and nested values', () {
    expect(summarizePayload(null), '{}');
    expect(summarizePayload({}), '{}');
    expect(
      summarizePayload({
        'legs': [
          {'amountMinor': 1},
        ],
      }),
      '{legs=<List<Map<String, int>>>}',
    );
  });
}
