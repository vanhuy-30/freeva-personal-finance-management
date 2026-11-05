import 'auth_use_cases.dart';

/// What a new password has so far, for the ticking list and the strength bar
/// on the sign-up and new-password screens. Length and letter+digit are the
/// rules; a symbol is only a tip.
class PasswordCheck {
  const PasswordCheck(this.password, this.confirmation);

  final String password;
  final String confirmation;

  bool get longEnough => validPasswordLength(password);
  bool get letterAndDigit => hasLetterAndDigit(password);
  bool get hasSymbol =>
      RegExp(r'[^\p{L}\p{Nd}\s]', unicode: true).hasMatch(password);
  bool get matches => password.isNotEmpty && password == confirmation;

  /// Meets every rule the server enforces.
  bool get valid => longEnough && letterAndDigit;

  /// Strength bar: 0 = nothing typed, 1 = not enough yet, 2 = good,
  /// 3 = very strong (rules met plus a symbol or 16+ characters).
  int get strength {
    if (password.isEmpty) return 0;
    if (!valid) return 1;
    return hasSymbol || password.length >= 16 ? 3 : 2;
  }
}
