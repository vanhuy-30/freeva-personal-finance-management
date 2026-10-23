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
  String get walletHide => 'Hide wallet';

  @override
  String get walletHiddenEmpty => 'No hidden wallets.';

  @override
  String get walletInvalid => 'Check the name and amounts.';

  @override
  String get walletConflict =>
      'This wallet changed elsewhere. Open it again to edit.';

  @override
  String get walletError => 'Couldn\'t save the wallet. Try again.';

  @override
  String get transactionTitle => 'Transactions';

  @override
  String get transactionRecord => 'Record transaction';

  @override
  String get transactionExpense => 'Expense';

  @override
  String get transactionIncome => 'Income';

  @override
  String get transactionTransfer => 'Transfer';

  @override
  String get transactionAll => 'All';

  @override
  String get transactionAmount => 'Amount';

  @override
  String get transactionWallet => 'Wallet';

  @override
  String get transactionDestination => 'Destination wallet';

  @override
  String get transactionCategory => 'Category';

  @override
  String get transactionAllCategories => 'All categories';

  @override
  String get transactionDate => 'Date';

  @override
  String get transactionNotes => 'Note';

  @override
  String get transactionMerchant => 'Payee / merchant';

  @override
  String get transactionTags => 'Tags';

  @override
  String get transactionTagCreate => 'Create tag';

  @override
  String get transactionTagCreateTitle => 'Create a new tag';

  @override
  String get transactionTagName => 'Tag name';

  @override
  String get transactionTagLimit => 'Up to 20 tags';

  @override
  String get transactionSave => 'Save';

  @override
  String get transactionEdit => 'Edit transaction';

  @override
  String get transactionCopy => 'Copy';

  @override
  String get transactionDelete => 'Delete';

  @override
  String get transactionRestore => 'Restore';

  @override
  String get transactionDeleteTitle => 'Delete transaction?';

  @override
  String get transactionDeleteBody =>
      'The transaction is soft-deleted and no longer counts toward the balance.';

  @override
  String get transactionCancel => 'Cancel';

  @override
  String get transactionEmpty => 'No transactions yet.';

  @override
  String get transactionDeletedEmpty => 'No deleted transactions.';

  @override
  String get transactionNoWallet =>
      'Add an active wallet before recording a transaction.';

  @override
  String get transactionCreateWallet => 'Create wallet';

  @override
  String get transactionShowDeleted => 'Show deleted transactions';

  @override
  String get transactionSearch => 'Search notes';

  @override
  String get transactionInvalid =>
      'Check the amount, wallet, category, date, or exchange rate. Expenses need a category. A cross-currency transfer accepts only an exact rate.';

  @override
  String get transactionConflict =>
      'This transaction changed elsewhere. Reload the list before editing again.';

  @override
  String get transactionError =>
      'Could not load or save transactions. Please try again.';

  @override
  String get transactionReloadRequired =>
      'The data is stale. Reload before recording again.';

  @override
  String get transactionRate => 'Exchange rate';

  @override
  String get transactionRateHint =>
      'Enter a manual rate. The destination amount must match the smallest currency unit exactly.';

  @override
  String get transactionLoadMore => 'Load more';

  @override
  String syncPending(int count) {
    return '$count changes waiting to sync';
  }

  @override
  String get syncNow => 'Sync';

  @override
  String get syncing => 'Syncing';

  @override
  String get syncConflict =>
      'Not overwritten. Reload to see the copy on the server.';

  @override
  String get syncReview =>
      'The amount differs from the saved copy. Not overwritten.';

  @override
  String get syncFailedItem => 'This change could not be synced.';

  @override
  String get syncDiscard => 'Discard';

  @override
  String get syncSchema =>
      'Sync is paused because the app and server schemas differ.';

  @override
  String get syncDuplicate =>
      'A similar transaction may already exist. This one was still kept.';

  @override
  String get syncDelete => 'Delete';

  @override
  String get syncRestore => 'Restore';

  @override
  String get syncChange => 'Change';

  @override
  String syncItem(String action, String date) {
    return '$action · $date';
  }

  @override
  String get categoryTitle => 'Categories';

  @override
  String get categoryAdd => 'Add category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryParent => 'Parent category';

  @override
  String get categoryNoParent => 'No parent';

  @override
  String get categoryColor => 'Color';

  @override
  String get categoryNoColor => 'No color';

  @override
  String get categoryIcon => 'Icon';

  @override
  String get categoryNoIcon => 'No icon';

  @override
  String get categorySystem => 'Default category';

  @override
  String get categoryShowHidden => 'Show hidden categories';

  @override
  String get categoryHide => 'Hide category';

  @override
  String get categoryRestore => 'Restore category';

  @override
  String get categoryHideExplanation =>
      'Hiding archives the category from the active list. Existing transactions keep it; hidden categories cannot be used for new records.';

  @override
  String get categoryHideBlocked =>
      'Hide or move active child categories before hiding this one.';

  @override
  String get categoryDelete => 'Delete category';

  @override
  String get categoryDeleteTitle => 'Delete this category permanently?';

  @override
  String get categoryDeleteBody =>
      'A deleted category cannot be restored. If any transaction still references it, including a soft-deleted one, choose a replacement.';

  @override
  String get categoryDeleteBlocked =>
      'Delete or move every child, including hidden ones, before deleting this category.';

  @override
  String get categoryReplacement => 'Replacement category';

  @override
  String get categoryNoReplacement => 'Do not move transactions';

  @override
  String get categoryEmpty => 'No categories yet.';

  @override
  String get categoryHiddenEmpty => 'No hidden categories.';

  @override
  String get categoryInvalid =>
      'Check the name (1–100 characters), parent, color and icon. A category cannot be its own parent or sit under its child.';

  @override
  String get categoryConflict =>
      'This category changed elsewhere. Reload the list before editing again.';

  @override
  String get categoryError =>
      'Could not load or save categories. Please try again.';

  @override
  String get categoryReloadRequired =>
      'The data is stale. Reload before editing again.';

  @override
  String get reportTitle => 'Reports';

  @override
  String get reportOverview => 'Overview';

  @override
  String get reportThisMonth => 'This month';

  @override
  String get reportNetWorth => 'Net worth';

  @override
  String get reportAssets => 'Assets';

  @override
  String get reportLiabilities => 'Liabilities';

  @override
  String get reportIncome => 'Income';

  @override
  String get reportExpense => 'Expense';

  @override
  String get reportNet => 'Cashflow';

  @override
  String get reportTransfer => 'Transfer';

  @override
  String get reportWeek => 'Week';

  @override
  String get reportMonth => 'Month';

  @override
  String get reportRange => 'Date range';

  @override
  String get reportPrevious => 'Previous period';

  @override
  String get reportNext => 'Next period';

  @override
  String get reportFrom => 'From';

  @override
  String get reportTo => 'To';

  @override
  String get reportApply => 'Show this range';

  @override
  String get reportByCategory => 'By category';

  @override
  String get reportByAccount => 'By wallet';

  @override
  String get reportUncategorized => 'Uncategorized';

  @override
  String get reportEmpty => 'Nothing to show for this period.';

  @override
  String get reportError => 'Could not load the report. Please try again.';

  @override
  String get reportInvalid =>
      'That date range is invalid. The start must be on or before the end, and the dates can be at most 3660 days apart.';

  @override
  String reportPeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String reportAmount(String label, String amount, String currency) {
    return '$label: $amount $currency';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsBack => 'Back';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsProfile => 'Language, currency, and time zone';

  @override
  String get settingsPermissions => 'System access';

  @override
  String get settingsBiometric => 'Biometric unlock';

  @override
  String get settingsBiometricReason =>
      'Authenticate to change biometric unlock';

  @override
  String get settingsBiometricOn => 'On';

  @override
  String get settingsBiometricOff => 'Off';

  @override
  String get settingsBiometricUnavailable =>
      'This device has no biometrics available.';

  @override
  String get settingsBiometricPin =>
      'Set up a PIN on the lock screen before enabling biometrics.';

  @override
  String get settingsBiometricFailed =>
      'Biometrics were not confirmed. The setting was not changed.';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsFaq => 'FAQ';

  @override
  String get settingsFeedback => 'Send feedback';

  @override
  String get settingsTerms => 'Terms of service (draft)';

  @override
  String get settingsPrivacy => 'Privacy policy (draft)';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsStorageError =>
      'Settings could not be saved on this device. Please try again.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingFinish => 'Done';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Freeva';

  @override
  String get onboardingWelcomeBody =>
      'A short introduction so you can record money without extra help.';

  @override
  String get onboardingWalletTitle => 'Create a wallet';

  @override
  String get onboardingWalletBody =>
      'Add a cash, bank, e-wallet, or credit wallet. Each amount stays in its own currency.';

  @override
  String get onboardingTransactionTitle => 'Record the first transaction';

  @override
  String get onboardingTransactionBody =>
      'From Home, record income, an expense, or a transfer between two wallets.';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqWalletQ => 'How do I add a wallet?';

  @override
  String get faqWalletA =>
      'Open Wallets from Home, then create a cash, bank, e-wallet, or credit wallet.';

  @override
  String get faqTransactionQ => 'How do I record a transaction?';

  @override
  String get faqTransactionA =>
      'Open Transactions or use Record transaction on Home. Choose income, an expense, or a transfer with two balanced sides.';

  @override
  String get faqProfileQ => 'How do I change language, currency, or time zone?';

  @override
  String get faqProfileA =>
      'Open Settings, then Language, currency, and time zone. The language changes after the profile is saved.';

  @override
  String get faqLockQ => 'How do I lock the app?';

  @override
  String get faqLockA =>
      'Freeva locks when you leave the app. Unlock with your six-digit PIN. You can turn on biometrics in Settings after a PIN exists.';

  @override
  String get faqThemeQ => 'How do I switch light and dark mode?';

  @override
  String get faqThemeA =>
      'Open Settings and choose Light, Dark, or System. Light is the default and stays on this device.';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get feedbackIdea => 'Idea';

  @override
  String get feedbackProblem => 'Problem';

  @override
  String get feedbackMessage => 'Message';

  @override
  String get feedbackCopy => 'Copy feedback';

  @override
  String get feedbackCopied =>
      'Copied. A contact address is not configured yet, so Freeva does not send this message.';

  @override
  String get feedbackInvalid => 'Enter a message of up to 2000 characters.';

  @override
  String get feedbackHelp =>
      'Freeva copies the message on this device. It is not uploaded and is not written to logs.';

  @override
  String get legalDraft =>
      'Draft for PRD-P0-002. This is not legal advice and is not in effect. The operating entity and contact channel are not decided yet.';

  @override
  String get tosTitle => 'Terms of service';

  @override
  String get tosBody =>
      'Freeva lets you record wallets and transactions you enter. You keep your financial data. The service operator is not decided yet. Account export and deletion are separate release work. This summary does not replace a lawyer-reviewed agreement.';

  @override
  String get privacyTitle => 'Privacy policy';

  @override
  String get privacyBody =>
      'The account stores email, language, time zone, default currency, and the financial month start day. Amounts you enter are not written to logs. Feedback you compose stays on this device until a contact channel exists. Analytics events do not include email, balances, or account numbers. This summary does not replace a lawyer-reviewed policy.';

  @override
  String get balanceHiddenMask => '••••';

  @override
  String get balanceHide => 'Hide balances';

  @override
  String get balanceShow => 'Show balances';

  @override
  String get settingsPrivacyControls => 'Privacy';

  @override
  String get settingsHideBalances => 'Hide balances';

  @override
  String get settingsHideBalancesHelp =>
      'Masks amounts shown on this device. Fields you are editing still show what you type.';

  @override
  String get settingsSessionAlerts => 'New sign-in alerts';

  @override
  String get settingsSessionAlertsHelp =>
      'Warns on this device when another session appears. The alert does not include an email, balance, or device name.';

  @override
  String get sessionAlertTitle => 'New sign-in';

  @override
  String get sessionAlertBody =>
      'Another session signed in. Open Freeva to review it and revoke it if it was not you.';

  @override
  String get sessionAlertReview => 'Review sessions';

  @override
  String get navOverview => 'Overview';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navReports => 'Reports';

  @override
  String get navMe => 'Me';

  @override
  String get navRecord => 'Record transaction';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get balanceHiddenSemantics => 'balance hidden';

  @override
  String get keypadDelete => 'Delete';

  @override
  String get commonLoading => 'Loading';

  @override
  String get passwordShow => 'Show password';

  @override
  String get passwordHide => 'Hide password';

  @override
  String get homeDatePattern => 'EEEE, MMM d';

  @override
  String get homeMonthPattern => 'MMMM';

  @override
  String homeGreeting(String name) {
    return 'Hi $name';
  }

  @override
  String get homeGreetingAnon => 'Hi there';

  @override
  String get homeSearch => 'Search transactions';

  @override
  String get homeNotifications => 'Notifications';

  @override
  String homeTotalBalance(int count) {
    return 'Total balance · $count wallets';
  }

  @override
  String homeTotalBalanceIn(int count, String currency) {
    return 'Total balance · $count $currency wallets';
  }

  @override
  String homeOtherCurrency(String amount, String currency, int count) {
    return '$amount $currency · $count wallets';
  }

  @override
  String homeIncomeMonth(String month) {
    return 'Income in $month';
  }

  @override
  String homeExpenseMonth(String month) {
    return 'Spent in $month';
  }

  @override
  String get homeQuickIncome => 'Add income';

  @override
  String get homeQuickTransfer => 'Move money';

  @override
  String get homeQuickWallets => 'My wallets';

  @override
  String get homeQuickCategories => 'Categories';

  @override
  String get homeSpendOther => 'Other';

  @override
  String get homeSpendEmpty => 'No spending yet.';

  @override
  String get homeSpendRecord => 'Add expense';

  @override
  String homeOtherCurrencySpend(String currency, String amount) {
    return '$currency wallets: $amount $currency spent this month';
  }

  @override
  String homeReviewMonth(String month) {
    return 'Look back at $month';
  }

  @override
  String homeReviewLine(String expense, String income) {
    return 'Spent $expense · Earned $income';
  }

  @override
  String get homeCreditTitle => 'Credit cards';

  @override
  String homeCreditDue(String date) {
    return 'Due $date';
  }

  @override
  String homeCreditUsed(String used, String limit) {
    return 'Used $used of $limit';
  }

  @override
  String homeCreditUsedNoLimit(String used) {
    return 'Used $used';
  }

  @override
  String get homeRecent => 'Recent';

  @override
  String get homeSeeTransactions => 'See transactions';

  @override
  String get homeRecentEmpty => 'Your transactions will show here';

  @override
  String get homePendingSync => 'Waiting to sync';

  @override
  String homeOfflineTitle(String time) {
    return 'Offline · Figures from $time';
  }

  @override
  String get homeOfflineBody => 'You can still add expenses.';

  @override
  String get homeErrorTitle => 'Couldn\'t load your balance';

  @override
  String get homeErrorBody => 'Your data is safe.';

  @override
  String homeSpokenExpense(String amount, String currency) {
    return 'minus $amount $currency';
  }

  @override
  String homeSpokenIncome(String amount, String currency) {
    return 'plus $amount $currency';
  }

  @override
  String homeSpokenRow(String amount, String title, String detail) {
    return '$amount, $title, $detail';
  }

  @override
  String get homeUncategorized => 'Uncategorized';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsEmptyBody => 'Reminders and alerts will show here.';

  @override
  String get homeSpokenVnd => 'dong';

  @override
  String get txSearchAction => 'Search';

  @override
  String get txFilterAction => 'Filters';

  @override
  String get txFilterActive => 'Filters on';

  @override
  String get txPeriodThisWeek => 'This week';

  @override
  String get txPeriodThisMonth => 'This month';

  @override
  String get txPeriodLastMonth => 'Last month';

  @override
  String get txPeriodCustom => 'Custom';

  @override
  String get txPeriodAllTime => 'All time';

  @override
  String txMonthChip(String month) {
    return '$month';
  }

  @override
  String txRangeChip(String from, String to) {
    return '$from – $to';
  }

  @override
  String get txToday => 'Today';

  @override
  String txDayHeader(String day, String date) {
    return '$day · $date';
  }

  @override
  String txChipRemove(String label) {
    return 'Remove $label';
  }

  @override
  String get txFilterReset => 'Reset';

  @override
  String get txFilterPeriod => 'Time';

  @override
  String get txFilterWallets => 'Wallets';

  @override
  String get txFilterCategories => 'Categories';

  @override
  String get txFilterTags => 'Tags';

  @override
  String get txFilterAny => 'All';

  @override
  String get txFilterDeleted => 'Deleted';

  @override
  String txFilterApply(int count) {
    return 'Show $count transactions';
  }

  @override
  String get txFilterApplyUnknown => 'Show transactions';

  @override
  String get txFilterDone => 'Done';

  @override
  String get txNoResultTitle => 'No matching transactions';

  @override
  String get txNoResultBody => 'Try removing a filter.';

  @override
  String get txNoResultClear => 'Clear filters';

  @override
  String get txEmptyTitle => 'No transactions yet';

  @override
  String get txEmptyBody => 'Your first expense takes seconds.';

  @override
  String get txEmptyAction => 'Add expense';

  @override
  String get txSearchHint => 'Search transactions';

  @override
  String get txSearchCancel => 'Cancel';

  @override
  String get txSearchClear => 'Clear text';

  @override
  String txSearchResults(int count) {
    return '$count results';
  }

  @override
  String get txSearchPrompt => 'Search by store, note or amount.';

  @override
  String get txDetailCategory => 'Category';

  @override
  String get txDetailWallet => 'Wallet';

  @override
  String get txDetailDate => 'Date';

  @override
  String get txDetailTags => 'Tags';

  @override
  String get txDetailNotes => 'Note';

  @override
  String get txDetailFrom => 'From';

  @override
  String get txDetailTo => 'To';

  @override
  String get txDetailDelete => 'Delete transaction';

  @override
  String get txDetailCopy => 'Duplicate';

  @override
  String get txDetailEdit => 'Edit';

  @override
  String get txKindExpense => 'expense';

  @override
  String get txKindIncome => 'income';

  @override
  String get txKindTransfer => 'transfer';

  @override
  String txDeletedToast(String kind) {
    return 'Deleted $kind';
  }

  @override
  String get txRestoredToast => 'Restored';

  @override
  String get txTrashTitle => 'Deleted';

  @override
  String get txTrashBody => 'Restore to bring it back to your list.';

  @override
  String get txTrashRestore => 'Restore';

  @override
  String get txTrashEmpty => 'Nothing deleted';

  @override
  String get txLoadFailed => 'Couldn\'t load transactions';

  @override
  String get txTransferTitle => 'Transfer';

  @override
  String get txAmountLabel => 'Amount';

  @override
  String get txTransferAmountLabel => 'Amount to move';

  @override
  String get txDateLabel => 'Date';

  @override
  String get txMoreButton => 'Note, store, tags';

  @override
  String get txSaveExpense => 'Save expense';

  @override
  String get txSaveIncome => 'Save income';

  @override
  String get txSaveTransfer => 'Save transfer';

  @override
  String get txSaveChanges => 'Save changes';

  @override
  String txEditTitle(String kind) {
    return 'Edit $kind';
  }

  @override
  String get txMerchantLabel => 'Store';

  @override
  String get txMerchantHint => 'e.g. Corner Café';

  @override
  String get txNotesHint => 'Add a note';

  @override
  String get txAddTag => 'Add tag';

  @override
  String get txPickCategory => 'Choose a category';

  @override
  String get txFindCategory => 'Find a category';

  @override
  String get txFrequent => 'Frequent';

  @override
  String get txFindOrCreateTag => 'Find or create a tag';

  @override
  String txCreateTag(String name) {
    return 'Create tag “$name”';
  }

  @override
  String get txSelected => 'Selected';

  @override
  String get txSwap => 'Swap direction';

  @override
  String get txPickWallet => 'Choose a wallet';

  @override
  String get txWalletSubExpense => 'The expense comes out of this wallet';

  @override
  String get txWalletSubIncome => 'The income goes into this wallet';

  @override
  String txRateLabel(String time) {
    return 'Rate at $time';
  }

  @override
  String get txRateEmpty => 'Enter a rate';

  @override
  String txRateValue(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String get txReceived => 'Received';

  @override
  String get txRateTitle => 'Exchange rate';

  @override
  String get txDateTitle => 'Choose a date';

  @override
  String get txYesterday => 'Yesterday';

  @override
  String txSavedToast(String kind) {
    return 'Saved $kind';
  }

  @override
  String txDiscardTitle(String kind) {
    return 'Discard this $kind?';
  }

  @override
  String get txDiscardBody => 'The amount and note won\'t be saved.';

  @override
  String get txKeepEditing => 'Keep editing';

  @override
  String get txDiscard => 'Discard';

  @override
  String get txAmountMissing => 'Enter an amount first.';

  @override
  String get txPickDestination => 'Choose the wallet that receives it.';

  @override
  String get txRateInvalid => 'This rate doesn\'t work for this amount.';

  @override
  String walletTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets',
      one: '1 wallet',
    );
    return 'Total balance · $_temp0';
  }

  @override
  String walletOtherTotal(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets',
      one: '1 wallet',
    );
    return '$amount · $_temp0';
  }

  @override
  String get walletSort => 'Sort';

  @override
  String get walletSortTitle => 'Arrange wallets';

  @override
  String get walletSortHint => 'Hold and drag, or use the arrows.';

  @override
  String get walletSortDone => 'Done';

  @override
  String walletMoveUpNamed(String name) {
    return 'Move $name up';
  }

  @override
  String walletMoveDownNamed(String name) {
    return 'Move $name down';
  }

  @override
  String get walletSortFailed => 'Couldn\'t save the order. Try again.';

  @override
  String get walletHiddenTitle => 'Hidden wallets';

  @override
  String get walletHiddenHint => 'History stays. Restore any time.';

  @override
  String get walletRestoreShort => 'Restore';

  @override
  String walletRestored(String name) {
    return '$name is back';
  }

  @override
  String walletRestoreNamed(String name) {
    return 'Restore $name';
  }

  @override
  String walletDueOn(String date) {
    return 'due $date';
  }

  @override
  String walletTypeCurrency(String type, String currency) {
    return '$type · $currency';
  }

  @override
  String walletMonthIn(String month) {
    return 'In, month $month';
  }

  @override
  String walletMonthOut(String month) {
    return 'Out, month $month';
  }

  @override
  String get walletRecordFrom => 'Record from here';

  @override
  String get walletTransfer => 'Transfer';

  @override
  String get walletEditCard => 'Edit card';

  @override
  String get walletNoTransactions => 'No transactions yet';

  @override
  String get walletNoTransactionsBody =>
      'Record the first one from this wallet.';

  @override
  String get creditNoTransactionsBody => 'Record the first one from this card.';

  @override
  String get walletNotFound => 'This wallet isn\'t here';

  @override
  String get walletEmptyTitle => 'No wallets yet';

  @override
  String get walletEmptyBody => 'Add your first wallet to start.';

  @override
  String get creditDebtLabel => 'Balance owed · Credit card';

  @override
  String get creditAvailableLabel => 'Available';

  @override
  String creditLimit(String amount) {
    return 'Limit $amount';
  }

  @override
  String get creditDueTitle => 'Payment due';

  @override
  String creditDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get creditCloseTitle => 'Statement closes';

  @override
  String creditCloseValue(int day) {
    return 'Day $day each month';
  }

  @override
  String get creditNotSet => 'Not set';

  @override
  String get creditRecordFrom => 'Record from card';

  @override
  String get creditPay => 'Pay card';

  @override
  String get walletLoadError => 'Couldn\'t load wallets';

  @override
  String get cardName => 'Card name';

  @override
  String get walletCurrencyField => 'Currency';

  @override
  String get walletCurrencyTitle => 'Choose currency';

  @override
  String get walletCurrentBalance => 'Current balance';

  @override
  String get walletBalanceHint =>
      'A rough number is fine. You can change it later.';

  @override
  String get creditCurrentDebt => 'Current balance owed';

  @override
  String get creditInitialDebt => 'Starting balance owed';

  @override
  String get creditLimitField => 'Limit';

  @override
  String get creditCloseField => 'Statement day';

  @override
  String get creditDueField => 'Due day';

  @override
  String creditDayValue(int day) {
    return 'Day $day';
  }

  @override
  String get creditPickDay => 'Pick a day';

  @override
  String get creditOptionalHint => 'Limit and days can stay empty.';

  @override
  String get walletSave => 'Save wallet';

  @override
  String get creditSave => 'Save card';

  @override
  String get walletSaveChanges => 'Save changes';

  @override
  String get walletLockedLabel => 'Type · Currency';

  @override
  String walletLockedSemantics(String type, String currency) {
    return '$type, $currency, locked because the wallet has transactions';
  }

  @override
  String walletHiddenToast(String name) {
    return '$name hidden';
  }

  @override
  String get walletNameMissing => 'Give it a name.';

  @override
  String get walletAmountInvalid => 'That amount doesn\'t look right.';

  @override
  String get dayDueTitle => 'Which day is it due?';

  @override
  String get dayCloseTitle => 'Which day does it close?';

  @override
  String get dayMonthly => 'Every month';

  @override
  String dayConfirm(int day) {
    return 'Pick day $day';
  }

  @override
  String get dayClear => 'Leave empty';

  @override
  String get dayCloseMark => 'Statement day';

  @override
  String get dayDueMark => 'Due day';

  @override
  String dayMarkedSemantics(int day, String mark) {
    return '$day, $mark';
  }

  @override
  String get categoryTabExpense => 'Expense';

  @override
  String get categoryTabIncome => 'Income';

  @override
  String get categoryTabs => 'Category type';

  @override
  String categoryChildCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subcategories',
      one: '1 subcategory',
    );
    return '$_temp0';
  }

  @override
  String categoryToggleSemantics(String name) {
    return '$name: show or hide subcategories';
  }

  @override
  String get categoryHiddenTitle => 'Hidden categories';

  @override
  String get categoryHiddenHint => 'Past transactions keep these categories.';

  @override
  String get categoryRestoreShort => 'Restore';

  @override
  String categoryRestoreNamed(String name) {
    return 'Restore $name';
  }

  @override
  String categoryRestored(String name) {
    return '$name is back';
  }

  @override
  String get categoryEmptyTitle => 'No categories yet';

  @override
  String get categoryEmptyBody => 'Add one to get started.';

  @override
  String get categoryLoadError => 'Couldn\'t load categories';
}
