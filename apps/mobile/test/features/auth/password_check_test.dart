import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/password_check.dart';

void main() {
  String pw(int n) => ('a1' * n).substring(0, n);

  test('length rule is 8 to 128 characters', () {
    expect(PasswordCheck(pw(7), '').longEnough, false);
    expect(PasswordCheck(pw(8), '').longEnough, true);
    expect(PasswordCheck(pw(128), '').longEnough, true);
    expect(PasswordCheck(pw(129), '').longEnough, false);
  });
  test('valid needs length plus a letter and a digit', () {
    expect(PasswordCheck(pw(8), '').valid, true);
    expect(const PasswordCheck('abcdefgh', '').valid, false);
    expect(const PasswordCheck('12345678', '').valid, false);
    expect(const PasswordCheck('a1', '').strength, 1);
    expect(PasswordCheck(pw(8), '').strength, 2);
  });
}
