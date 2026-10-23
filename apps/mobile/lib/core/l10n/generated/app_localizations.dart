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
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
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

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial profile'**
  String get profileTitle;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get profileVietnamese;

  /// No description provided for @profileEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profileEnglish;

  /// No description provided for @profileCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get profileCurrency;

  /// No description provided for @profileCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Applies to new data by default; existing amounts are not converted.'**
  String get profileCurrencyHint;

  /// No description provided for @profileTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get profileTimezone;

  /// No description provided for @profileFiscalDay.
  ///
  /// In en, this message translates to:
  /// **'Financial month start day'**
  String get profileFiscalDay;

  /// No description provided for @profileFiscalHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a day from 1 to 28 so each financial month starts on the same day.'**
  String get profileFiscalHint;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSave;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get profileCancel;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Please try again.'**
  String get profileLoadError;

  /// No description provided for @profileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Changes could not be saved. Please try again.'**
  String get profileSaveError;

  /// No description provided for @profileConflict.
  ///
  /// In en, this message translates to:
  /// **'Your profile changed on another device. Reload before editing.'**
  String get profileConflict;

  /// No description provided for @profileReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get profileReload;

  /// No description provided for @profileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the language, currency, time zone and start day (1–28).'**
  String get profileInvalid;

  /// No description provided for @profileBack.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get profileBack;

  /// No description provided for @profileSearch.
  ///
  /// In en, this message translates to:
  /// **'Search time zones'**
  String get profileSearch;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'My wallets'**
  String get walletTitle;

  /// No description provided for @walletAdd.
  ///
  /// In en, this message translates to:
  /// **'Add wallet'**
  String get walletAdd;

  /// No description provided for @walletEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit wallet'**
  String get walletEdit;

  /// No description provided for @walletCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get walletCash;

  /// No description provided for @walletBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get walletBank;

  /// No description provided for @walletEwallet.
  ///
  /// In en, this message translates to:
  /// **'E-wallet'**
  String get walletEwallet;

  /// No description provided for @walletCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get walletCredit;

  /// No description provided for @walletName.
  ///
  /// In en, this message translates to:
  /// **'Wallet name'**
  String get walletName;

  /// No description provided for @walletType.
  ///
  /// In en, this message translates to:
  /// **'Wallet type'**
  String get walletType;

  /// No description provided for @walletInitialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get walletInitialBalance;

  /// No description provided for @walletHide.
  ///
  /// In en, this message translates to:
  /// **'Hide wallet'**
  String get walletHide;

  /// No description provided for @walletHiddenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No hidden wallets.'**
  String get walletHiddenEmpty;

  /// No description provided for @walletInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the name and amounts.'**
  String get walletInvalid;

  /// No description provided for @walletConflict.
  ///
  /// In en, this message translates to:
  /// **'This wallet changed elsewhere. Open it again to edit.'**
  String get walletConflict;

  /// No description provided for @walletError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the wallet. Try again.'**
  String get walletError;

  /// No description provided for @transactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionTitle;

  /// No description provided for @transactionRecord.
  ///
  /// In en, this message translates to:
  /// **'Record transaction'**
  String get transactionRecord;

  /// No description provided for @transactionExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionExpense;

  /// No description provided for @transactionIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionIncome;

  /// No description provided for @transactionTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionTransfer;

  /// No description provided for @transactionAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transactionAll;

  /// No description provided for @transactionAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionAmount;

  /// No description provided for @transactionWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get transactionWallet;

  /// No description provided for @transactionDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination wallet'**
  String get transactionDestination;

  /// No description provided for @transactionCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionCategory;

  /// No description provided for @transactionAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get transactionAllCategories;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionDate;

  /// No description provided for @transactionNotes.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get transactionNotes;

  /// No description provided for @transactionMerchant.
  ///
  /// In en, this message translates to:
  /// **'Payee / merchant'**
  String get transactionMerchant;

  /// No description provided for @transactionTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get transactionTags;

  /// No description provided for @transactionTagCreate.
  ///
  /// In en, this message translates to:
  /// **'Create tag'**
  String get transactionTagCreate;

  /// No description provided for @transactionTagCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new tag'**
  String get transactionTagCreateTitle;

  /// No description provided for @transactionTagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get transactionTagName;

  /// No description provided for @transactionTagLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to 20 tags'**
  String get transactionTagLimit;

  /// No description provided for @transactionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transactionSave;

  /// No description provided for @transactionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get transactionEdit;

  /// No description provided for @transactionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get transactionCopy;

  /// No description provided for @transactionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transactionDelete;

  /// No description provided for @transactionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get transactionRestore;

  /// No description provided for @transactionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get transactionDeleteTitle;

  /// No description provided for @transactionDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The transaction is soft-deleted and no longer counts toward the balance.'**
  String get transactionDeleteBody;

  /// No description provided for @transactionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get transactionCancel;

  /// No description provided for @transactionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get transactionEmpty;

  /// No description provided for @transactionDeletedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deleted transactions.'**
  String get transactionDeletedEmpty;

  /// No description provided for @transactionNoWallet.
  ///
  /// In en, this message translates to:
  /// **'Add an active wallet before recording a transaction.'**
  String get transactionNoWallet;

  /// No description provided for @transactionCreateWallet.
  ///
  /// In en, this message translates to:
  /// **'Create wallet'**
  String get transactionCreateWallet;

  /// No description provided for @transactionShowDeleted.
  ///
  /// In en, this message translates to:
  /// **'Show deleted transactions'**
  String get transactionShowDeleted;

  /// No description provided for @transactionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get transactionSearch;

  /// No description provided for @transactionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the amount, wallet, category, date, or exchange rate. Expenses need a category. A cross-currency transfer accepts only an exact rate.'**
  String get transactionInvalid;

  /// No description provided for @transactionConflict.
  ///
  /// In en, this message translates to:
  /// **'This transaction changed elsewhere. Reload the list before editing again.'**
  String get transactionConflict;

  /// No description provided for @transactionError.
  ///
  /// In en, this message translates to:
  /// **'Could not load or save transactions. Please try again.'**
  String get transactionError;

  /// No description provided for @transactionReloadRequired.
  ///
  /// In en, this message translates to:
  /// **'The data is stale. Reload before recording again.'**
  String get transactionReloadRequired;

  /// No description provided for @transactionRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get transactionRate;

  /// No description provided for @transactionRateHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a manual rate. The destination amount must match the smallest currency unit exactly.'**
  String get transactionRateHint;

  /// No description provided for @transactionLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get transactionLoadMore;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} changes waiting to sync'**
  String syncPending(int count);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncing;

  /// No description provided for @syncConflict.
  ///
  /// In en, this message translates to:
  /// **'Not overwritten. Reload to see the copy on the server.'**
  String get syncConflict;

  /// No description provided for @syncReview.
  ///
  /// In en, this message translates to:
  /// **'The amount differs from the saved copy. Not overwritten.'**
  String get syncReview;

  /// No description provided for @syncFailedItem.
  ///
  /// In en, this message translates to:
  /// **'This change could not be synced.'**
  String get syncFailedItem;

  /// No description provided for @syncDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get syncDiscard;

  /// No description provided for @syncSchema.
  ///
  /// In en, this message translates to:
  /// **'Sync is paused because the app and server schemas differ.'**
  String get syncSchema;

  /// No description provided for @syncDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A similar transaction may already exist. This one was still kept.'**
  String get syncDuplicate;

  /// No description provided for @syncDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get syncDelete;

  /// No description provided for @syncRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get syncRestore;

  /// No description provided for @syncChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get syncChange;

  /// No description provided for @syncItem.
  ///
  /// In en, this message translates to:
  /// **'{action} · {date}'**
  String syncItem(String action, String date);

  /// No description provided for @categoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoryTitle;

  /// No description provided for @categoryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoryAdd;

  /// No description provided for @categoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoryEdit;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryParent.
  ///
  /// In en, this message translates to:
  /// **'Parent category'**
  String get categoryParent;

  /// No description provided for @categoryNoParent.
  ///
  /// In en, this message translates to:
  /// **'No parent'**
  String get categoryNoParent;

  /// No description provided for @categoryColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryColor;

  /// No description provided for @categoryNoColor.
  ///
  /// In en, this message translates to:
  /// **'No color'**
  String get categoryNoColor;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryIcon;

  /// No description provided for @categoryNoIcon.
  ///
  /// In en, this message translates to:
  /// **'No icon'**
  String get categoryNoIcon;

  /// No description provided for @categorySystem.
  ///
  /// In en, this message translates to:
  /// **'Default category'**
  String get categorySystem;

  /// No description provided for @categoryShowHidden.
  ///
  /// In en, this message translates to:
  /// **'Show hidden categories'**
  String get categoryShowHidden;

  /// No description provided for @categoryHide.
  ///
  /// In en, this message translates to:
  /// **'Hide category'**
  String get categoryHide;

  /// No description provided for @categoryRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore category'**
  String get categoryRestore;

  /// No description provided for @categoryHideExplanation.
  ///
  /// In en, this message translates to:
  /// **'Hiding archives the category from the active list. Existing transactions keep it; hidden categories cannot be used for new records.'**
  String get categoryHideExplanation;

  /// No description provided for @categoryHideBlocked.
  ///
  /// In en, this message translates to:
  /// **'Hide or move active child categories before hiding this one.'**
  String get categoryHideBlocked;

  /// No description provided for @categoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get categoryDelete;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this category permanently?'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'A deleted category cannot be restored. If any transaction still references it, including a soft-deleted one, choose a replacement.'**
  String get categoryDeleteBody;

  /// No description provided for @categoryDeleteBlocked.
  ///
  /// In en, this message translates to:
  /// **'Delete or move every child, including hidden ones, before deleting this category.'**
  String get categoryDeleteBlocked;

  /// No description provided for @categoryReplacement.
  ///
  /// In en, this message translates to:
  /// **'Replacement category'**
  String get categoryReplacement;

  /// No description provided for @categoryNoReplacement.
  ///
  /// In en, this message translates to:
  /// **'Do not move transactions'**
  String get categoryNoReplacement;

  /// No description provided for @categoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get categoryEmpty;

  /// No description provided for @categoryHiddenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No hidden categories.'**
  String get categoryHiddenEmpty;

  /// No description provided for @categoryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the name (1–100 characters), parent, color and icon. A category cannot be its own parent or sit under its child.'**
  String get categoryInvalid;

  /// No description provided for @categoryConflict.
  ///
  /// In en, this message translates to:
  /// **'This category changed elsewhere. Reload the list before editing again.'**
  String get categoryConflict;

  /// No description provided for @categoryError.
  ///
  /// In en, this message translates to:
  /// **'Could not load or save categories. Please try again.'**
  String get categoryError;

  /// No description provided for @categoryReloadRequired.
  ///
  /// In en, this message translates to:
  /// **'The data is stale. Reload before editing again.'**
  String get categoryReloadRequired;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportTitle;

  /// No description provided for @reportOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get reportOverview;

  /// No description provided for @reportThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get reportThisMonth;

  /// No description provided for @reportNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get reportNetWorth;

  /// No description provided for @reportAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get reportAssets;

  /// No description provided for @reportLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get reportLiabilities;

  /// No description provided for @reportIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reportIncome;

  /// No description provided for @reportExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get reportExpense;

  /// No description provided for @reportNet.
  ///
  /// In en, this message translates to:
  /// **'Cashflow'**
  String get reportNet;

  /// No description provided for @reportTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get reportTransfer;

  /// No description provided for @reportWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get reportWeek;

  /// No description provided for @reportMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get reportMonth;

  /// No description provided for @reportRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get reportRange;

  /// No description provided for @reportPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get reportPrevious;

  /// No description provided for @reportNext.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get reportNext;

  /// No description provided for @reportFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get reportFrom;

  /// No description provided for @reportTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get reportTo;

  /// No description provided for @reportApply.
  ///
  /// In en, this message translates to:
  /// **'Show this range'**
  String get reportApply;

  /// No description provided for @reportByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get reportByCategory;

  /// No description provided for @reportByAccount.
  ///
  /// In en, this message translates to:
  /// **'By wallet'**
  String get reportByAccount;

  /// No description provided for @reportUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get reportUncategorized;

  /// No description provided for @reportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show for this period.'**
  String get reportEmpty;

  /// No description provided for @reportError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the report. Please try again.'**
  String get reportError;

  /// No description provided for @reportInvalid.
  ///
  /// In en, this message translates to:
  /// **'That date range is invalid. The start must be on or before the end, and the dates can be at most 3660 days apart.'**
  String get reportInvalid;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String reportPeriod(String from, String to);

  /// No description provided for @reportAmount.
  ///
  /// In en, this message translates to:
  /// **'{label}: {amount} {currency}'**
  String reportAmount(String label, String amount, String currency);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get settingsBack;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Language, currency, and time zone'**
  String get settingsProfile;

  /// No description provided for @settingsPermissions.
  ///
  /// In en, this message translates to:
  /// **'System access'**
  String get settingsPermissions;

  /// No description provided for @settingsBiometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get settingsBiometric;

  /// No description provided for @settingsBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to change biometric unlock'**
  String get settingsBiometricReason;

  /// No description provided for @settingsBiometricOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsBiometricOn;

  /// No description provided for @settingsBiometricOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsBiometricOff;

  /// No description provided for @settingsBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device has no biometrics available.'**
  String get settingsBiometricUnavailable;

  /// No description provided for @settingsBiometricPin.
  ///
  /// In en, this message translates to:
  /// **'Set up a PIN on the lock screen before enabling biometrics.'**
  String get settingsBiometricPin;

  /// No description provided for @settingsBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometrics were not confirmed. The setting was not changed.'**
  String get settingsBiometricFailed;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// No description provided for @settingsFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get settingsFaq;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service (draft)'**
  String get settingsTerms;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy (draft)'**
  String get settingsPrivacy;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsStorageError.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be saved on this device. Please try again.'**
  String get settingsStorageError;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onboardingFinish;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Freeva'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A short introduction so you can record money without extra help.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a wallet'**
  String get onboardingWalletTitle;

  /// No description provided for @onboardingWalletBody.
  ///
  /// In en, this message translates to:
  /// **'Add a cash, bank, e-wallet, or credit wallet. Each amount stays in its own currency.'**
  String get onboardingWalletBody;

  /// No description provided for @onboardingTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Record the first transaction'**
  String get onboardingTransactionTitle;

  /// No description provided for @onboardingTransactionBody.
  ///
  /// In en, this message translates to:
  /// **'From Home, record income, an expense, or a transfer between two wallets.'**
  String get onboardingTransactionBody;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqTitle;

  /// No description provided for @faqWalletQ.
  ///
  /// In en, this message translates to:
  /// **'How do I add a wallet?'**
  String get faqWalletQ;

  /// No description provided for @faqWalletA.
  ///
  /// In en, this message translates to:
  /// **'Open Wallets from Home, then create a cash, bank, e-wallet, or credit wallet.'**
  String get faqWalletA;

  /// No description provided for @faqTransactionQ.
  ///
  /// In en, this message translates to:
  /// **'How do I record a transaction?'**
  String get faqTransactionQ;

  /// No description provided for @faqTransactionA.
  ///
  /// In en, this message translates to:
  /// **'Open Transactions or use Record transaction on Home. Choose income, an expense, or a transfer with two balanced sides.'**
  String get faqTransactionA;

  /// No description provided for @faqProfileQ.
  ///
  /// In en, this message translates to:
  /// **'How do I change language, currency, or time zone?'**
  String get faqProfileQ;

  /// No description provided for @faqProfileA.
  ///
  /// In en, this message translates to:
  /// **'Open Settings, then Language, currency, and time zone. The language changes after the profile is saved.'**
  String get faqProfileA;

  /// No description provided for @faqLockQ.
  ///
  /// In en, this message translates to:
  /// **'How do I lock the app?'**
  String get faqLockQ;

  /// No description provided for @faqLockA.
  ///
  /// In en, this message translates to:
  /// **'Freeva locks when you leave the app. Unlock with your six-digit PIN. You can turn on biometrics in Settings after a PIN exists.'**
  String get faqLockA;

  /// No description provided for @faqThemeQ.
  ///
  /// In en, this message translates to:
  /// **'How do I switch light and dark mode?'**
  String get faqThemeQ;

  /// No description provided for @faqThemeA.
  ///
  /// In en, this message translates to:
  /// **'Open Settings and choose Light, Dark, or System. Light is the default and stays on this device.'**
  String get faqThemeA;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get feedbackIdea;

  /// No description provided for @feedbackProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get feedbackProblem;

  /// No description provided for @feedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get feedbackMessage;

  /// No description provided for @feedbackCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy feedback'**
  String get feedbackCopy;

  /// No description provided for @feedbackCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied. A contact address is not configured yet, so Freeva does not send this message.'**
  String get feedbackCopied;

  /// No description provided for @feedbackInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a message of up to 2000 characters.'**
  String get feedbackInvalid;

  /// No description provided for @feedbackHelp.
  ///
  /// In en, this message translates to:
  /// **'Freeva copies the message on this device. It is not uploaded and is not written to logs.'**
  String get feedbackHelp;

  /// No description provided for @legalDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft for PRD-P0-002. This is not legal advice and is not in effect. The operating entity and contact channel are not decided yet.'**
  String get legalDraft;

  /// No description provided for @tosTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get tosTitle;

  /// No description provided for @tosBody.
  ///
  /// In en, this message translates to:
  /// **'Freeva lets you record wallets and transactions you enter. You keep your financial data. The service operator is not decided yet. Account export and deletion are separate release work. This summary does not replace a lawyer-reviewed agreement.'**
  String get tosBody;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'The account stores email, language, time zone, default currency, and the financial month start day. Amounts you enter are not written to logs. Feedback you compose stays on this device until a contact channel exists. Analytics events do not include email, balances, or account numbers. This summary does not replace a lawyer-reviewed policy.'**
  String get privacyBody;

  /// No description provided for @balanceHiddenMask.
  ///
  /// In en, this message translates to:
  /// **'••••'**
  String get balanceHiddenMask;

  /// No description provided for @balanceHide.
  ///
  /// In en, this message translates to:
  /// **'Hide balances'**
  String get balanceHide;

  /// No description provided for @balanceShow.
  ///
  /// In en, this message translates to:
  /// **'Show balances'**
  String get balanceShow;

  /// No description provided for @settingsPrivacyControls.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyControls;

  /// No description provided for @settingsHideBalances.
  ///
  /// In en, this message translates to:
  /// **'Hide balances'**
  String get settingsHideBalances;

  /// No description provided for @settingsHideBalancesHelp.
  ///
  /// In en, this message translates to:
  /// **'Masks amounts shown on this device. Fields you are editing still show what you type.'**
  String get settingsHideBalancesHelp;

  /// No description provided for @settingsSessionAlerts.
  ///
  /// In en, this message translates to:
  /// **'New sign-in alerts'**
  String get settingsSessionAlerts;

  /// No description provided for @settingsSessionAlertsHelp.
  ///
  /// In en, this message translates to:
  /// **'Warns on this device when another session appears. The alert does not include an email, balance, or device name.'**
  String get settingsSessionAlertsHelp;

  /// No description provided for @sessionAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'New sign-in'**
  String get sessionAlertTitle;

  /// No description provided for @sessionAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Another session signed in. Open Freeva to review it and revoke it if it was not you.'**
  String get sessionAlertBody;

  /// No description provided for @sessionAlertReview.
  ///
  /// In en, this message translates to:
  /// **'Review sessions'**
  String get sessionAlertReview;

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navMe;

  /// No description provided for @navRecord.
  ///
  /// In en, this message translates to:
  /// **'Record transaction'**
  String get navRecord;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @balanceHiddenSemantics.
  ///
  /// In en, this message translates to:
  /// **'balance hidden'**
  String get balanceHiddenSemantics;

  /// No description provided for @keypadDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get keypadDelete;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @passwordShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShow;

  /// No description provided for @passwordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHide;

  /// No description provided for @homeDatePattern.
  ///
  /// In en, this message translates to:
  /// **'EEEE, MMM d'**
  String get homeDatePattern;

  /// No description provided for @homeMonthPattern.
  ///
  /// In en, this message translates to:
  /// **'MMMM'**
  String get homeMonthPattern;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingAnon.
  ///
  /// In en, this message translates to:
  /// **'Hi there'**
  String get homeGreetingAnon;

  /// No description provided for @homeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get homeSearch;

  /// No description provided for @homeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeNotifications;

  /// No description provided for @homeTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance · {count} wallets'**
  String homeTotalBalance(int count);

  /// No description provided for @homeTotalBalanceIn.
  ///
  /// In en, this message translates to:
  /// **'Total balance · {count} {currency} wallets'**
  String homeTotalBalanceIn(int count, String currency);

  /// No description provided for @homeOtherCurrency.
  ///
  /// In en, this message translates to:
  /// **'{amount} {currency} · {count} wallets'**
  String homeOtherCurrency(String amount, String currency, int count);

  /// No description provided for @homeIncomeMonth.
  ///
  /// In en, this message translates to:
  /// **'Income in {month}'**
  String homeIncomeMonth(String month);

  /// No description provided for @homeExpenseMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent in {month}'**
  String homeExpenseMonth(String month);

  /// No description provided for @homeQuickIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get homeQuickIncome;

  /// No description provided for @homeQuickTransfer.
  ///
  /// In en, this message translates to:
  /// **'Move money'**
  String get homeQuickTransfer;

  /// No description provided for @homeQuickWallets.
  ///
  /// In en, this message translates to:
  /// **'My wallets'**
  String get homeQuickWallets;

  /// No description provided for @homeQuickCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeQuickCategories;

  /// No description provided for @homeSpendOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get homeSpendOther;

  /// No description provided for @homeSpendEmpty.
  ///
  /// In en, this message translates to:
  /// **'No spending yet.'**
  String get homeSpendEmpty;

  /// No description provided for @homeSpendRecord.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get homeSpendRecord;

  /// No description provided for @homeOtherCurrencySpend.
  ///
  /// In en, this message translates to:
  /// **'{currency} wallets: {amount} {currency} spent this month'**
  String homeOtherCurrencySpend(String currency, String amount);

  /// No description provided for @homeReviewMonth.
  ///
  /// In en, this message translates to:
  /// **'Look back at {month}'**
  String homeReviewMonth(String month);

  /// No description provided for @homeReviewLine.
  ///
  /// In en, this message translates to:
  /// **'Spent {expense} · Earned {income}'**
  String homeReviewLine(String expense, String income);

  /// No description provided for @homeCreditTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit cards'**
  String get homeCreditTitle;

  /// No description provided for @homeCreditDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String homeCreditDue(String date);

  /// No description provided for @homeCreditUsed.
  ///
  /// In en, this message translates to:
  /// **'Used {used} of {limit}'**
  String homeCreditUsed(String used, String limit);

  /// No description provided for @homeCreditUsedNoLimit.
  ///
  /// In en, this message translates to:
  /// **'Used {used}'**
  String homeCreditUsedNoLimit(String used);

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// No description provided for @homeSeeTransactions.
  ///
  /// In en, this message translates to:
  /// **'See transactions'**
  String get homeSeeTransactions;

  /// No description provided for @homeRecentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your transactions will show here'**
  String get homeRecentEmpty;

  /// No description provided for @homePendingSync.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get homePendingSync;

  /// No description provided for @homeOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline · Figures from {time}'**
  String homeOfflineTitle(String time);

  /// No description provided for @homeOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'You can still add expenses.'**
  String get homeOfflineBody;

  /// No description provided for @homeErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your balance'**
  String get homeErrorTitle;

  /// No description provided for @homeErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is safe.'**
  String get homeErrorBody;

  /// No description provided for @homeSpokenExpense.
  ///
  /// In en, this message translates to:
  /// **'minus {amount} {currency}'**
  String homeSpokenExpense(String amount, String currency);

  /// No description provided for @homeSpokenIncome.
  ///
  /// In en, this message translates to:
  /// **'plus {amount} {currency}'**
  String homeSpokenIncome(String amount, String currency);

  /// No description provided for @homeSpokenRow.
  ///
  /// In en, this message translates to:
  /// **'{amount}, {title}, {detail}'**
  String homeSpokenRow(String amount, String title, String detail);

  /// No description provided for @homeUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get homeUncategorized;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders and alerts will show here.'**
  String get notificationsEmptyBody;

  /// No description provided for @homeSpokenVnd.
  ///
  /// In en, this message translates to:
  /// **'dong'**
  String get homeSpokenVnd;

  /// No description provided for @txSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get txSearchAction;

  /// No description provided for @txFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get txFilterAction;

  /// No description provided for @txFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Filters on'**
  String get txFilterActive;

  /// No description provided for @txPeriodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get txPeriodThisWeek;

  /// No description provided for @txPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get txPeriodThisMonth;

  /// No description provided for @txPeriodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get txPeriodLastMonth;

  /// No description provided for @txPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get txPeriodCustom;

  /// No description provided for @txPeriodAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get txPeriodAllTime;

  /// No description provided for @txMonthChip.
  ///
  /// In en, this message translates to:
  /// **'{month}'**
  String txMonthChip(String month);

  /// No description provided for @txRangeChip.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String txRangeChip(String from, String to);

  /// No description provided for @txToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get txToday;

  /// No description provided for @txDayHeader.
  ///
  /// In en, this message translates to:
  /// **'{day} · {date}'**
  String txDayHeader(String day, String date);

  /// No description provided for @txChipRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {label}'**
  String txChipRemove(String label);

  /// No description provided for @txFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get txFilterReset;

  /// No description provided for @txFilterPeriod.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get txFilterPeriod;

  /// No description provided for @txFilterWallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get txFilterWallets;

  /// No description provided for @txFilterCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get txFilterCategories;

  /// No description provided for @txFilterTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get txFilterTags;

  /// No description provided for @txFilterAny.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get txFilterAny;

  /// No description provided for @txFilterDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get txFilterDeleted;

  /// No description provided for @txFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Show {count} transactions'**
  String txFilterApply(int count);

  /// No description provided for @txFilterApplyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Show transactions'**
  String get txFilterApplyUnknown;

  /// No description provided for @txFilterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get txFilterDone;

  /// No description provided for @txNoResultTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get txNoResultTitle;

  /// No description provided for @txNoResultBody.
  ///
  /// In en, this message translates to:
  /// **'Try removing a filter.'**
  String get txNoResultBody;

  /// No description provided for @txNoResultClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get txNoResultClear;

  /// No description provided for @txEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get txEmptyTitle;

  /// No description provided for @txEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your first expense takes seconds.'**
  String get txEmptyBody;

  /// No description provided for @txEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get txEmptyAction;

  /// No description provided for @txSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get txSearchHint;

  /// No description provided for @txSearchCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get txSearchCancel;

  /// No description provided for @txSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear text'**
  String get txSearchClear;

  /// No description provided for @txSearchResults.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String txSearchResults(int count);

  /// No description provided for @txSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search by store, note or amount.'**
  String get txSearchPrompt;

  /// No description provided for @txDetailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get txDetailCategory;

  /// No description provided for @txDetailWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get txDetailWallet;

  /// No description provided for @txDetailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txDetailDate;

  /// No description provided for @txDetailTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get txDetailTags;

  /// No description provided for @txDetailNotes.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get txDetailNotes;

  /// No description provided for @txDetailFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get txDetailFrom;

  /// No description provided for @txDetailTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get txDetailTo;

  /// No description provided for @txDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get txDetailDelete;

  /// No description provided for @txDetailCopy.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get txDetailCopy;

  /// No description provided for @txDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get txDetailEdit;

  /// No description provided for @txKindExpense.
  ///
  /// In en, this message translates to:
  /// **'expense'**
  String get txKindExpense;

  /// No description provided for @txKindIncome.
  ///
  /// In en, this message translates to:
  /// **'income'**
  String get txKindIncome;

  /// No description provided for @txKindTransfer.
  ///
  /// In en, this message translates to:
  /// **'transfer'**
  String get txKindTransfer;

  /// No description provided for @txDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Deleted {kind}'**
  String txDeletedToast(String kind);

  /// No description provided for @txRestoredToast.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get txRestoredToast;

  /// No description provided for @txTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get txTrashTitle;

  /// No description provided for @txTrashBody.
  ///
  /// In en, this message translates to:
  /// **'Restore to bring it back to your list.'**
  String get txTrashBody;

  /// No description provided for @txTrashRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get txTrashRestore;

  /// No description provided for @txTrashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing deleted'**
  String get txTrashEmpty;

  /// No description provided for @txLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transactions'**
  String get txLoadFailed;

  /// No description provided for @txTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get txTransferTitle;

  /// No description provided for @txAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get txAmountLabel;

  /// No description provided for @txTransferAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to move'**
  String get txTransferAmountLabel;

  /// No description provided for @txDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txDateLabel;

  /// No description provided for @txMoreButton.
  ///
  /// In en, this message translates to:
  /// **'Note, store, tags'**
  String get txMoreButton;

  /// No description provided for @txSaveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get txSaveExpense;

  /// No description provided for @txSaveIncome.
  ///
  /// In en, this message translates to:
  /// **'Save income'**
  String get txSaveIncome;

  /// No description provided for @txSaveTransfer.
  ///
  /// In en, this message translates to:
  /// **'Save transfer'**
  String get txSaveTransfer;

  /// No description provided for @txSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get txSaveChanges;

  /// No description provided for @txEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {kind}'**
  String txEditTitle(String kind);

  /// No description provided for @txMerchantLabel.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get txMerchantLabel;

  /// No description provided for @txMerchantHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Corner Café'**
  String get txMerchantHint;

  /// No description provided for @txNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get txNotesHint;

  /// No description provided for @txAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get txAddTag;

  /// No description provided for @txPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get txPickCategory;

  /// No description provided for @txFindCategory.
  ///
  /// In en, this message translates to:
  /// **'Find a category'**
  String get txFindCategory;

  /// No description provided for @txFrequent.
  ///
  /// In en, this message translates to:
  /// **'Frequent'**
  String get txFrequent;

  /// No description provided for @txFindOrCreateTag.
  ///
  /// In en, this message translates to:
  /// **'Find or create a tag'**
  String get txFindOrCreateTag;

  /// No description provided for @txCreateTag.
  ///
  /// In en, this message translates to:
  /// **'Create tag “{name}”'**
  String txCreateTag(String name);

  /// No description provided for @txSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get txSelected;

  /// No description provided for @txSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap direction'**
  String get txSwap;

  /// No description provided for @txPickWallet.
  ///
  /// In en, this message translates to:
  /// **'Choose a wallet'**
  String get txPickWallet;

  /// No description provided for @txWalletSubExpense.
  ///
  /// In en, this message translates to:
  /// **'The expense comes out of this wallet'**
  String get txWalletSubExpense;

  /// No description provided for @txWalletSubIncome.
  ///
  /// In en, this message translates to:
  /// **'The income goes into this wallet'**
  String get txWalletSubIncome;

  /// No description provided for @txRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate at {time}'**
  String txRateLabel(String time);

  /// No description provided for @txRateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate'**
  String get txRateEmpty;

  /// No description provided for @txRateValue.
  ///
  /// In en, this message translates to:
  /// **'1 {from} = {rate} {to}'**
  String txRateValue(String from, String rate, String to);

  /// No description provided for @txReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get txReceived;

  /// No description provided for @txRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get txRateTitle;

  /// No description provided for @txDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get txDateTitle;

  /// No description provided for @txYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get txYesterday;

  /// No description provided for @txSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved {kind}'**
  String txSavedToast(String kind);

  /// No description provided for @txDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this {kind}?'**
  String txDiscardTitle(String kind);

  /// No description provided for @txDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The amount and note won\'t be saved.'**
  String get txDiscardBody;

  /// No description provided for @txKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get txKeepEditing;

  /// No description provided for @txDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get txDiscard;

  /// No description provided for @txAmountMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount first.'**
  String get txAmountMissing;

  /// No description provided for @txPickDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose the wallet that receives it.'**
  String get txPickDestination;

  /// No description provided for @txRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'This rate doesn\'t work for this amount.'**
  String get txRateInvalid;

  /// No description provided for @walletTotal.
  ///
  /// In en, this message translates to:
  /// **'Total balance · {count, plural, =1{1 wallet} other{{count} wallets}}'**
  String walletTotal(int count);

  /// No description provided for @walletOtherTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} · {count, plural, =1{1 wallet} other{{count} wallets}}'**
  String walletOtherTotal(String amount, int count);

  /// No description provided for @walletSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get walletSort;

  /// No description provided for @walletSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrange wallets'**
  String get walletSortTitle;

  /// No description provided for @walletSortHint.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag, or use the arrows.'**
  String get walletSortHint;

  /// No description provided for @walletSortDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get walletSortDone;

  /// No description provided for @walletMoveUpNamed.
  ///
  /// In en, this message translates to:
  /// **'Move {name} up'**
  String walletMoveUpNamed(String name);

  /// No description provided for @walletMoveDownNamed.
  ///
  /// In en, this message translates to:
  /// **'Move {name} down'**
  String walletMoveDownNamed(String name);

  /// No description provided for @walletSortFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the order. Try again.'**
  String get walletSortFailed;

  /// No description provided for @walletHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden wallets'**
  String get walletHiddenTitle;

  /// No description provided for @walletHiddenHint.
  ///
  /// In en, this message translates to:
  /// **'History stays. Restore any time.'**
  String get walletHiddenHint;

  /// No description provided for @walletRestoreShort.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get walletRestoreShort;

  /// No description provided for @walletRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} is back'**
  String walletRestored(String name);

  /// No description provided for @walletRestoreNamed.
  ///
  /// In en, this message translates to:
  /// **'Restore {name}'**
  String walletRestoreNamed(String name);

  /// No description provided for @walletDueOn.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String walletDueOn(String date);

  /// No description provided for @walletTypeCurrency.
  ///
  /// In en, this message translates to:
  /// **'{type} · {currency}'**
  String walletTypeCurrency(String type, String currency);

  /// No description provided for @walletMonthIn.
  ///
  /// In en, this message translates to:
  /// **'In, month {month}'**
  String walletMonthIn(String month);

  /// No description provided for @walletMonthOut.
  ///
  /// In en, this message translates to:
  /// **'Out, month {month}'**
  String walletMonthOut(String month);

  /// No description provided for @walletRecordFrom.
  ///
  /// In en, this message translates to:
  /// **'Record from here'**
  String get walletRecordFrom;

  /// No description provided for @walletTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get walletTransfer;

  /// No description provided for @walletEditCard.
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get walletEditCard;

  /// No description provided for @walletNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get walletNoTransactions;

  /// No description provided for @walletNoTransactionsBody.
  ///
  /// In en, this message translates to:
  /// **'Record the first one from this wallet.'**
  String get walletNoTransactionsBody;

  /// No description provided for @creditNoTransactionsBody.
  ///
  /// In en, this message translates to:
  /// **'Record the first one from this card.'**
  String get creditNoTransactionsBody;

  /// No description provided for @walletNotFound.
  ///
  /// In en, this message translates to:
  /// **'This wallet isn\'t here'**
  String get walletNotFound;

  /// No description provided for @walletEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No wallets yet'**
  String get walletEmptyTitle;

  /// No description provided for @walletEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first wallet to start.'**
  String get walletEmptyBody;

  /// No description provided for @creditDebtLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance owed · Credit card'**
  String get creditDebtLabel;

  /// No description provided for @creditAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get creditAvailableLabel;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit {amount}'**
  String creditLimit(String amount);

  /// No description provided for @creditDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment due'**
  String get creditDueTitle;

  /// No description provided for @creditDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{today} =1{1 day left} other{{count} days left}}'**
  String creditDaysLeft(int count);

  /// No description provided for @creditCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Statement closes'**
  String get creditCloseTitle;

  /// No description provided for @creditCloseValue.
  ///
  /// In en, this message translates to:
  /// **'Day {day} each month'**
  String creditCloseValue(int day);

  /// No description provided for @creditNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get creditNotSet;

  /// No description provided for @creditRecordFrom.
  ///
  /// In en, this message translates to:
  /// **'Record from card'**
  String get creditRecordFrom;

  /// No description provided for @creditPay.
  ///
  /// In en, this message translates to:
  /// **'Pay card'**
  String get creditPay;

  /// No description provided for @walletLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load wallets'**
  String get walletLoadError;

  /// No description provided for @cardName.
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get cardName;

  /// No description provided for @walletCurrencyField.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get walletCurrencyField;

  /// No description provided for @walletCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose currency'**
  String get walletCurrencyTitle;

  /// No description provided for @walletCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get walletCurrentBalance;

  /// No description provided for @walletBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'A rough number is fine. You can change it later.'**
  String get walletBalanceHint;

  /// No description provided for @creditCurrentDebt.
  ///
  /// In en, this message translates to:
  /// **'Current balance owed'**
  String get creditCurrentDebt;

  /// No description provided for @creditInitialDebt.
  ///
  /// In en, this message translates to:
  /// **'Starting balance owed'**
  String get creditInitialDebt;

  /// No description provided for @creditLimitField.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get creditLimitField;

  /// No description provided for @creditCloseField.
  ///
  /// In en, this message translates to:
  /// **'Statement day'**
  String get creditCloseField;

  /// No description provided for @creditDueField.
  ///
  /// In en, this message translates to:
  /// **'Due day'**
  String get creditDueField;

  /// No description provided for @creditDayValue.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String creditDayValue(int day);

  /// No description provided for @creditPickDay.
  ///
  /// In en, this message translates to:
  /// **'Pick a day'**
  String get creditPickDay;

  /// No description provided for @creditOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Limit and days can stay empty.'**
  String get creditOptionalHint;

  /// No description provided for @walletSave.
  ///
  /// In en, this message translates to:
  /// **'Save wallet'**
  String get walletSave;

  /// No description provided for @creditSave.
  ///
  /// In en, this message translates to:
  /// **'Save card'**
  String get creditSave;

  /// No description provided for @walletSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get walletSaveChanges;

  /// No description provided for @walletLockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Type · Currency'**
  String get walletLockedLabel;

  /// No description provided for @walletLockedSemantics.
  ///
  /// In en, this message translates to:
  /// **'{type}, {currency}, locked because the wallet has transactions'**
  String walletLockedSemantics(String type, String currency);

  /// No description provided for @walletHiddenToast.
  ///
  /// In en, this message translates to:
  /// **'{name} hidden'**
  String walletHiddenToast(String name);

  /// No description provided for @walletNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Give it a name.'**
  String get walletNameMissing;

  /// No description provided for @walletAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'That amount doesn\'t look right.'**
  String get walletAmountInvalid;

  /// No description provided for @dayDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Which day is it due?'**
  String get dayDueTitle;

  /// No description provided for @dayCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Which day does it close?'**
  String get dayCloseTitle;

  /// No description provided for @dayMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get dayMonthly;

  /// No description provided for @dayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pick day {day}'**
  String dayConfirm(int day);

  /// No description provided for @dayClear.
  ///
  /// In en, this message translates to:
  /// **'Leave empty'**
  String get dayClear;

  /// No description provided for @dayCloseMark.
  ///
  /// In en, this message translates to:
  /// **'Statement day'**
  String get dayCloseMark;

  /// No description provided for @dayDueMark.
  ///
  /// In en, this message translates to:
  /// **'Due day'**
  String get dayDueMark;

  /// No description provided for @dayMarkedSemantics.
  ///
  /// In en, this message translates to:
  /// **'{day}, {mark}'**
  String dayMarkedSemantics(int day, String mark);
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'vi':
      return SVi();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
