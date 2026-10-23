import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/text/vietnamese_fold.dart';

void main() {
  test('folds case and Vietnamese diacritics one char per char', () {
    expect(foldVietnamese('Phở Thìn ĐẶC BIỆT'), 'pho thin dac biet');
    expect(foldVietnamese('Phở').length, 'Phở'.length);
  });

  test('finds every accent-insensitive match with offsets in the original', () {
    expect(foldedMatches('Phở bò, phở gà', 'pho'), [(0, 3), (8, 11)]);
    expect(foldedMatches('Highlands', 'xyz'), isEmpty);
    expect(foldedMatches('Grab', '  '), isEmpty);
  });
}
