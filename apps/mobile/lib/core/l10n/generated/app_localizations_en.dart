import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Freeva';

  @override
  String get splashTagline => 'Your money. Your freedom.';

  @override
  String get homePlaceholder => 'Core loop: wallet → transaction → balance. Features land in lib/features.';

  @override
  String get brandWordmark => 'FREEVA';

  @override
  String get authLogin => 'Sign in';

  @override
  String get authRegister => 'Create account';

  @override
  String get authResendVerification => 'Send verification code';

  @override
  String get authVerifyEmail => 'Verify email';

  @override
  String get authForgotPassword => 'Forgot password';

  @override
  String get authResetPassword => 'Reset password';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHelp => '12–128 characters; spaces are preserved.';

  @override
  String get authEmailCode => '64-character code from email';

  @override
  String get authSuccess => 'Request processed. If you requested a code, check your email if the account is eligible. After verification or password reset, you can sign in.';

  @override
  String get authInvalidInput => 'Check your email, password, email code, or matching six-digit PINs.';

  @override
  String get authInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authInvalidToken => 'Code is invalid, already used, or expired.';

  @override
  String authRateLimited(int seconds) {
    return 'Too many requests. Try again in $seconds seconds.';
  }

  @override
  String get authNetworkError => 'Unable to connect. Check your connection and retry.';

  @override
  String get authStorageError => 'Secure storage is unavailable. Please retry.';

  @override
  String get authUnavailable => 'Unable to complete. Check service configuration or use your PIN if biometrics are unavailable.';

  @override
  String get authWrongPin => 'Incorrect PIN. After five failed attempts, sign in again.';

  @override
  String get authExpired => 'Session expired, was revoked, or PIN attempts exceeded. Please sign in again.';

  @override
  String get authSetupPin => 'Set up PIN';

  @override
  String get authLocked => 'Freeva is locked';

  @override
  String get authPinHelp => 'Use a six-digit PIN to unlock this device.';

  @override
  String get authPin => 'PIN';

  @override
  String get authConfirmPin => 'Confirm PIN';

  @override
  String get authEnableBiometric => 'Enable biometric unlock';

  @override
  String get authBiometricReason => 'Authenticate to unlock Freeva';

  @override
  String get authUnlock => 'Unlock';

  @override
  String get authUseBiometric => 'Use biometrics';

  @override
  String get authForgetDevice => 'Forgot PIN / sign in again';

  @override
  String get authForgetHelp => 'Removes credentials on this device. The server session remains until expiry or revocation in session management.';

  @override
  String get authSessions => 'Manage sessions';

  @override
  String get authCurrentSession => 'Current session';

  @override
  String get authOtherSession => 'Other session';

  @override
  String authSessionExpiry(String date) {
    return 'Expires: $date';
  }

  @override
  String get authRevoke => 'Revoke session';

  @override
  String get authRevokeAll => 'Sign out all sessions';

  @override
  String get authLockNow => 'Lock now';

  @override
  String get authLogout => 'Sign out';

  @override
  String get authWelcomeTitle => 'Welcome to Freeva';

  @override
  String get authWelcomeSubtitle => 'Start your journey to a healthier financial future.';

  @override
  String get authEmailPlaceholder => 'Enter your email';

  @override
  String get authContinue => 'Continue';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authLoginSubtitle => 'Enter your password to pick up where you left off.';

  @override
  String get authCreateTitle => 'Create your Freeva account';

  @override
  String get authRegisterSubtitle => 'Create a password to start taking care of your finances.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authVerifyTitle => 'Check your email';

  @override
  String get authVerifySubtitle => 'Your verification code was sent when you signed up. Enter it below to finish.';

  @override
  String get authVerifyAndContinue => 'Verify and continue';

  @override
  String get authResendCode => 'No code yet? Send again';

  @override
  String get authCodeResent => 'A new code has been requested. Check your inbox and spam folder.';

  @override
  String get authVerifiedNotice => 'Email verified. Sign in to continue.';

  @override
  String get authRecoverTitle => 'Forgot your password?';

  @override
  String get authRecoverSubtitle => 'We’ll send a recovery code to your email.';

  @override
  String get authSendResetCode => 'Send recovery code';

  @override
  String get authNewPasswordTitle => 'Create a new password';

  @override
  String get authResetSubtitle => 'Check your email for a recovery code, then choose a new password.';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authSavePassword => 'Save new password';

  @override
  String get authPasswordChanged => 'Password changed. Sign in with your new password.';

  @override
  String get authPasswordMismatch => 'The passwords don’t match. Please try again.';

  @override
  String get authInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authBack => 'Go back';

  @override
  String get authSecurityNote => 'Your account is protected by your password and app lock.';
}
