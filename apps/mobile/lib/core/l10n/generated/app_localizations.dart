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

  /// No description provided for @authInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Check your email and password.'**
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

  /// No description provided for @authBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock Freeva'**
  String get authBiometricReason;

  /// No description provided for @authUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get authUseBiometric;

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

  /// No description provided for @authContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get authVerifyTitle;

  /// No description provided for @authRecoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authRecoverTitle;

  /// No description provided for @authRecoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and Freeva sends a reset link.'**
  String get authRecoverSubtitle;

  /// No description provided for @authNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get authNewPasswordTitle;

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

  /// No description provided for @authPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Sign in with the new one.'**
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

  /// No description provided for @authBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get authBack;

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

  /// No description provided for @categoryColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryColor;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryIcon;

  /// No description provided for @categoryHiddenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No hidden categories.'**
  String get categoryHiddenEmpty;

  /// No description provided for @categoryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the name and main category.'**
  String get categoryInvalid;

  /// No description provided for @categoryConflict.
  ///
  /// In en, this message translates to:
  /// **'This category changed elsewhere. Open it again to edit.'**
  String get categoryConflict;

  /// No description provided for @categoryError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the category. Try again.'**
  String get categoryError;

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
  /// **'Custom'**
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

  /// No description provided for @reportApply.
  ///
  /// In en, this message translates to:
  /// **'Show this range'**
  String get reportApply;

  /// No description provided for @reportError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the report. Please try again.'**
  String get reportError;

  /// No description provided for @reportInvalid.
  ///
  /// In en, this message translates to:
  /// **'That date range isn\'t valid.'**
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

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqTitle;

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

  /// No description provided for @categoryTabExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get categoryTabExpense;

  /// No description provided for @categoryTabIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categoryTabIncome;

  /// No description provided for @categoryTabs.
  ///
  /// In en, this message translates to:
  /// **'Category type'**
  String get categoryTabs;

  /// No description provided for @categoryChildCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subcategory} other{{count} subcategories}}'**
  String categoryChildCount(int count);

  /// No description provided for @categoryToggleSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}: show or hide subcategories'**
  String categoryToggleSemantics(String name);

  /// No description provided for @categoryHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden categories'**
  String get categoryHiddenTitle;

  /// No description provided for @categoryHiddenHint.
  ///
  /// In en, this message translates to:
  /// **'Past transactions keep these categories.'**
  String get categoryHiddenHint;

  /// No description provided for @categoryRestoreShort.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get categoryRestoreShort;

  /// No description provided for @categoryRestoreNamed.
  ///
  /// In en, this message translates to:
  /// **'Restore {name}'**
  String categoryRestoreNamed(String name);

  /// No description provided for @categoryRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} is back'**
  String categoryRestored(String name);

  /// No description provided for @categoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get categoryEmptyTitle;

  /// No description provided for @categoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add one to get started.'**
  String get categoryEmptyBody;

  /// No description provided for @categoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load categories'**
  String get categoryLoadError;

  /// No description provided for @categoryIconFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryIconFood;

  /// No description provided for @categoryIconCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get categoryIconCoffee;

  /// No description provided for @categoryIconGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryIconGroceries;

  /// No description provided for @categoryIconShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryIconShopping;

  /// No description provided for @categoryIconClothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes'**
  String get categoryIconClothes;

  /// No description provided for @categoryIconGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get categoryIconGifts;

  /// No description provided for @categoryIconTransport.
  ///
  /// In en, this message translates to:
  /// **'Car, motorbike'**
  String get categoryIconTransport;

  /// No description provided for @categoryIconBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get categoryIconBus;

  /// No description provided for @categoryIconFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get categoryIconFuel;

  /// No description provided for @categoryIconTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryIconTravel;

  /// No description provided for @categoryIconHousing.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get categoryIconHousing;

  /// No description provided for @categoryIconRepair.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get categoryIconRepair;

  /// No description provided for @categoryIconElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get categoryIconElectricity;

  /// No description provided for @categoryIconWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get categoryIconWater;

  /// No description provided for @categoryIconInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get categoryIconInternet;

  /// No description provided for @categoryIconPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get categoryIconPhone;

  /// No description provided for @categoryIconHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryIconHealth;

  /// No description provided for @categoryIconMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get categoryIconMedicine;

  /// No description provided for @categoryIconSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get categoryIconSports;

  /// No description provided for @categoryIconFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get categoryIconFamily;

  /// No description provided for @categoryIconPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get categoryIconPets;

  /// No description provided for @categoryIconBeauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get categoryIconBeauty;

  /// No description provided for @categoryIconEducation.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get categoryIconEducation;

  /// No description provided for @categoryIconBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get categoryIconBooks;

  /// No description provided for @categoryIconMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get categoryIconMusic;

  /// No description provided for @categoryIconEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get categoryIconEntertainment;

  /// No description provided for @categoryIconGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get categoryIconGames;

  /// No description provided for @categoryIconSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categoryIconSalary;

  /// No description provided for @categoryIconBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get categoryIconBonus;

  /// No description provided for @categoryIconInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investing'**
  String get categoryIconInvestment;

  /// No description provided for @categoryIconWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryIconWork;

  /// No description provided for @categoryIconOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get categoryIconOtherIncome;

  /// No description provided for @categoryIconBills.
  ///
  /// In en, this message translates to:
  /// **'Taxes, fees'**
  String get categoryIconBills;

  /// No description provided for @categoryIconInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get categoryIconInsurance;

  /// No description provided for @categoryIconSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get categoryIconSubscription;

  /// No description provided for @categoryIconOtherExpense.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryIconOtherExpense;

  /// No description provided for @categoryColorNone.
  ///
  /// In en, this message translates to:
  /// **'No colour'**
  String get categoryColorNone;

  /// No description provided for @categoryColorBrandPrimary.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get categoryColorBrandPrimary;

  /// No description provided for @categoryColorBlueDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep blue'**
  String get categoryColorBlueDeep;

  /// No description provided for @categoryColorBrandSecondary.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get categoryColorBrandSecondary;

  /// No description provided for @categoryColorOceanDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep ocean'**
  String get categoryColorOceanDeep;

  /// No description provided for @categoryColorBrandAccent.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get categoryColorBrandAccent;

  /// No description provided for @categoryColorVioletDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep violet'**
  String get categoryColorVioletDeep;

  /// No description provided for @categoryColorSuccess.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get categoryColorSuccess;

  /// No description provided for @categoryColorWarning.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get categoryColorWarning;

  /// No description provided for @categoryColorBlueLight.
  ///
  /// In en, this message translates to:
  /// **'Light blue'**
  String get categoryColorBlueLight;

  /// No description provided for @categoryColorBrandHighlight.
  ///
  /// In en, this message translates to:
  /// **'Light sky'**
  String get categoryColorBrandHighlight;

  /// No description provided for @categoryColorVioletLight.
  ///
  /// In en, this message translates to:
  /// **'Light violet'**
  String get categoryColorVioletLight;

  /// No description provided for @categoryColorGreenLight.
  ///
  /// In en, this message translates to:
  /// **'Light green'**
  String get categoryColorGreenLight;

  /// No description provided for @categoryColorYellowLight.
  ///
  /// In en, this message translates to:
  /// **'Light yellow'**
  String get categoryColorYellowLight;

  /// No description provided for @categoryColorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get categoryColorPink;

  /// No description provided for @categoryColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get categoryColorOrange;

  /// No description provided for @categoryColorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get categoryColorBrown;

  /// No description provided for @categoryColorLime.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get categoryColorLime;

  /// No description provided for @categoryColorOlive.
  ///
  /// In en, this message translates to:
  /// **'Olive'**
  String get categoryColorOlive;

  /// No description provided for @categoryColorPlum.
  ///
  /// In en, this message translates to:
  /// **'Plum'**
  String get categoryColorPlum;

  /// No description provided for @categoryColorGray.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get categoryColorGray;

  /// No description provided for @categoryIconGroupFood.
  ///
  /// In en, this message translates to:
  /// **'Food · shopping'**
  String get categoryIconGroupFood;

  /// No description provided for @categoryIconGroupHome.
  ///
  /// In en, this message translates to:
  /// **'Getting around · home'**
  String get categoryIconGroupHome;

  /// No description provided for @categoryIconGroupLife.
  ///
  /// In en, this message translates to:
  /// **'Health · family · fun'**
  String get categoryIconGroupLife;

  /// No description provided for @categoryIconGroupMoney.
  ///
  /// In en, this message translates to:
  /// **'Income · money'**
  String get categoryIconGroupMoney;

  /// No description provided for @categoryLevelMain.
  ///
  /// In en, this message translates to:
  /// **'Main category'**
  String get categoryLevelMain;

  /// No description provided for @categoryLevelChild.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get categoryLevelChild;

  /// No description provided for @categoryParentField.
  ///
  /// In en, this message translates to:
  /// **'Under'**
  String get categoryParentField;

  /// No description provided for @categoryPickParent.
  ///
  /// In en, this message translates to:
  /// **'Pick a main category'**
  String get categoryPickParent;

  /// No description provided for @categoryParentSheet.
  ///
  /// In en, this message translates to:
  /// **'Main category'**
  String get categoryParentSheet;

  /// No description provided for @categoryParentMissing.
  ///
  /// In en, this message translates to:
  /// **'Pick a main category.'**
  String get categoryParentMissing;

  /// No description provided for @categoryNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Give it a name.'**
  String get categoryNameMissing;

  /// No description provided for @categoryMoreIcons.
  ///
  /// In en, this message translates to:
  /// **'More icons'**
  String get categoryMoreIcons;

  /// No description provided for @categoryIconSearch.
  ///
  /// In en, this message translates to:
  /// **'Search: fuel, pets…'**
  String get categoryIconSearch;

  /// No description provided for @categoryIconSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search icons'**
  String get categoryIconSearchLabel;

  /// No description provided for @categoryIconDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get categoryIconDone;

  /// No description provided for @categoryIconNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No icons match.'**
  String get categoryIconNoMatch;

  /// No description provided for @categorySave.
  ///
  /// In en, this message translates to:
  /// **'Save category'**
  String get categorySave;

  /// No description provided for @categorySaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get categorySaveChanges;

  /// No description provided for @categoryHideShort.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get categoryHideShort;

  /// No description provided for @categoryDeleteShort.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get categoryDeleteShort;

  /// No description provided for @categoryChildrenBlock.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subcategory left} other{{count} subcategories left}}'**
  String categoryChildrenBlock(int count);

  /// No description provided for @categoryHiddenToast.
  ///
  /// In en, this message translates to:
  /// **'{name} hidden'**
  String categoryHiddenToast(String name);

  /// No description provided for @categoryDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String categoryDeletedToast(String name);

  /// No description provided for @categoryDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String categoryDeleteQuestion(String name);

  /// No description provided for @categoryDeleteNoUndo.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get categoryDeleteNoUndo;

  /// No description provided for @categoryDeleteMove.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone. {count, plural, =1{1 transaction moves} other{{count} transactions move}} to:'**
  String categoryDeleteMove(int count);

  /// No description provided for @categoryMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move transactions to'**
  String get categoryMoveTo;

  /// No description provided for @reportYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get reportYear;

  /// No description provided for @reportYearTitle.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String reportYearTitle(String year);

  /// No description provided for @reportMonthTitlePattern.
  ///
  /// In en, this message translates to:
  /// **'MMMM, yyyy'**
  String get reportMonthTitlePattern;

  /// No description provided for @reportShortDatePattern.
  ///
  /// In en, this message translates to:
  /// **'MM/dd'**
  String get reportShortDatePattern;

  /// No description provided for @reportRangeDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String reportRangeDays(int count);

  /// No description provided for @reportAverageDay.
  ///
  /// In en, this message translates to:
  /// **'Average spend/day'**
  String get reportAverageDay;

  /// No description provided for @reportRemaining.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get reportRemaining;

  /// No description provided for @reportVsMonth.
  ///
  /// In en, this message translates to:
  /// **'vs M{month}'**
  String reportVsMonth(String month);

  /// No description provided for @reportVsWeek.
  ///
  /// In en, this message translates to:
  /// **'vs last week'**
  String get reportVsWeek;

  /// No description provided for @reportVsYear.
  ///
  /// In en, this message translates to:
  /// **'vs {year}'**
  String reportVsYear(String year);

  /// No description provided for @reportVsPeriod.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get reportVsPeriod;

  /// No description provided for @reportChange.
  ///
  /// In en, this message translates to:
  /// **'{percent}% {versus}'**
  String reportChange(String percent, String versus);

  /// No description provided for @reportBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly budget'**
  String get reportBudgetSet;

  /// No description provided for @reportBudgetSoon.
  ///
  /// In en, this message translates to:
  /// **'Budgets are coming soon'**
  String get reportBudgetSoon;

  /// No description provided for @reportTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending trend'**
  String get reportTrendTitle;

  /// No description provided for @reportTrendAverageWeeks.
  ///
  /// In en, this message translates to:
  /// **'Average of {count} weeks'**
  String reportTrendAverageWeeks(int count);

  /// No description provided for @reportTrendAverageMonths.
  ///
  /// In en, this message translates to:
  /// **'Average of {count} months'**
  String reportTrendAverageMonths(int count);

  /// No description provided for @reportTrendAverageYears.
  ///
  /// In en, this message translates to:
  /// **'Average of {count} years'**
  String reportTrendAverageYears(int count);

  /// No description provided for @reportViewExpense.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get reportViewExpense;

  /// No description provided for @reportViewIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reportViewIncome;

  /// No description provided for @reportViewWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get reportViewWallet;

  /// No description provided for @reportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportOther;

  /// No description provided for @reportOtherCount.
  ///
  /// In en, this message translates to:
  /// **'Other · {count} categories'**
  String reportOtherCount(int count);

  /// No description provided for @reportFlowIn.
  ///
  /// In en, this message translates to:
  /// **'In +{amount}'**
  String reportFlowIn(String amount);

  /// No description provided for @reportFlowOut.
  ///
  /// In en, this message translates to:
  /// **'Out −{amount}'**
  String reportFlowOut(String amount);

  /// No description provided for @reportFlowTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfers {amount}'**
  String reportFlowTransfer(String amount);

  /// No description provided for @reportEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No data for {period}'**
  String reportEmptyTitle(String period);

  /// No description provided for @reportEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Record a transaction to see your numbers.'**
  String get reportEmptyHint;

  /// No description provided for @reportBackWeek.
  ///
  /// In en, this message translates to:
  /// **'Back to this week'**
  String get reportBackWeek;

  /// No description provided for @reportBackMonth.
  ///
  /// In en, this message translates to:
  /// **'Back to this month'**
  String get reportBackMonth;

  /// No description provided for @reportBackYear.
  ///
  /// In en, this message translates to:
  /// **'Back to this year'**
  String get reportBackYear;

  /// No description provided for @reportUnitThousand.
  ///
  /// In en, this message translates to:
  /// **'k'**
  String get reportUnitThousand;

  /// No description provided for @reportUnitMillion.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get reportUnitMillion;

  /// No description provided for @reportUnitBillion.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get reportUnitBillion;

  /// No description provided for @reportDonutSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} {amount} {currency}: {items}'**
  String reportDonutSemantics(
    String label,
    String amount,
    String currency,
    String items,
  );

  /// No description provided for @reportTrendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Spending, last {count}: {items}'**
  String reportTrendSemantics(int count, String items);

  /// No description provided for @reportMonthShort.
  ///
  /// In en, this message translates to:
  /// **'M{month}'**
  String reportMonthShort(String month);

  /// No description provided for @reportRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a date range'**
  String get reportRangeTitle;

  /// No description provided for @reportQuick7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get reportQuick7;

  /// No description provided for @reportQuick30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get reportQuick30;

  /// No description provided for @reportQuickQuarter.
  ///
  /// In en, this message translates to:
  /// **'This quarter'**
  String get reportQuickQuarter;

  /// No description provided for @reportWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Mon,Tue,Wed,Thu,Fri,Sat,Sun'**
  String get reportWeekdays;

  /// No description provided for @reportRangePickStart.
  ///
  /// In en, this message translates to:
  /// **'Pick the first day'**
  String get reportRangePickStart;

  /// No description provided for @reportRangePickEnd.
  ///
  /// In en, this message translates to:
  /// **'Now pick the last day'**
  String get reportRangePickEnd;

  /// No description provided for @reportDayFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String reportDayFrom(String date);

  /// No description provided for @reportDayTo.
  ///
  /// In en, this message translates to:
  /// **'To {date}'**
  String reportDayTo(String date);

  /// No description provided for @reportDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String reportDayToday(String date);

  /// No description provided for @reportShareExpense.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of spending'**
  String reportShareExpense(String percent);

  /// No description provided for @reportShareIncome.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of income'**
  String reportShareIncome(String percent);

  /// No description provided for @reportShareCount.
  ///
  /// In en, this message translates to:
  /// **'{share} · {count} transactions'**
  String reportShareCount(String share, int count);

  /// No description provided for @reportLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest transactions'**
  String get reportLargest;

  /// No description provided for @reportSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String reportSeeAll(int count);

  /// No description provided for @reportLargestError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transactions'**
  String get reportLargestError;

  /// No description provided for @meTitle.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get meTitle;

  /// No description provided for @meGroupFinance.
  ///
  /// In en, this message translates to:
  /// **'Money setup'**
  String get meGroupFinance;

  /// No description provided for @meGroupApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get meGroupApp;

  /// No description provided for @meGroupHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get meGroupHelp;

  /// No description provided for @meWallets.
  ///
  /// In en, this message translates to:
  /// **'My wallets'**
  String get meWallets;

  /// No description provided for @meCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get meCategories;

  /// No description provided for @meTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get meTags;

  /// No description provided for @meRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get meRecurring;

  /// No description provided for @meBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get meBills;

  /// No description provided for @meCalendar.
  ///
  /// In en, this message translates to:
  /// **'Money calendar'**
  String get meCalendar;

  /// No description provided for @meCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get meCurrency;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Money calendar'**
  String get calendarTitle;

  /// No description provided for @calendarLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load calendar'**
  String get calendarLoadError;

  /// No description provided for @calendarEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing this month'**
  String get calendarEmptyTitle;

  /// No description provided for @calendarEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No posted transactions, recurring runs, or bills in this month.'**
  String get calendarEmptyBody;

  /// No description provided for @calendarPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPrevMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// No description provided for @calendarSectionTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get calendarSectionTransactions;

  /// No description provided for @calendarSectionRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get calendarSectionRecurring;

  /// No description provided for @calendarSectionBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get calendarSectionBills;

  /// No description provided for @calendarLegend.
  ///
  /// In en, this message translates to:
  /// **'Dots mark item types on each day'**
  String get calendarLegend;

  /// No description provided for @calendarTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get calendarTransfer;

  /// No description provided for @calendarEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get calendarEstimated;

  /// No description provided for @billsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get billsTitle;

  /// No description provided for @billsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add bill'**
  String get billsAdd;

  /// No description provided for @billsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit bill'**
  String get billsEdit;

  /// No description provided for @billsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get billsDelete;

  /// No description provided for @billsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get billsSave;

  /// No description provided for @billsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get billsEmptyTitle;

  /// No description provided for @billsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Track utilities and subscriptions. Mark paid by linking an existing transaction.'**
  String get billsEmptyBody;

  /// No description provided for @billsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load bills'**
  String get billsLoadError;

  /// No description provided for @billsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get billsName;

  /// No description provided for @billsAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get billsAmount;

  /// No description provided for @billsAmountFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get billsAmountFixed;

  /// No description provided for @billsAmountEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get billsAmountEstimated;

  /// No description provided for @billsDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due date (YYYY-MM-DD)'**
  String get billsDueOn;

  /// No description provided for @billsRecurring.
  ///
  /// In en, this message translates to:
  /// **'Link recurring'**
  String get billsRecurring;

  /// No description provided for @billsOneOff.
  ///
  /// In en, this message translates to:
  /// **'One-off'**
  String get billsOneOff;

  /// No description provided for @billsLinkedRecurring.
  ///
  /// In en, this message translates to:
  /// **'Linked recurring'**
  String get billsLinkedRecurring;

  /// No description provided for @billsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get billsFilterAll;

  /// No description provided for @billsStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get billsStatusOpen;

  /// No description provided for @billsStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get billsStatusOverdue;

  /// No description provided for @billsStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billsStatusPaid;

  /// No description provided for @billsMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get billsMarkPaid;

  /// No description provided for @billsUnpay.
  ///
  /// In en, this message translates to:
  /// **'Clear paid mark'**
  String get billsUnpay;

  /// No description provided for @billsPickTransaction.
  ///
  /// In en, this message translates to:
  /// **'Choose a transaction'**
  String get billsPickTransaction;

  /// No description provided for @billsNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions to link yet'**
  String get billsNoTransactions;

  /// No description provided for @billsMarkedPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment linked'**
  String get billsMarkedPaid;

  /// No description provided for @billsClearedPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid mark cleared'**
  String get billsClearedPaid;

  /// No description provided for @billsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name and amount'**
  String get billsInvalid;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringTitle;

  /// No description provided for @recurringAdd.
  ///
  /// In en, this message translates to:
  /// **'Add recurring'**
  String get recurringAdd;

  /// No description provided for @recurringEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring'**
  String get recurringEdit;

  /// No description provided for @recurringDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get recurringDelete;

  /// No description provided for @recurringSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get recurringSave;

  /// No description provided for @recurringEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recurring yet'**
  String get recurringEmptyTitle;

  /// No description provided for @recurringEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Set rent, salary, or transfers once and Freeva posts them on schedule.'**
  String get recurringEmptyBody;

  /// No description provided for @recurringLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load recurring'**
  String get recurringLoadError;

  /// No description provided for @recurringAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get recurringAmount;

  /// No description provided for @recurringWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get recurringWallet;

  /// No description provided for @recurringCounterWallet.
  ///
  /// In en, this message translates to:
  /// **'To wallet'**
  String get recurringCounterWallet;

  /// No description provided for @recurringCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get recurringCategory;

  /// No description provided for @recurringFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get recurringFrequency;

  /// No description provided for @recurringInterval.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get recurringInterval;

  /// No description provided for @recurringEvery.
  ///
  /// In en, this message translates to:
  /// **'Every {count}'**
  String recurringEvery(String count);

  /// No description provided for @recurringUnitDay.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurringUnitDay;

  /// No description provided for @recurringUnitWeek.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurringUnitWeek;

  /// No description provided for @recurringUnitMonth.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurringUnitMonth;

  /// No description provided for @recurringUnitYear.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurringUnitYear;

  /// No description provided for @recurringStart.
  ///
  /// In en, this message translates to:
  /// **'Start date (YYYY-MM-DD)'**
  String get recurringStart;

  /// No description provided for @recurringNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next run (YYYY-MM-DD)'**
  String get recurringNextLabel;

  /// No description provided for @recurringEnd.
  ///
  /// In en, this message translates to:
  /// **'End date (optional)'**
  String get recurringEnd;

  /// No description provided for @recurringActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get recurringActive;

  /// No description provided for @recurringNext.
  ///
  /// In en, this message translates to:
  /// **'Next {date}'**
  String recurringNext(String date);

  /// No description provided for @recurringTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get recurringTypeExpense;

  /// No description provided for @recurringTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get recurringTypeIncome;

  /// No description provided for @recurringTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get recurringTypeTransfer;

  /// No description provided for @meBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get meBudget;

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get budgetTitle;

  /// No description provided for @budgetSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get budgetSave;

  /// No description provided for @budgetSaved.
  ///
  /// In en, this message translates to:
  /// **'Budget saved'**
  String get budgetSaved;

  /// No description provided for @budgetCleared.
  ///
  /// In en, this message translates to:
  /// **'Budget removed'**
  String get budgetCleared;

  /// No description provided for @budgetLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the budget'**
  String get budgetLoadError;

  /// No description provided for @budgetOverallLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get budgetOverallLimit;

  /// No description provided for @budgetCategoryLimit.
  ///
  /// In en, this message translates to:
  /// **'Category limit'**
  String get budgetCategoryLimit;

  /// No description provided for @budgetTapToSet.
  ///
  /// In en, this message translates to:
  /// **'Tap to set'**
  String get budgetTapToSet;

  /// No description provided for @budgetCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get budgetCategoriesTitle;

  /// No description provided for @budgetCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: set a limit for each expense category.'**
  String get budgetCategoriesHint;

  /// No description provided for @budgetAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get budgetAddCategory;

  /// No description provided for @budgetNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No expense categories left to add'**
  String get budgetNoCategories;

  /// No description provided for @budgetUnknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetUnknownCategory;

  /// No description provided for @budgetClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove budget?'**
  String get budgetClearTitle;

  /// No description provided for @budgetClearBody.
  ///
  /// In en, this message translates to:
  /// **'The spent bar on Home will hide until you set a budget again.'**
  String get budgetClearBody;

  /// No description provided for @budgetClearAction.
  ///
  /// In en, this message translates to:
  /// **'Remove budget'**
  String get budgetClearAction;

  /// No description provided for @budgetSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetSpentLabel;

  /// No description provided for @budgetRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get budgetRemainingLabel;

  /// No description provided for @budgetUsedPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String budgetUsedPercent(String percent);

  /// No description provided for @budgetLimitLine.
  ///
  /// In en, this message translates to:
  /// **'{spent} / {limit}'**
  String budgetLimitLine(String spent, String limit);

  /// No description provided for @budgetThresholdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert thresholds'**
  String get budgetThresholdsTitle;

  /// No description provided for @budgetScopeDefault.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get budgetScopeDefault;

  /// No description provided for @budgetScopeMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get budgetScopeMonth;

  /// No description provided for @budgetScopeMonthHint.
  ///
  /// In en, this message translates to:
  /// **'Using the default limit. Saving creates an override for this month only.'**
  String get budgetScopeMonthHint;

  /// No description provided for @budgetScopeMonthOverrideHint.
  ///
  /// In en, this message translates to:
  /// **'This month has its own limit, not the default.'**
  String get budgetScopeMonthOverrideHint;

  /// No description provided for @budgetClearMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this month’s override?'**
  String get budgetClearMonthTitle;

  /// No description provided for @budgetClearMonthBody.
  ///
  /// In en, this message translates to:
  /// **'This month will use the default limit again (if one is set).'**
  String get budgetClearMonthBody;

  /// No description provided for @budgetClearMonthAction.
  ///
  /// In en, this message translates to:
  /// **'Remove month override'**
  String get budgetClearMonthAction;

  /// No description provided for @budgetMonthCleared.
  ///
  /// In en, this message translates to:
  /// **'Month override removed'**
  String get budgetMonthCleared;

  /// No description provided for @budgetStatusHealthy.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get budgetStatusHealthy;

  /// No description provided for @budgetStatusWarning.
  ///
  /// In en, this message translates to:
  /// **'A bit fast'**
  String get budgetStatusWarning;

  /// No description provided for @budgetStatusCritical.
  ///
  /// In en, this message translates to:
  /// **'Almost out'**
  String get budgetStatusCritical;

  /// No description provided for @budgetStatusOver.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get budgetStatusOver;

  /// No description provided for @budgetHomeLine.
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} / {limit}'**
  String budgetHomeLine(String spent, String limit);

  /// No description provided for @meFiscal.
  ///
  /// In en, this message translates to:
  /// **'Month starts on'**
  String get meFiscal;

  /// No description provided for @meFiscalDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String meFiscalDay(int day);

  /// No description provided for @meGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get meGoals;

  /// No description provided for @meTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get meTheme;

  /// No description provided for @meThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get meThemeLight;

  /// No description provided for @meThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get meThemeDark;

  /// No description provided for @meThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Match device'**
  String get meThemeSystem;

  /// No description provided for @meLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get meLanguage;

  /// No description provided for @meTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get meTimezone;

  /// No description provided for @meNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get meNotifications;

  /// No description provided for @meHideBalances.
  ///
  /// In en, this message translates to:
  /// **'Hide balances'**
  String get meHideBalances;

  /// No description provided for @meSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get meSecurity;

  /// No description provided for @meSecurityValueBiometric.
  ///
  /// In en, this message translates to:
  /// **'PIN · biometrics'**
  String get meSecurityValueBiometric;

  /// No description provided for @meSecurityValuePin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get meSecurityValuePin;

  /// No description provided for @meFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get meFaq;

  /// No description provided for @meFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get meFeedback;

  /// No description provided for @meSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get meSoon;

  /// No description provided for @meLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get meLogout;

  /// No description provided for @meLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of this device?'**
  String get meLogoutTitle;

  /// No description provided for @meLogoutBody.
  ///
  /// In en, this message translates to:
  /// **'Your data stays in your account.'**
  String get meLogoutBody;

  /// No description provided for @meProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get meProfileTitle;

  /// No description provided for @meProfileName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get meProfileName;

  /// No description provided for @meProfileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get meProfileEmail;

  /// No description provided for @meChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get meChange;

  /// No description provided for @meSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get meSave;

  /// No description provided for @meSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get meSaved;

  /// No description provided for @meSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Try again.'**
  String get meSaveError;

  /// No description provided for @meConflict.
  ///
  /// In en, this message translates to:
  /// **'This changed on another device. Reload and try again.'**
  String get meConflict;

  /// No description provided for @meAvatarSemantics.
  ///
  /// In en, this message translates to:
  /// **'Profile picture, initial {letter}'**
  String meAvatarSemantics(String letter);

  /// No description provided for @meSecUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get meSecUnlock;

  /// No description provided for @meSecPin.
  ///
  /// In en, this message translates to:
  /// **'PIN lock'**
  String get meSecPin;

  /// No description provided for @meSecPinSub.
  ///
  /// In en, this message translates to:
  /// **'When you reopen Freeva'**
  String get meSecPinSub;

  /// No description provided for @meSecBiometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get meSecBiometric;

  /// No description provided for @meSecChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get meSecChangePin;

  /// No description provided for @meSecLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get meSecLogin;

  /// No description provided for @meSecSessions.
  ///
  /// In en, this message translates to:
  /// **'Signed-in devices'**
  String get meSecSessions;

  /// No description provided for @meSecChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get meSecChangePassword;

  /// No description provided for @meSessionsHint.
  ///
  /// In en, this message translates to:
  /// **'Don\'t recognise one? Revoke it now.'**
  String get meSessionsHint;

  /// No description provided for @meSessionThis.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get meSessionThis;

  /// No description provided for @meSessionOther.
  ///
  /// In en, this message translates to:
  /// **'Another device'**
  String get meSessionOther;

  /// No description provided for @meSessionInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get meSessionInUse;

  /// No description provided for @meSessionDates.
  ///
  /// In en, this message translates to:
  /// **'From {from} · expires {to}'**
  String meSessionDates(String from, String to);

  /// No description provided for @meRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get meRevoke;

  /// No description provided for @meRevokeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Revoke the session from {date}'**
  String meRevokeSemantics(String date);

  /// No description provided for @meRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke this session?'**
  String get meRevokeTitle;

  /// No description provided for @meRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'That device will be signed out.'**
  String get meRevokeBody;

  /// No description provided for @meRevokeOthers.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices'**
  String get meRevokeOthers;

  /// No description provided for @meRevokeOthersTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices?'**
  String get meRevokeOthersTitle;

  /// No description provided for @meRevokeOthersBody.
  ///
  /// In en, this message translates to:
  /// **'This device stays signed in.'**
  String get meRevokeOthersBody;

  /// No description provided for @meChangePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get meChangePinTitle;

  /// No description provided for @mePinCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get mePinCurrent;

  /// No description provided for @mePinNew.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get mePinNew;

  /// No description provided for @mePinRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat new PIN'**
  String get mePinRepeat;

  /// No description provided for @mePinWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. After 5 misses you sign in again.'**
  String get mePinWrong;

  /// No description provided for @mePinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The new PINs don\'t match.'**
  String get mePinMismatch;

  /// No description provided for @mePinSame.
  ///
  /// In en, this message translates to:
  /// **'Pick a different PIN.'**
  String get mePinSame;

  /// No description provided for @mePinInvalid.
  ///
  /// In en, this message translates to:
  /// **'A PIN is 6 digits.'**
  String get mePinInvalid;

  /// No description provided for @mePinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get mePinChanged;

  /// No description provided for @meChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get meChangePasswordTitle;

  /// No description provided for @mePasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get mePasswordCurrent;

  /// No description provided for @mePasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get mePasswordNew;

  /// No description provided for @mePasswordRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get mePasswordRepeat;

  /// No description provided for @mePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 12 characters, with letters and digits.'**
  String get mePasswordHint;

  /// No description provided for @mePasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t your current password.'**
  String get mePasswordWrong;

  /// No description provided for @mePasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters with letters and digits, different from the old one.'**
  String get mePasswordWeak;

  /// No description provided for @mePasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The new passwords don\'t match.'**
  String get mePasswordMismatch;

  /// No description provided for @mePasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Other devices were signed out.'**
  String get mePasswordChanged;

  /// No description provided for @meBusyRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again in {minutes} min.'**
  String meBusyRetry(int minutes);

  /// No description provided for @meNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Freeva. Check your connection.'**
  String get meNetworkError;

  /// No description provided for @meSecAlways.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get meSecAlways;

  /// No description provided for @tagsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search tags'**
  String get tagsSearch;

  /// No description provided for @tagsAdd.
  ///
  /// In en, this message translates to:
  /// **'Create tag'**
  String get tagsAdd;

  /// No description provided for @tagsName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagsName;

  /// No description provided for @tagsRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get tagsRenameTitle;

  /// No description provided for @tagsRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get tagsRename;

  /// No description provided for @tagsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tagsDelete;

  /// No description provided for @tagsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String tagsDeleteTitle(String name);

  /// No description provided for @tagsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Transactions stay; only this tag comes off.'**
  String get tagsDeleteBody;

  /// No description provided for @tagsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get tagsEmptyTitle;

  /// No description provided for @tagsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tag transactions to group them your way.'**
  String get tagsEmptyBody;

  /// No description provided for @tagsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No tag matches'**
  String get tagsNoMatch;

  /// No description provided for @tagsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load tags'**
  String get tagsLoadError;

  /// No description provided for @tagsRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {count} transactions'**
  String tagsRowSemantics(String name, int count);

  /// No description provided for @tagsMore.
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String tagsMore(String name);

  /// No description provided for @fbHeading.
  ///
  /// In en, this message translates to:
  /// **'What would you like to tell Freeva?'**
  String get fbHeading;

  /// No description provided for @fbKindBug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get fbKindBug;

  /// No description provided for @fbKindIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get fbKindIdea;

  /// No description provided for @fbKindPraise.
  ///
  /// In en, this message translates to:
  /// **'Praise'**
  String get fbKindPraise;

  /// No description provided for @fbAbout.
  ///
  /// In en, this message translates to:
  /// **'Which part?'**
  String get fbAbout;

  /// No description provided for @fbTopicRecord.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get fbTopicRecord;

  /// No description provided for @fbTopicReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get fbTopicReports;

  /// No description provided for @fbTopicWallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get fbTopicWallets;

  /// No description provided for @fbTopicCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get fbTopicCategories;

  /// No description provided for @fbTopicAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get fbTopicAppearance;

  /// No description provided for @fbTopicOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get fbTopicOther;

  /// No description provided for @fbLabelBug.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get fbLabelBug;

  /// No description provided for @fbLabelIdea.
  ///
  /// In en, this message translates to:
  /// **'Your idea'**
  String get fbLabelIdea;

  /// No description provided for @fbLabelPraise.
  ///
  /// In en, this message translates to:
  /// **'What do you like?'**
  String get fbLabelPraise;

  /// No description provided for @fbCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/2000'**
  String fbCount(int count);

  /// No description provided for @fbReply.
  ///
  /// In en, this message translates to:
  /// **'Reply to me by email'**
  String get fbReply;

  /// No description provided for @fbSend.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get fbSend;

  /// No description provided for @fbSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get fbSending;

  /// No description provided for @fbThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get fbThanks;

  /// No description provided for @fbThanksReply.
  ///
  /// In en, this message translates to:
  /// **'Freeva will read it and reply by email.'**
  String get fbThanksReply;

  /// No description provided for @fbThanksNoReply.
  ///
  /// In en, this message translates to:
  /// **'Freeva will read every message.'**
  String get fbThanksNoReply;

  /// No description provided for @fbDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get fbDone;

  /// No description provided for @fbError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send. Try again.'**
  String get fbError;

  /// No description provided for @faqSearch.
  ///
  /// In en, this message translates to:
  /// **'Search questions'**
  String get faqSearch;

  /// No description provided for @faqNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No question matches'**
  String get faqNoMatch;

  /// No description provided for @faqMissing.
  ///
  /// In en, this message translates to:
  /// **'Not finding your answer?'**
  String get faqMissing;

  /// No description provided for @faqSend.
  ///
  /// In en, this message translates to:
  /// **'Send feedback to Freeva'**
  String get faqSend;

  /// No description provided for @notifyReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifyReminders;

  /// No description provided for @notifyAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get notifyAlerts;

  /// No description provided for @notifyRecord.
  ///
  /// In en, this message translates to:
  /// **'Record reminder'**
  String get notifyRecord;

  /// No description provided for @notifyRecordSub.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get notifyRecordSub;

  /// No description provided for @notifyDigest.
  ///
  /// In en, this message translates to:
  /// **'Spending summary'**
  String get notifyDigest;

  /// No description provided for @notifyDigestSub.
  ///
  /// In en, this message translates to:
  /// **'Every week or month'**
  String get notifyDigestSub;

  /// No description provided for @notifyBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget running out'**
  String get notifyBudget;

  /// No description provided for @notifyBudgetSub.
  ///
  /// In en, this message translates to:
  /// **'At 80% and 100% used'**
  String get notifyBudgetSub;

  /// No description provided for @notifyCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card due'**
  String get notifyCard;

  /// No description provided for @notifyCardSub.
  ///
  /// In en, this message translates to:
  /// **'3 days before'**
  String get notifyCardSub;

  /// No description provided for @notifySession.
  ///
  /// In en, this message translates to:
  /// **'New device signed in'**
  String get notifySession;

  /// No description provided for @notifyRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring due soon'**
  String get notifyRecurring;

  /// No description provided for @notifyRecurringSub.
  ///
  /// In en, this message translates to:
  /// **'One day before the next run'**
  String get notifyRecurringSub;

  /// No description provided for @notifyGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal contribution reminder'**
  String get notifyGoal;

  /// No description provided for @notifyGoalSub.
  ///
  /// In en, this message translates to:
  /// **'When a contribution is due'**
  String get notifyGoalSub;

  /// No description provided for @notifyDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt due'**
  String get notifyDebt;

  /// No description provided for @notifyDebtSub.
  ///
  /// In en, this message translates to:
  /// **'Before the due date'**
  String get notifyDebtSub;

  /// No description provided for @notifyMonthReview.
  ///
  /// In en, this message translates to:
  /// **'Month review'**
  String get notifyMonthReview;

  /// No description provided for @notifyMonthReviewSub.
  ///
  /// In en, this message translates to:
  /// **'When a month summary is ready'**
  String get notifyMonthReviewSub;

  /// No description provided for @notifyInsight.
  ///
  /// In en, this message translates to:
  /// **'New insight'**
  String get notifyInsight;

  /// No description provided for @notifyInsightSub.
  ///
  /// In en, this message translates to:
  /// **'When a new tip is ready'**
  String get notifyInsightSub;

  /// No description provided for @notifyQuietTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifyQuietTitle;

  /// No description provided for @notifyQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Enable quiet hours'**
  String get notifyQuietHours;

  /// No description provided for @notifyQuietEdit.
  ///
  /// In en, this message translates to:
  /// **'Quiet window'**
  String get notifyQuietEdit;

  /// No description provided for @notifyQuietStart.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours start'**
  String get notifyQuietStart;

  /// No description provided for @notifyQuietEnd.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours end'**
  String get notifyQuietEnd;

  /// No description provided for @notifyQuietWindow.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String notifyQuietWindow(String start, String end);

  /// No description provided for @notifyMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifyMarkAllRead;

  /// No description provided for @notifyInboxBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget reached {threshold}%'**
  String notifyInboxBudgetTitle(String threshold);

  /// No description provided for @notifyInboxBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'You have used {threshold}% of this month’s budget.'**
  String notifyInboxBudgetBody(String threshold);

  /// No description provided for @notifyInboxRecurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring due soon'**
  String get notifyInboxRecurringTitle;

  /// No description provided for @notifyInboxRecurringBody.
  ///
  /// In en, this message translates to:
  /// **'A recurring transaction runs on {date}.'**
  String notifyInboxRecurringBody(String date);

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueApple;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account?'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authLaterLink.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get authLaterLink;

  /// No description provided for @authDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get authDone;

  /// No description provided for @authVerifySent.
  ///
  /// In en, this message translates to:
  /// **'Freeva sent a confirmation link to {email}.'**
  String authVerifySent(String email);

  /// No description provided for @authVerifyWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'A confirmed email helps you'**
  String get authVerifyWhyTitle;

  /// No description provided for @authVerifyWhyReset.
  ///
  /// In en, this message translates to:
  /// **'Get your password back if you forget it'**
  String get authVerifyWhyReset;

  /// No description provided for @authVerifyWhyAlert.
  ///
  /// In en, this message translates to:
  /// **'Get alerts about unusual sign-ins'**
  String get authVerifyWhyAlert;

  /// No description provided for @authVerifyWhyNotice.
  ///
  /// In en, this message translates to:
  /// **'Never miss important account notices'**
  String get authVerifyWhyNotice;

  /// No description provided for @authResendPrompt.
  ///
  /// In en, this message translates to:
  /// **'Didn’t get it?'**
  String get authResendPrompt;

  /// No description provided for @authResendLink.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get authResendLink;

  /// No description provided for @authVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation link sent again.'**
  String get authVerificationSent;

  /// No description provided for @authVerifyLater.
  ///
  /// In en, this message translates to:
  /// **'You can use the app without confirming. Confirm later in Profile.'**
  String get authVerifyLater;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendResetLink;

  /// No description provided for @authResetSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authResetSentTitle;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'If {email} has an account, Freeva sent a reset link.'**
  String authResetSent(String email);

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToLogin;

  /// No description provided for @authConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get authConfirmNewPassword;

  /// No description provided for @authSaveAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Save and sign in'**
  String get authSaveAndLogin;

  /// No description provided for @authSocialSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get authSocialSoon;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Not enough yet'**
  String get passwordWeak;

  /// No description provided for @passwordGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordGood;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Very strong'**
  String get passwordStrong;

  /// No description provided for @passwordRuleLength.
  ///
  /// In en, this message translates to:
  /// **'At least 12 characters'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleLetterDigit.
  ///
  /// In en, this message translates to:
  /// **'Letters and numbers'**
  String get passwordRuleLetterDigit;

  /// No description provided for @passwordRuleSymbol.
  ///
  /// In en, this message translates to:
  /// **'Add a symbol like ! @ # to be stronger'**
  String get passwordRuleSymbol;

  /// No description provided for @passwordRuleMatch.
  ///
  /// In en, this message translates to:
  /// **'Both passwords match'**
  String get passwordRuleMatch;

  /// No description provided for @passwordRuleMet.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get passwordRuleMet;

  /// No description provided for @passwordRuleNotMet.
  ///
  /// In en, this message translates to:
  /// **'not yet'**
  String get passwordRuleNotMet;

  /// No description provided for @consentLabel.
  ///
  /// In en, this message translates to:
  /// **'Agree to the terms'**
  String get consentLabel;

  /// No description provided for @consentPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to Freeva’s '**
  String get consentPrefix;

  /// No description provided for @consentTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get consentTerms;

  /// No description provided for @consentAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get consentAnd;

  /// No description provided for @consentPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get consentPrivacy;

  /// No description provided for @consentSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get consentSuffix;

  /// No description provided for @authPinSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get authPinSetupTitle;

  /// No description provided for @authPinSetupSub.
  ///
  /// In en, this message translates to:
  /// **'6 digits to unlock Freeva on this device.'**
  String get authPinSetupSub;

  /// No description provided for @authPinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat your PIN'**
  String get authPinConfirmTitle;

  /// No description provided for @authPinConfirmSub.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6 digits again to be sure.'**
  String get authPinConfirmSub;

  /// No description provided for @authPinConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'If they don’t match you start again.'**
  String get authPinConfirmHint;

  /// No description provided for @authPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs didn’t match. Let’s start again.'**
  String get authPinMismatch;

  /// No description provided for @authConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get authConfirm;

  /// No description provided for @authBiometricTitleFace.
  ///
  /// In en, this message translates to:
  /// **'Set up Face ID'**
  String get authBiometricTitleFace;

  /// No description provided for @authBiometricSubFace.
  ///
  /// In en, this message translates to:
  /// **'Unlock Freeva with your face, faster than a PIN.'**
  String get authBiometricSubFace;

  /// No description provided for @authBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock faster'**
  String get authBiometricTitle;

  /// No description provided for @authBiometricSub.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint or face instead of typing the PIN.'**
  String get authBiometricSub;

  /// No description provided for @authBiometricSetup.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get authBiometricSetup;

  /// No description provided for @authLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get authLockTitle;

  /// No description provided for @authLockWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authLockWelcome;

  /// No description provided for @authForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot your PIN?'**
  String get authForgotPin;

  /// No description provided for @authForgotPinMessage.
  ///
  /// In en, this message translates to:
  /// **'You’ll sign in again with your email and password.'**
  String get authForgotPinMessage;

  /// No description provided for @authForgotPinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get authForgotPinConfirm;

  /// No description provided for @authCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authCancel;

  /// No description provided for @pinDigitsEntered.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} digits entered'**
  String pinDigitsEntered(int count, int total);

  /// No description provided for @meSecPinSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get meSecPinSetTitle;

  /// No description provided for @meSecPinNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get meSecPinNone;

  /// No description provided for @authUseFaceId.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Face ID'**
  String get authUseFaceId;

  /// No description provided for @meSecPinSetDone.
  ///
  /// In en, this message translates to:
  /// **'PIN set'**
  String get meSecPinSetDone;

  /// No description provided for @welcomeTitleLine1.
  ///
  /// In en, this message translates to:
  /// **'Money, made clear.'**
  String get welcomeTitleLine1;

  /// No description provided for @welcomeTitleLine2.
  ///
  /// In en, this message translates to:
  /// **'Life, made light.'**
  String get welcomeTitleLine2;

  /// No description provided for @welcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Log spending in seconds, every day.'**
  String get welcomeSub;

  /// No description provided for @welcomeStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeStart;

  /// No description provided for @welcomeSampleBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get welcomeSampleBalance;

  /// No description provided for @welcomeSampleFood.
  ///
  /// In en, this message translates to:
  /// **'Pho lunch'**
  String get welcomeSampleFood;

  /// No description provided for @welcomeSampleSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get welcomeSampleSalary;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your Freeva account'**
  String get signUpTitle;

  /// No description provided for @signUpSub.
  ///
  /// In en, this message translates to:
  /// **'Your data is safe and moves with you to a new phone.'**
  String get signUpSub;

  /// No description provided for @authContinueEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get authContinueEmail;

  /// No description provided for @signUpTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the '**
  String get signUpTermsPrefix;

  /// No description provided for @signUpTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get signUpTermsLink;

  /// No description provided for @signUpTermsSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get signUpTermsSuffix;

  /// No description provided for @onbProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String onbProgress(int current, int total);

  /// No description provided for @onbGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to improve?'**
  String get onbGoalsTitle;

  /// No description provided for @onbGoalsSub.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 2.'**
  String get onbGoalsSub;

  /// No description provided for @onbGoalTrack.
  ///
  /// In en, this message translates to:
  /// **'Track spending'**
  String get onbGoalTrack;

  /// No description provided for @onbGoalSave.
  ///
  /// In en, this message translates to:
  /// **'Save more'**
  String get onbGoalSave;

  /// No description provided for @onbGoalBudget.
  ///
  /// In en, this message translates to:
  /// **'Stay on budget'**
  String get onbGoalBudget;

  /// No description provided for @onbGoalDebt.
  ///
  /// In en, this message translates to:
  /// **'Manage debt'**
  String get onbGoalDebt;

  /// No description provided for @onbGoalEmergency.
  ///
  /// In en, this message translates to:
  /// **'Build an emergency fund'**
  String get onbGoalEmergency;

  /// No description provided for @onbGoalUnderstand.
  ///
  /// In en, this message translates to:
  /// **'Understand my finances'**
  String get onbGoalUnderstand;

  /// No description provided for @onbHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you manage money now?'**
  String get onbHabitTitle;

  /// No description provided for @onbHabitManual.
  ///
  /// In en, this message translates to:
  /// **'Notes by hand'**
  String get onbHabitManual;

  /// No description provided for @onbHabitSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Excel or Sheets'**
  String get onbHabitSpreadsheet;

  /// No description provided for @onbHabitApp.
  ///
  /// In en, this message translates to:
  /// **'Another app'**
  String get onbHabitApp;

  /// No description provided for @onbHabitNone.
  ///
  /// In en, this message translates to:
  /// **'Not tracking yet'**
  String get onbHabitNone;

  /// No description provided for @onbCadenceTitle.
  ///
  /// In en, this message translates to:
  /// **'How often do you review spending?'**
  String get onbCadenceTitle;

  /// No description provided for @onbCadenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get onbCadenceDaily;

  /// No description provided for @onbCadenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get onbCadenceWeekly;

  /// No description provided for @onbCadenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get onbCadenceMonthly;

  /// No description provided for @onbCadenceRarely.
  ///
  /// In en, this message translates to:
  /// **'Hardly ever'**
  String get onbCadenceRarely;

  /// No description provided for @onbBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'How much do you plan to spend each month?'**
  String get onbBudgetTitle;

  /// No description provided for @onbBudgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get onbBudgetAmount;

  /// No description provided for @onbBudgetLater.
  ///
  /// In en, this message translates to:
  /// **'Set up later'**
  String get onbBudgetLater;

  /// No description provided for @setupWalletsTitle.
  ///
  /// In en, this message translates to:
  /// **'Where is your money?'**
  String get setupWalletsTitle;

  /// No description provided for @setupWalletsSub.
  ///
  /// In en, this message translates to:
  /// **'Add wallets and balances. A rough number is enough.'**
  String get setupWalletsSub;

  /// No description provided for @setupAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get setupAdd;

  /// No description provided for @setupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get setupSkip;

  /// No description provided for @checklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Let’s get started'**
  String get checklistTitle;

  /// No description provided for @checklistWallet.
  ///
  /// In en, this message translates to:
  /// **'Create a wallet'**
  String get checklistWallet;

  /// No description provided for @checklistExpense.
  ///
  /// In en, this message translates to:
  /// **'Record your first expense'**
  String get checklistExpense;

  /// No description provided for @checklistRecordNow.
  ///
  /// In en, this message translates to:
  /// **'Record now'**
  String get checklistRecordNow;

  /// No description provided for @checklistPin.
  ///
  /// In en, this message translates to:
  /// **'Lock the app with a PIN'**
  String get checklistPin;

  /// No description provided for @authLockGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}'**
  String authLockGreeting(String name);

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncBannerBoth.
  ///
  /// In en, this message translates to:
  /// **'{attention} changes need you · {waiting} more waiting to send'**
  String syncBannerBoth(int attention, int waiting);

  /// No description provided for @syncBannerAttention.
  ///
  /// In en, this message translates to:
  /// **'{count} changes need you'**
  String syncBannerAttention(int count);

  /// No description provided for @syncBannerWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} changes waiting to send'**
  String syncBannerWaiting(int count);

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get syncOffline;

  /// No description provided for @syncUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t send yet'**
  String get syncUnavailable;

  /// No description provided for @syncUnavailableSub.
  ///
  /// In en, this message translates to:
  /// **'Try again later'**
  String get syncUnavailableSub;

  /// No description provided for @syncWaitingCard.
  ///
  /// In en, this message translates to:
  /// **'Changes are waiting to send'**
  String get syncWaitingCard;

  /// No description provided for @syncLastTime.
  ///
  /// In en, this message translates to:
  /// **'Last {when}'**
  String syncLastTime(String when);

  /// No description provided for @syncLastNever.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncLastNever;

  /// No description provided for @syncToday.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String syncToday(String time);

  /// No description provided for @syncOnDay.
  ///
  /// In en, this message translates to:
  /// **'{date} {time}'**
  String syncOnDay(String date, String time);

  /// No description provided for @syncRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get syncRetry;

  /// No description provided for @syncSending.
  ///
  /// In en, this message translates to:
  /// **'Sending {count} changes'**
  String syncSending(int count);

  /// No description provided for @syncSendingSub.
  ///
  /// In en, this message translates to:
  /// **'You can keep using the app'**
  String get syncSendingSub;

  /// No description provided for @syncAllDone.
  ///
  /// In en, this message translates to:
  /// **'Everything is synced'**
  String get syncAllDone;

  /// No description provided for @syncSectionAttention.
  ///
  /// In en, this message translates to:
  /// **'NEEDS YOU · {count}'**
  String syncSectionAttention(int count);

  /// No description provided for @syncSectionWaiting.
  ///
  /// In en, this message translates to:
  /// **'WAITING TO SEND · {count}'**
  String syncSectionWaiting(int count);

  /// No description provided for @syncSectionHolding.
  ///
  /// In en, this message translates to:
  /// **'KEPT ON THIS DEVICE · {count}'**
  String syncSectionHolding(int count);

  /// No description provided for @syncActionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get syncActionAdd;

  /// No description provided for @syncActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get syncActionEdit;

  /// No description provided for @syncActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get syncActionDelete;

  /// No description provided for @syncActionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get syncActionRestore;

  /// No description provided for @syncItemLine.
  ///
  /// In en, this message translates to:
  /// **'{action} · {detail}'**
  String syncItemLine(String action, String detail);

  /// No description provided for @syncReasonChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed on another device'**
  String get syncReasonChanged;

  /// No description provided for @syncReasonWallet.
  ///
  /// In en, this message translates to:
  /// **'The wallet was removed'**
  String get syncReasonWallet;

  /// No description provided for @syncReasonMissing.
  ///
  /// In en, this message translates to:
  /// **'The transaction was removed elsewhere'**
  String get syncReasonMissing;

  /// No description provided for @syncReasonInvalid.
  ///
  /// In en, this message translates to:
  /// **'The details are no longer valid'**
  String get syncReasonInvalid;

  /// No description provided for @syncReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t send · Try again later'**
  String get syncReasonOther;

  /// No description provided for @syncFooter.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this device until it is sent.'**
  String get syncFooter;

  /// No description provided for @syncUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Freeva needs an update'**
  String get syncUpdateTitle;

  /// No description provided for @syncUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'To keep syncing. Your changes are kept.'**
  String get syncUpdateBody;

  /// No description provided for @syncDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this change?'**
  String get syncDiscardTitle;

  /// No description provided for @syncDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} {amount} won’t be saved.'**
  String syncDiscardMessage(String name, String amount);

  /// No description provided for @syncDiscardMessageShort.
  ///
  /// In en, this message translates to:
  /// **'{name} won’t be saved.'**
  String syncDiscardMessageShort(String name);

  /// No description provided for @syncDiscardKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get syncDiscardKeep;

  /// No description provided for @syncDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get syncDiscardConfirm;

  /// No description provided for @syncDiscardSemantics.
  ///
  /// In en, this message translates to:
  /// **'Discard change {name}'**
  String syncDiscardSemantics(String name);

  /// No description provided for @syncChipReview.
  ///
  /// In en, this message translates to:
  /// **'Needs a look'**
  String get syncChipReview;

  /// No description provided for @syncChipWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get syncChipWaiting;

  /// No description provided for @syncViewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get syncViewAction;

  /// No description provided for @syncCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which to keep'**
  String get syncCompareTitle;

  /// No description provided for @syncCompareIntroA.
  ///
  /// In en, this message translates to:
  /// **'{name} was just changed on another device. The differences are '**
  String syncCompareIntroA(String name);

  /// No description provided for @syncCompareIntroB.
  ///
  /// In en, this message translates to:
  /// **'highlighted'**
  String get syncCompareIntroB;

  /// No description provided for @syncCompareIntroC.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get syncCompareIntroC;

  /// No description provided for @syncCompareMine.
  ///
  /// In en, this message translates to:
  /// **'This device’s version'**
  String get syncCompareMine;

  /// No description provided for @syncCompareMineWhen.
  ///
  /// In en, this message translates to:
  /// **'You changed it {when}'**
  String syncCompareMineWhen(String when);

  /// No description provided for @syncCompareSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved version'**
  String get syncCompareSaved;

  /// No description provided for @syncCompareSavedWhen.
  ///
  /// In en, this message translates to:
  /// **'Changed elsewhere {when}'**
  String syncCompareSavedWhen(String when);

  /// No description provided for @syncCompareSavedNoTime.
  ///
  /// In en, this message translates to:
  /// **'Saved on the server'**
  String get syncCompareSavedNoTime;

  /// No description provided for @syncCompareDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get syncCompareDeleted;

  /// No description provided for @syncFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get syncFieldAmount;

  /// No description provided for @syncFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get syncFieldCategory;

  /// No description provided for @syncFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get syncFieldNotes;

  /// No description provided for @syncFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get syncFieldDate;

  /// No description provided for @syncFieldMerchant.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get syncFieldMerchant;

  /// No description provided for @syncKeepSaved.
  ///
  /// In en, this message translates to:
  /// **'Keep the saved version'**
  String get syncKeepSaved;

  /// No description provided for @syncKeepMine.
  ///
  /// In en, this message translates to:
  /// **'Keep this device’s version'**
  String get syncKeepMine;

  /// No description provided for @syncDupTitle.
  ///
  /// In en, this message translates to:
  /// **'You may have recorded this already'**
  String get syncDupTitle;

  /// No description provided for @syncDupSub.
  ///
  /// In en, this message translates to:
  /// **'These two look the same.'**
  String get syncDupSub;

  /// No description provided for @syncDupJust.
  ///
  /// In en, this message translates to:
  /// **'JUST RECORDED'**
  String get syncDupJust;

  /// No description provided for @syncDupExisting.
  ///
  /// In en, this message translates to:
  /// **'ALREADY THERE'**
  String get syncDupExisting;

  /// No description provided for @syncDupKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get syncDupKeepBoth;

  /// No description provided for @syncDupDeleteNew.
  ///
  /// In en, this message translates to:
  /// **'Delete the new one'**
  String get syncDupDeleteNew;

  /// No description provided for @syncBannerOthersWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} other changes waiting to send'**
  String syncBannerOthersWaiting(Object count);

  /// No description provided for @syncLastToday.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time} today'**
  String syncLastToday(Object time);

  /// No description provided for @syncSectionSending.
  ///
  /// In en, this message translates to:
  /// **'SENDING'**
  String get syncSectionSending;

  /// No description provided for @reportDonutTotalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get reportDonutTotalExpense;

  /// No description provided for @reportDonutTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get reportDonutTotalIncome;

  /// No description provided for @reportBarGeneralSuffix.
  ///
  /// In en, this message translates to:
  /// **'(general)'**
  String get reportBarGeneralSuffix;

  /// No description provided for @reportEmptyTitleMonth.
  ///
  /// In en, this message translates to:
  /// **'No data for month {month} yet'**
  String reportEmptyTitleMonth(Object month);

  /// No description provided for @meLegal.
  ///
  /// In en, this message translates to:
  /// **'Terms and privacy'**
  String get meLegal;

  /// No description provided for @meNotifyOnCount.
  ///
  /// In en, this message translates to:
  /// **'{count} on'**
  String meNotifyOnCount(Object count);

  /// No description provided for @meGoalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} goals'**
  String meGoalsCount(Object count);

  /// No description provided for @meProfileEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email · verified'**
  String get meProfileEmailVerified;

  /// No description provided for @meProfileEmailUnverified.
  ///
  /// In en, this message translates to:
  /// **'Email · not verified'**
  String get meProfileEmailUnverified;

  /// No description provided for @meDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get meDeleteAccount;

  /// No description provided for @meChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get meChangeAvatar;

  /// No description provided for @meSecurityValueFaceId.
  ///
  /// In en, this message translates to:
  /// **'PIN · Face ID'**
  String get meSecurityValueFaceId;

  /// No description provided for @meSecFaceId.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Face ID'**
  String get meSecFaceId;

  /// No description provided for @notifySessionSubAlways.
  ///
  /// In en, this message translates to:
  /// **'Always on so you can check'**
  String get notifySessionSubAlways;

  /// No description provided for @faqRecordQ.
  ///
  /// In en, this message translates to:
  /// **'How do I record an expense?'**
  String get faqRecordQ;

  /// No description provided for @faqRecordA.
  ///
  /// In en, this message translates to:
  /// **'Tap + in the middle of the bottom bar, enter the amount, pick a category and save. Wallet and date reuse your last choice.'**
  String get faqRecordA;

  /// No description provided for @faqTransferQ.
  ///
  /// In en, this message translates to:
  /// **'Moving money between two wallets?'**
  String get faqTransferQ;

  /// No description provided for @faqTransferA.
  ///
  /// In en, this message translates to:
  /// **'Tap +, choose Transfer, pick the from and to wallets and enter the amount. Both balances update together.'**
  String get faqTransferA;

  /// No description provided for @faqDeletedQ.
  ///
  /// In en, this message translates to:
  /// **'Deleted a transaction by mistake?'**
  String get faqDeletedQ;

  /// No description provided for @faqDeletedA.
  ///
  /// In en, this message translates to:
  /// **'Tap Undo right after deleting. Later you can still restore it from Deleted in Transactions.'**
  String get faqDeletedA;

  /// No description provided for @faqMonthQ.
  ///
  /// In en, this message translates to:
  /// **'What is a financial month?'**
  String get faqMonthQ;

  /// No description provided for @faqMonthA.
  ///
  /// In en, this message translates to:
  /// **'It\'s the period your monthly totals cover. If you\'re paid on the 5th, set Month starts on day 5 in Me so the numbers match.'**
  String get faqMonthA;

  /// No description provided for @faqLockAppQ.
  ///
  /// In en, this message translates to:
  /// **'Locking the app with PIN or Face ID'**
  String get faqLockAppQ;

  /// No description provided for @faqLockAppA.
  ///
  /// In en, this message translates to:
  /// **'Go to Me, Security to set a PIN. With a PIN you can turn on Face ID. Without a PIN the app doesn\'t lock.'**
  String get faqLockAppA;

  /// No description provided for @faqSafeQ.
  ///
  /// In en, this message translates to:
  /// **'Is my data safe?'**
  String get faqSafeQ;

  /// No description provided for @faqSafeA.
  ///
  /// In en, this message translates to:
  /// **'Your data lives in your Freeva account, so changing phones doesn\'t lose it. Lock the app with a PIN so others can\'t see it.'**
  String get faqSafeA;

  /// No description provided for @homeOfflineHeading.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get homeOfflineHeading;

  /// No description provided for @homeOfflineDetail.
  ///
  /// In en, this message translates to:
  /// **'Figures as of {time}. You can still record spending.'**
  String homeOfflineDetail(Object time);

  /// No description provided for @homeCreditUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get homeCreditUsedLabel;

  /// No description provided for @homeCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit {limit}'**
  String homeCreditLimit(Object limit);

  /// No description provided for @homeOtherCurrencyMeta.
  ///
  /// In en, this message translates to:
  /// **'{currency} · {count} wallets'**
  String homeOtherCurrencyMeta(Object currency, Object count);

  /// No description provided for @homeTotalBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get homeTotalBalanceLabel;

  /// No description provided for @authResetVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified {email}'**
  String authResetVerified(Object email);

  /// No description provided for @currencyNameVnd.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese dong'**
  String get currencyNameVnd;

  /// No description provided for @currencyNameUsd.
  ///
  /// In en, this message translates to:
  /// **'US dollar'**
  String get currencyNameUsd;

  /// No description provided for @currencyNameEur.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get currencyNameEur;

  /// No description provided for @currencyNameJpy.
  ///
  /// In en, this message translates to:
  /// **'Japanese yen'**
  String get currencyNameJpy;

  /// No description provided for @currencyNameKrw.
  ///
  /// In en, this message translates to:
  /// **'South Korean won'**
  String get currencyNameKrw;

  /// No description provided for @currencyNameCny.
  ///
  /// In en, this message translates to:
  /// **'Chinese yuan'**
  String get currencyNameCny;

  /// No description provided for @currencyNameSgd.
  ///
  /// In en, this message translates to:
  /// **'Singapore dollar'**
  String get currencyNameSgd;

  /// No description provided for @currencyNameThb.
  ///
  /// In en, this message translates to:
  /// **'Thai baht'**
  String get currencyNameThb;

  /// No description provided for @currencyNameAud.
  ///
  /// In en, this message translates to:
  /// **'Australian dollar'**
  String get currencyNameAud;

  /// No description provided for @currencyNameGbp.
  ///
  /// In en, this message translates to:
  /// **'British pound'**
  String get currencyNameGbp;

  /// No description provided for @currencyCodeName.
  ///
  /// In en, this message translates to:
  /// **'{code} · {name}'**
  String currencyCodeName(Object code, Object name);

  /// No description provided for @tagsViewTransactions.
  ///
  /// In en, this message translates to:
  /// **'View transactions'**
  String get tagsViewTransactions;
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
