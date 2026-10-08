// ignore: unused_import
import 'package:intl/intl.dart' as intl;
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
  String get homePlaceholder =>
      'Core loop: wallet → transaction → balance. Features land in lib/features.';

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
  String get authSuccess =>
      'Request processed. If you requested a code, check your email if the account is eligible. After verification or password reset, you can sign in.';

  @override
  String get authInvalidInput =>
      'Check your email, password, email code, or matching six-digit PINs.';

  @override
  String get authInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authInvalidToken => 'Code is invalid, already used, or expired.';

  @override
  String authRateLimited(int seconds) {
    return 'Too many requests. Try again in $seconds seconds.';
  }

  @override
  String get authNetworkError =>
      'Unable to connect. Check your connection and retry.';

  @override
  String get authStorageError => 'Secure storage is unavailable. Please retry.';

  @override
  String get authUnavailable =>
      'Unable to complete. Check service configuration or use your PIN if biometrics are unavailable.';

  @override
  String get authWrongPin =>
      'Incorrect PIN. After five failed attempts, sign in again.';

  @override
  String get authExpired =>
      'Session expired, was revoked, or PIN attempts exceeded. Please sign in again.';

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
  String get authForgetHelp =>
      'Removes credentials on this device. The server session remains until expiry or revocation in session management.';

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
  String get authWelcomeSubtitle =>
      'Start your journey to a healthier financial future.';

  @override
  String get authEmailPlaceholder => 'Enter your email';

  @override
  String get authContinue => 'Continue';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authLoginSubtitle =>
      'Enter your password to pick up where you left off.';

  @override
  String get authCreateTitle => 'Create your Freeva account';

  @override
  String get authRegisterSubtitle =>
      'Create a password to start taking care of your finances.';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authVerifyTitle => 'Check your email';

  @override
  String get authVerifySubtitle =>
      'Your verification code was sent when you signed up. Enter it below to finish.';

  @override
  String get authVerifyAndContinue => 'Verify and continue';

  @override
  String get authResendCode => 'No code yet? Send again';

  @override
  String get authCodeResent =>
      'A new code has been requested. Check your inbox and spam folder.';

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
  String get authResetSubtitle =>
      'Check your email for a recovery code, then choose a new password.';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authSavePassword => 'Save new password';

  @override
  String get authPasswordChanged =>
      'Password changed. Sign in with your new password.';

  @override
  String get authPasswordMismatch =>
      'The passwords don’t match. Please try again.';

  @override
  String get authInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authBack => 'Go back';

  @override
  String get authSecurityNote =>
      'Your account is protected by your password and app lock.';

  @override
  String get profileTitle => 'Financial profile';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileVietnamese => 'Vietnamese';

  @override
  String get profileEnglish => 'English';

  @override
  String get profileCurrency => 'Default currency';

  @override
  String get profileCurrencyHint =>
      'Applies to new data by default; existing amounts are not converted.';

  @override
  String get profileTimezone => 'Time zone';

  @override
  String get profileFiscalDay => 'Financial month start day';

  @override
  String get profileFiscalHint =>
      'Choose a day from 1 to 28 so each financial month starts on the same day.';

  @override
  String get profileSave => 'Save changes';

  @override
  String get profileCancel => 'Discard changes';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get profileLoadError =>
      'Could not load your profile. Please try again.';

  @override
  String get profileSaveError =>
      'Changes could not be saved. Please try again.';

  @override
  String get profileConflict =>
      'Your profile changed on another device. Reload before editing.';

  @override
  String get profileReload => 'Reload';

  @override
  String get profileInvalid =>
      'Check the language, currency, time zone and start day (1–28).';

  @override
  String get profileBack => 'Back to home';

  @override
  String get profileSearch => 'Search time zones';

  @override
  String get walletTitle => 'My wallets';

  @override
  String get walletAdd => 'Add wallet';

  @override
  String get walletEdit => 'Edit wallet';

  @override
  String get walletCash => 'Cash';

  @override
  String get walletBank => 'Bank';

  @override
  String get walletEwallet => 'E-wallet';

  @override
  String get walletCredit => 'Credit card';

  @override
  String get walletName => 'Wallet name';

  @override
  String get walletType => 'Wallet type';

  @override
  String get walletInitialBalance => 'Initial balance';

  @override
  String get walletCreditLimit => 'Credit limit (optional)';

  @override
  String get walletCloseDay => 'Statement day (1–28, optional)';

  @override
  String get walletDueDay => 'Payment day (1–28, optional)';

  @override
  String get walletMoneyHint =>
      'Enter amounts in the selected currency without thousands separators. For example: VND 10000; USD 10.50.';

  @override
  String get walletEditHint =>
      'Wallet type and currency cannot change once transactions exist. Edit the initial balance only to correct it.';

  @override
  String get walletShowHidden => 'Show hidden wallets';

  @override
  String get walletHide => 'Hide wallet';

  @override
  String get walletRestore => 'Restore wallet';

  @override
  String get walletHideExplanation =>
      'Hiding archives the wallet from the active list. Its balance and history are preserved and it can be restored later.';

  @override
  String get walletMoveUp => 'Move up';

  @override
  String get walletMoveDown => 'Move down';

  @override
  String get walletEmpty =>
      'No wallets yet. Add your first wallet to get started.';

  @override
  String get walletHiddenEmpty => 'No hidden wallets.';

  @override
  String walletBalance(String amount, String currency) {
    return 'Balance: $amount $currency';
  }

  @override
  String get walletInvalid =>
      'Check the name, amounts and days (1–28). Type or currency may be locked because transactions exist.';

  @override
  String get walletConflict =>
      'This wallet changed elsewhere. Return to the list and reload before editing again.';

  @override
  String get walletError => 'Could not load or save wallets. Please try again.';

  @override
  String get walletReloadRequired =>
      'The operation may have been partially saved. Reload the list to get the latest state.';
}
