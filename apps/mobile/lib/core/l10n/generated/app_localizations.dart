import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Freeva'**
  String get appTitle;

  /// Product-approved splash copy; keep unchanged across locales.
  ///
  /// In en, this message translates to:
  /// **'Your money. Your freedom.'**
  String get splashTagline;

  /// No description provided for @homePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Core loop: wallet → transaction → balance. Features land in lib/features.'**
  String get homePlaceholder;

  /// Official brand wordmark; keep unchanged across locales.
  ///
  /// In en, this message translates to:
  /// **'FREEVA'**
  String get brandWordmark;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegister;

  /// No description provided for @authResendVerification.
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get authResendVerification;

  /// No description provided for @authVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get authVerifyEmail;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get authForgotPassword;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPassword;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'12–128 characters; spaces are preserved.'**
  String get authPasswordHelp;

  /// No description provided for @authEmailCode.
  ///
  /// In en, this message translates to:
  /// **'64-character code from email'**
  String get authEmailCode;

  /// No description provided for @authSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request processed. If you requested a code, check your email if the account is eligible. After verification or password reset, you can sign in.'**
  String get authSuccess;

  /// No description provided for @authInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Check your email, password, email code, or matching six-digit PINs.'**
  String get authInvalidInput;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authInvalidCredentials;

  /// No description provided for @authInvalidToken.
  ///
  /// In en, this message translates to:
  /// **'Code is invalid, already used, or expired.'**
  String get authInvalidToken;

  /// No description provided for @authRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try again in {seconds} seconds.'**
  String authRateLimited(int seconds);

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your connection and retry.'**
  String get authNetworkError;

  /// No description provided for @authStorageError.
  ///
  /// In en, this message translates to:
  /// **'Secure storage is unavailable. Please retry.'**
  String get authStorageError;

  /// No description provided for @authUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete. Check service configuration or use your PIN if biometrics are unavailable.'**
  String get authUnavailable;

  /// No description provided for @authWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. After five failed attempts, sign in again.'**
  String get authWrongPin;

  /// No description provided for @authExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired, was revoked, or PIN attempts exceeded. Please sign in again.'**
  String get authExpired;

  /// No description provided for @authSetupPin.
  ///
  /// In en, this message translates to:
  /// **'Set up PIN'**
  String get authSetupPin;

  /// No description provided for @authLocked.
  ///
  /// In en, this message translates to:
  /// **'Freeva is locked'**
  String get authLocked;

  /// No description provided for @authPinHelp.
  ///
  /// In en, this message translates to:
  /// **'Use a six-digit PIN to unlock this device.'**
  String get authPinHelp;

  /// No description provided for @authPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get authPin;

  /// No description provided for @authConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get authConfirmPin;

  /// No description provided for @authEnableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric unlock'**
  String get authEnableBiometric;

  /// No description provided for @authBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock Freeva'**
  String get authBiometricReason;

  /// No description provided for @authUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get authUnlock;

  /// No description provided for @authUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get authUseBiometric;

  /// No description provided for @authForgetDevice.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN / sign in again'**
  String get authForgetDevice;

  /// No description provided for @authForgetHelp.
  ///
  /// In en, this message translates to:
  /// **'Removes credentials on this device. The server session remains until expiry or revocation in session management.'**
  String get authForgetHelp;

  /// No description provided for @authSessions.
  ///
  /// In en, this message translates to:
  /// **'Manage sessions'**
  String get authSessions;

  /// No description provided for @authCurrentSession.
  ///
  /// In en, this message translates to:
  /// **'Current session'**
  String get authCurrentSession;

  /// No description provided for @authOtherSession.
  ///
  /// In en, this message translates to:
  /// **'Other session'**
  String get authOtherSession;

  /// No description provided for @authSessionExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String authSessionExpiry(String date);

  /// No description provided for @authRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke session'**
  String get authRevoke;

  /// No description provided for @authRevokeAll.
  ///
  /// In en, this message translates to:
  /// **'Sign out all sessions'**
  String get authRevokeAll;

  /// No description provided for @authLockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get authLockNow;

  /// No description provided for @authLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authLogout;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Freeva'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your journey to a healthier financial future.'**
  String get authWelcomeSubtitle;

  /// No description provided for @authEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailPlaceholder;

  /// No description provided for @authContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to pick up where you left off.'**
  String get authLoginSubtitle;

  /// No description provided for @authCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your Freeva account'**
  String get authCreateTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a password to start taking care of your finances.'**
  String get authRegisterSubtitle;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authVerifyTitle;

  /// No description provided for @authVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your verification code was sent when you signed up. Enter it below to finish.'**
  String get authVerifySubtitle;

  /// No description provided for @authVerifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get authVerifyAndContinue;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'No code yet? Send again'**
  String get authResendCode;

  /// No description provided for @authCodeResent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been requested. Check your inbox and spam folder.'**
  String get authCodeResent;

  /// No description provided for @authVerifiedNotice.
  ///
  /// In en, this message translates to:
  /// **'Email verified. Sign in to continue.'**
  String get authVerifiedNotice;

  /// No description provided for @authRecoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authRecoverTitle;

  /// No description provided for @authRecoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We’ll send a recovery code to your email.'**
  String get authRecoverSubtitle;

  /// No description provided for @authSendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send recovery code'**
  String get authSendResetCode;

  /// No description provided for @authNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get authNewPasswordTitle;

  /// No description provided for @authResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email for a recovery code, then choose a new password.'**
  String get authResetSubtitle;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authSavePassword.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get authSavePassword;

  /// No description provided for @authPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Sign in with your new password.'**
  String get authPasswordChanged;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don’t match. Please try again.'**
  String get authPasswordMismatch;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get authBack;

  /// No description provided for @authSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'Your account is protected by your password and app lock.'**
  String get authSecurityNote;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return SEn();
    case 'vi': return SVi();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
