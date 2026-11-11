import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/password_check.dart';

import '../../support/server_config_fixture.dart';

void main() {
  String pw(int n) => ('a1' * n).substring(0, n);

  test('length rule is 8 to 128 characters', () {
    expect(PasswordCheck(pw(7), '', testLimits()).longEnough, false);
    expect(PasswordCheck(pw(8), '', testLimits()).longEnough, true);
    expect(PasswordCheck(pw(128), '', testLimits()).longEnough, true);
    expect(PasswordCheck(pw(129), '', testLimits()).longEnough, false);
  });
  test('valid needs length plus a letter and a digit', () {
    expect(PasswordCheck(pw(8), '', testLimits()).valid, true);
    expect(PasswordCheck('abcdefgh', '', testLimits()).valid, false);
    expect(PasswordCheck('12345678', '', testLimits()).valid, false);
    expect(PasswordCheck('a1', '', testLimits()).strength, 1);
    expect(PasswordCheck(pw(8), '', testLimits()).strength, 2);
  });
}
