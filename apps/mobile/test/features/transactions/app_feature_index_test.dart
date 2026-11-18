import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/features/transactions/domain/app_feature_index.dart';

void main() {
  late S s;
  setUpAll(() async => s = await S.delegate.load(const Locale('vi')));

  List<String> routes(String q) => [
    for (final f in matchFeatures(s, q)) f.route,
  ];

  test('finds a feature by title, without accents, or by a keyword', () {
    expect(routes('danh muc'), contains('/categories'));
    expect(routes('Ví'), contains('/wallets'));
    expect(routes('mat khau'), contains('/me/security/password'));
    expect(routes('export'), contains('/me/export'));
    expect(routes('xuat'), contains('/me/export'));
  });

  test('a blank or one-letter query finds nothing by keyword', () {
    expect(routes(''), isEmpty);
    expect(routes('   '), isEmpty);
  });

  test('every feature has a route and a title; shortcuts exist', () {
    for (final f in appFeatures) {
      expect(f.route, startsWith('/'));
      expect(f.label(s), isNotEmpty);
    }
    expect(quickFeatures(), hasLength(6));
  });
}
