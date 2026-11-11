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
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authInvalidInput => 'Check your email and password.';

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
  String authWrongPin(int count) {
    return 'Incorrect PIN. After $count failed attempts, sign in again.';
  }

  @override
  String get authExpired =>
      'Session expired, was revoked, or PIN attempts exceeded. Please sign in again.';

  @override
  String get authBiometricReason => 'Authenticate to unlock Freeva';

  @override
  String get authUseBiometric => 'Use biometrics';

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
  String get authContinue => 'Continue';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authVerifyTitle => 'Confirm your email';

  @override
  String get authRecoverTitle => 'Forgot your password?';

  @override
  String get authRecoverSubtitle =>
      'Enter your email and Freeva sends a reset link.';

  @override
  String get authNewPasswordTitle => 'Set a new password';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authPasswordChanged =>
      'Password changed. Sign in with the new one.';

  @override
  String get authPasswordMismatch =>
      'The passwords don’t match. Please try again.';

  @override
  String get authInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authBack => 'Go back';

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
  String transactionTagLimit(int count) {
    return 'Up to $count tags';
  }

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
  String get categoryTitle => 'Categories';

  @override
  String get categoryAdd => 'Add category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryColor => 'Color';

  @override
  String get categoryIcon => 'Icon';

  @override
  String get categoryHiddenEmpty => 'No hidden categories.';

  @override
  String get categoryInvalid => 'Check the name and main category.';

  @override
  String get categoryConflict =>
      'This category changed elsewhere. Open it again to edit.';

  @override
  String get categoryError => 'Couldn\'t save the category. Try again.';

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
  String get monthReviewTitle => 'Month review';

  @override
  String get monthReviewOpen => 'Open month review';

  @override
  String get monthReviewSavings => 'Savings';

  @override
  String get monthReviewSavingsRate => 'Savings rate';

  @override
  String get monthReviewTopCategories => 'Top categories';

  @override
  String get monthReviewNoCategories => 'No expense categories this month.';

  @override
  String get reportWeek => 'Week';

  @override
  String get reportMonth => 'Month';

  @override
  String get reportRange => 'Custom';

  @override
  String get reportPrevious => 'Previous period';

  @override
  String get reportNext => 'Next period';

  @override
  String get reportApply => 'Show this range';

  @override
  String get reportError => 'Could not load the report. Please try again.';

  @override
  String get reportInvalid => 'That date range isn\'t valid.';

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
  String get faqTitle => 'FAQ';

  @override
  String get legalDraft =>
      'Draft for PRD-P0-002. This is not legal advice and is not in effect. The operating entity and contact channel are not decided yet.';

  @override
  String get tosTitle => 'Terms of service';

  @override
  String get tosBody =>
      'Freeva lets you record wallets and transactions you enter. You keep your financial data. The service operator is not decided yet. You can export your data and delete your account from Profile. This summary does not replace a lawyer-reviewed agreement.';

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
  String homeReviewTopIncrease(String category) {
    return '$category rose the most';
  }

  @override
  String homeReviewOverBudget(int percent) {
    return 'Over budget by $percent%';
  }

  @override
  String get homeCreditTitle => 'Credit cards';

  @override
  String homeCreditDue(String date) {
    return 'Due $date';
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
  String txDayWithTime(String day, String time) {
    return '$day, $time';
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
  String get txDateTimeTitle => 'Choose date and time';

  @override
  String get txTimeLabel => 'Time';

  @override
  String get txTimeNone => 'No time';

  @override
  String get txTimeClear => 'Clear time';

  @override
  String get txDateTimeDone => 'Done';

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
  String get creditMinimumField => 'Minimum payment';

  @override
  String get creditMinimumTitle => 'Minimum payment';

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
  String get creditOptionalHint =>
      'Limit, minimum payment, and days can stay empty.';

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

  @override
  String get categoryIconFood => 'Food';

  @override
  String get categoryIconCoffee => 'Coffee';

  @override
  String get categoryIconGroceries => 'Groceries';

  @override
  String get categoryIconShopping => 'Shopping';

  @override
  String get categoryIconClothes => 'Clothes';

  @override
  String get categoryIconGifts => 'Gifts';

  @override
  String get categoryIconTransport => 'Car, motorbike';

  @override
  String get categoryIconBus => 'Bus';

  @override
  String get categoryIconFuel => 'Fuel';

  @override
  String get categoryIconTravel => 'Travel';

  @override
  String get categoryIconHousing => 'Home';

  @override
  String get categoryIconRepair => 'Repairs';

  @override
  String get categoryIconElectricity => 'Electricity';

  @override
  String get categoryIconWater => 'Water';

  @override
  String get categoryIconInternet => 'Internet';

  @override
  String get categoryIconPhone => 'Phone';

  @override
  String get categoryIconHealth => 'Health';

  @override
  String get categoryIconMedicine => 'Medicine';

  @override
  String get categoryIconSports => 'Sports';

  @override
  String get categoryIconFamily => 'Family';

  @override
  String get categoryIconPets => 'Pets';

  @override
  String get categoryIconBeauty => 'Beauty';

  @override
  String get categoryIconEducation => 'Learning';

  @override
  String get categoryIconBooks => 'Books';

  @override
  String get categoryIconMusic => 'Music';

  @override
  String get categoryIconEntertainment => 'Movies';

  @override
  String get categoryIconGames => 'Games';

  @override
  String get categoryIconSalary => 'Salary';

  @override
  String get categoryIconBonus => 'Bonus';

  @override
  String get categoryIconInvestment => 'Investing';

  @override
  String get categoryIconWork => 'Work';

  @override
  String get categoryIconOtherIncome => 'Savings';

  @override
  String get categoryIconBills => 'Taxes, fees';

  @override
  String get categoryIconInsurance => 'Insurance';

  @override
  String get categoryIconSubscription => 'Subscriptions';

  @override
  String get categoryIconOtherExpense => 'Other';

  @override
  String get categoryColorNone => 'No colour';

  @override
  String get categoryColorBrandPrimary => 'Blue';

  @override
  String get categoryColorBlueDeep => 'Deep blue';

  @override
  String get categoryColorBrandSecondary => 'Sky';

  @override
  String get categoryColorOceanDeep => 'Deep ocean';

  @override
  String get categoryColorBrandAccent => 'Violet';

  @override
  String get categoryColorVioletDeep => 'Deep violet';

  @override
  String get categoryColorSuccess => 'Green';

  @override
  String get categoryColorWarning => 'Yellow';

  @override
  String get categoryColorBlueLight => 'Light blue';

  @override
  String get categoryColorBrandHighlight => 'Light sky';

  @override
  String get categoryColorVioletLight => 'Light violet';

  @override
  String get categoryColorGreenLight => 'Light green';

  @override
  String get categoryColorYellowLight => 'Light yellow';

  @override
  String get categoryColorPink => 'Pink';

  @override
  String get categoryColorOrange => 'Orange';

  @override
  String get categoryColorBrown => 'Brown';

  @override
  String get categoryColorLime => 'Lime';

  @override
  String get categoryColorOlive => 'Olive';

  @override
  String get categoryColorPlum => 'Plum';

  @override
  String get categoryColorGray => 'Grey';

  @override
  String get categoryIconGroupFood => 'Food · shopping';

  @override
  String get categoryIconGroupHome => 'Getting around · home';

  @override
  String get categoryIconGroupLife => 'Health · family · fun';

  @override
  String get categoryIconGroupMoney => 'Income · money';

  @override
  String get categoryLevelMain => 'Main category';

  @override
  String get categoryLevelChild => 'Subcategory';

  @override
  String get categoryParentField => 'Under';

  @override
  String get categoryPickParent => 'Pick a main category';

  @override
  String get categoryParentSheet => 'Main category';

  @override
  String get categoryParentMissing => 'Pick a main category.';

  @override
  String get categoryNameMissing => 'Give it a name.';

  @override
  String get categoryMoreIcons => 'More icons';

  @override
  String get categoryIconSearch => 'Search: fuel, pets…';

  @override
  String get categoryIconSearchLabel => 'Search icons';

  @override
  String get categoryIconDone => 'Done';

  @override
  String get categoryIconNoMatch => 'No icons match.';

  @override
  String get categorySave => 'Save category';

  @override
  String get categorySaveChanges => 'Save changes';

  @override
  String get categoryHideShort => 'Hide';

  @override
  String get categoryDeleteShort => 'Delete';

  @override
  String categoryChildrenBlock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subcategories left',
      one: '1 subcategory left',
    );
    return '$_temp0';
  }

  @override
  String categoryHiddenToast(String name) {
    return '$name hidden';
  }

  @override
  String categoryDeletedToast(String name) {
    return '$name deleted';
  }

  @override
  String categoryDeleteQuestion(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get categoryDeleteNoUndo => 'This can\'t be undone.';

  @override
  String categoryDeleteMove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions move',
      one: '1 transaction moves',
    );
    return 'This can\'t be undone. $_temp0 to:';
  }

  @override
  String get categoryMoveTo => 'Move transactions to';

  @override
  String get reportYear => 'Year';

  @override
  String reportYearTitle(String year) {
    return 'Year $year';
  }

  @override
  String get reportMonthTitlePattern => 'MMMM, yyyy';

  @override
  String get reportShortDatePattern => 'MM/dd';

  @override
  String reportRangeDays(int count) {
    return '$count days';
  }

  @override
  String get reportAverageDay => 'Average spend/day';

  @override
  String get reportRemaining => 'Left';

  @override
  String reportVsMonth(String month) {
    return 'vs M$month';
  }

  @override
  String get reportVsWeek => 'vs last week';

  @override
  String reportVsYear(String year) {
    return 'vs $year';
  }

  @override
  String get reportVsPeriod => 'vs previous period';

  @override
  String reportChange(String percent, String versus) {
    return '$percent% $versus';
  }

  @override
  String get reportBudgetSet => 'Set a monthly budget';

  @override
  String get reportBudgetSoon => 'Budgets are coming soon';

  @override
  String get reportTrendTitle => 'Spending trend';

  @override
  String reportTrendAverageWeeks(int count) {
    return 'Average of $count weeks';
  }

  @override
  String reportTrendAverageMonths(int count) {
    return 'Average of $count months';
  }

  @override
  String reportTrendAverageYears(int count) {
    return 'Average of $count years';
  }

  @override
  String get reportViewExpense => 'Spent';

  @override
  String get reportViewIncome => 'Income';

  @override
  String get reportViewWallet => 'Wallets';

  @override
  String get reportOther => 'Other';

  @override
  String reportOtherCount(int count) {
    return 'Other · $count categories';
  }

  @override
  String reportFlowIn(String amount) {
    return 'In +$amount';
  }

  @override
  String reportFlowOut(String amount) {
    return 'Out −$amount';
  }

  @override
  String reportFlowTransfer(String amount) {
    return 'Transfers $amount';
  }

  @override
  String reportEmptyTitle(String period) {
    return 'No data for $period';
  }

  @override
  String get reportEmptyHint => 'Record a transaction to see your numbers.';

  @override
  String get reportBackWeek => 'Back to this week';

  @override
  String get reportBackMonth => 'Back to this month';

  @override
  String get reportBackYear => 'Back to this year';

  @override
  String get reportUnitThousand => 'k';

  @override
  String get reportUnitMillion => 'M';

  @override
  String get reportUnitBillion => 'B';

  @override
  String reportDonutSemantics(
    String label,
    String amount,
    String currency,
    String items,
  ) {
    return '$label $amount $currency: $items';
  }

  @override
  String reportTrendSemantics(int count, String items) {
    return 'Spending, last $count: $items';
  }

  @override
  String reportMonthShort(String month) {
    return 'M$month';
  }

  @override
  String get reportRangeTitle => 'Choose a date range';

  @override
  String get reportQuick7 => 'Last 7 days';

  @override
  String get reportQuick30 => 'Last 30 days';

  @override
  String get reportQuickQuarter => 'This quarter';

  @override
  String get reportWeekdays => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get reportRangePickStart => 'Pick the first day';

  @override
  String get reportRangePickEnd => 'Now pick the last day';

  @override
  String reportDayFrom(String date) {
    return 'From $date';
  }

  @override
  String reportDayTo(String date) {
    return 'To $date';
  }

  @override
  String reportDayToday(String date) {
    return 'Today, $date';
  }

  @override
  String reportShareExpense(String percent) {
    return '$percent% of spending';
  }

  @override
  String reportShareIncome(String percent) {
    return '$percent% of income';
  }

  @override
  String reportShareCount(String share, int count) {
    return '$share · $count transactions';
  }

  @override
  String get reportLargest => 'Largest transactions';

  @override
  String reportSeeAll(int count) {
    return 'See all $count';
  }

  @override
  String get reportLargestError => 'Couldn\'t load transactions';

  @override
  String get meTitle => 'You';

  @override
  String get meGroupApp => 'App';

  @override
  String get meGroupHelp => 'Help';

  @override
  String get meWallets => 'My wallets';

  @override
  String get meCategories => 'Categories';

  @override
  String get meTags => 'Tags';

  @override
  String get meRecurring => 'Recurring';

  @override
  String get meCalendar => 'Money calendar';

  @override
  String get meCurrency => 'Default currency';

  @override
  String get calendarTitle => 'Money calendar';

  @override
  String get calendarLoadError => 'Couldn’t load calendar';

  @override
  String get calendarEmptyTitle => 'Nothing this month';

  @override
  String get calendarEmptyBody =>
      'No posted transactions, recurring runs, or bills in this month.';

  @override
  String get calendarPrevMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarSectionTransactions => 'Transactions';

  @override
  String get calendarSectionRecurring => 'Recurring';

  @override
  String get calendarSectionBills => 'Bills';

  @override
  String get calendarLegend => 'Dots mark item types on each day';

  @override
  String get calendarTransfer => 'Transfer';

  @override
  String get calendarEstimated => 'Estimated';

  @override
  String get billsStatusOpen => 'Open';

  @override
  String get billsStatusOverdue => 'Overdue';

  @override
  String get billsStatusPaid => 'Paid';

  @override
  String get recurringTitle => 'Recurring and bills';

  @override
  String get recurringAdd => 'Add recurring';

  @override
  String get recurringSave => 'Save';

  @override
  String get recurringEmptyTitle => 'Nothing recurring yet';

  @override
  String get recurringEmptyBody =>
      'Add rent, salary, or a bill like electricity so Freeva posts or reminds you on time.';

  @override
  String get recurringLoadError => 'Couldn’t load recurring';

  @override
  String get recurringAmount => 'Amount';

  @override
  String get recurringWallet => 'Wallet';

  @override
  String get recurringCounterWallet => 'To wallet';

  @override
  String get recurringCategory => 'Category';

  @override
  String get recurringTypeExpense => 'Expense';

  @override
  String get recurringTypeIncome => 'Income';

  @override
  String get recurringTypeTransfer => 'Transfer';

  @override
  String get meBudget => 'Monthly budget';

  @override
  String get budgetTitle => 'Monthly budget';

  @override
  String get budgetSave => 'Save';

  @override
  String get budgetSaved => 'Budget saved';

  @override
  String get budgetCleared => 'Budget removed';

  @override
  String get budgetLoadError => 'Couldn’t load the budget';

  @override
  String get budgetOverallLimit => 'Monthly limit';

  @override
  String get budgetCategoryLimit => 'Category limit';

  @override
  String get budgetTapToSet => 'Tap to set';

  @override
  String get budgetCategoriesTitle => 'By category';

  @override
  String get budgetCategoriesHint =>
      'Optional: set a limit for each expense category.';

  @override
  String get budgetAddCategory => 'Add category';

  @override
  String get budgetNoCategories => 'No expense categories left to add';

  @override
  String get budgetUnknownCategory => 'Category';

  @override
  String get budgetClearTitle => 'Remove budget?';

  @override
  String get budgetClearBody =>
      'The spent bar on Home will hide until you set a budget again.';

  @override
  String get budgetClearAction => 'Remove budget';

  @override
  String get budgetSpentLabel => 'Spent';

  @override
  String get budgetRemainingLabel => 'Left';

  @override
  String budgetUsedPercent(String percent) {
    return '$percent% used';
  }

  @override
  String budgetLimitLine(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get budgetThresholdsTitle => 'Alert thresholds';

  @override
  String get budgetThresholdsSheetTitle => 'Alert me when used';

  @override
  String budgetThresholdsSheetSub(int count) {
    return 'Pick up to $count levels.';
  }

  @override
  String budgetThresholdsDefaultHint(String levels) {
    return 'Default is $levels.';
  }

  @override
  String get budgetScopeDefault => 'Every month';

  @override
  String get budgetScopeMonth => 'This month';

  @override
  String get budgetScopeMonthHint =>
      'Using the default limit. Saving creates an override for this month only.';

  @override
  String get budgetScopeMonthOverrideHint =>
      'This month has its own limit, not the default.';

  @override
  String get budgetClearMonthTitle => 'Remove this month’s override?';

  @override
  String get budgetClearMonthBody =>
      'This month will use the default limit again (if one is set).';

  @override
  String get budgetClearMonthAction => 'Remove month override';

  @override
  String get budgetMonthCleared => 'Month override removed';

  @override
  String get budgetStatusHealthy => 'On track';

  @override
  String get budgetStatusWarning => 'A bit fast';

  @override
  String get budgetStatusCritical => 'Almost out';

  @override
  String get budgetStatusOver => 'Over budget';

  @override
  String budgetHomeLine(String spent, String limit) {
    return 'Spent $spent / $limit';
  }

  @override
  String get meFiscal => 'Month starts on';

  @override
  String meFiscalDay(int day) {
    return 'Day $day';
  }

  @override
  String get meGoals => 'Goals';

  @override
  String get meTheme => 'Appearance';

  @override
  String get meThemeLight => 'Light';

  @override
  String get meThemeDark => 'Dark';

  @override
  String get meThemeSystem => 'Match device';

  @override
  String get meLanguage => 'Language';

  @override
  String get meTimezone => 'Time zone';

  @override
  String get meNotifications => 'Notifications';

  @override
  String get meHideBalances => 'Hide balances';

  @override
  String get meSecurity => 'Security';

  @override
  String get meSecurityValueBiometric => 'PIN · biometrics';

  @override
  String get meSecurityValuePin => 'PIN';

  @override
  String get meFaq => 'FAQ';

  @override
  String get meFeedback => 'Send feedback';

  @override
  String get meSoon => 'Coming soon';

  @override
  String get meLogout => 'Log out';

  @override
  String get meLogoutTitle => 'Log out of this device?';

  @override
  String get meLogoutBody => 'Your data stays in your account.';

  @override
  String get meProfileTitle => 'Profile';

  @override
  String get meProfileName => 'Display name';

  @override
  String get meProfileEmail => 'Email';

  @override
  String get meChange => 'Change';

  @override
  String get meSave => 'Save changes';

  @override
  String get meSaved => 'Saved';

  @override
  String get meSaveError => 'Couldn\'t save. Try again.';

  @override
  String get meConflict =>
      'This changed on another device. Reload and try again.';

  @override
  String meAvatarSemantics(String letter) {
    return 'Profile picture, initial $letter';
  }

  @override
  String get meSecUnlock => 'Unlock';

  @override
  String get meSecPin => 'PIN lock';

  @override
  String get meSecPinSub => 'When you reopen Freeva';

  @override
  String get meSecBiometric => 'Unlock with biometrics';

  @override
  String get meSecChangePin => 'Change PIN';

  @override
  String get meSecLogin => 'Sign-in';

  @override
  String get meSecSessions => 'Signed-in devices';

  @override
  String get meSecChangePassword => 'Change password';

  @override
  String get meSessionsHint => 'Don\'t recognise one? Revoke it now.';

  @override
  String get meSessionThis => 'This device';

  @override
  String get meSessionOther => 'Another device';

  @override
  String get meSessionInUse => 'In use';

  @override
  String meSessionDates(String from, String to) {
    return 'From $from · expires $to';
  }

  @override
  String get meRevoke => 'Revoke';

  @override
  String meRevokeSemantics(String date) {
    return 'Revoke the session from $date';
  }

  @override
  String get meRevokeTitle => 'Revoke this session?';

  @override
  String get meRevokeBody => 'That device will be signed out.';

  @override
  String get meRevokeOthers => 'Sign out all other devices';

  @override
  String get meRevokeOthersTitle => 'Sign out all other devices?';

  @override
  String get meRevokeOthersBody => 'This device stays signed in.';

  @override
  String get meChangePinTitle => 'Change PIN';

  @override
  String get mePinCurrent => 'Current PIN';

  @override
  String get mePinNew => 'New PIN';

  @override
  String get mePinRepeat => 'Repeat new PIN';

  @override
  String mePinWrong(int count) {
    return 'Wrong PIN. After $count misses you sign in again.';
  }

  @override
  String get mePinMismatch => 'The new PINs don\'t match.';

  @override
  String get mePinSame => 'Pick a different PIN.';

  @override
  String get mePinInvalid => 'A PIN is 6 digits.';

  @override
  String get mePinChanged => 'PIN changed';

  @override
  String get meChangePasswordTitle => 'Change password';

  @override
  String get mePasswordCurrent => 'Current password';

  @override
  String get mePasswordNew => 'New password';

  @override
  String get mePasswordRepeat => 'Repeat new password';

  @override
  String mePasswordHint(int count) {
    return 'At least $count characters, with letters and digits.';
  }

  @override
  String get mePasswordWrong => 'That isn\'t your current password.';

  @override
  String mePasswordWeak(int count) {
    return 'Use at least $count characters with letters and digits, different from the old one.';
  }

  @override
  String get mePasswordMismatch => 'The new passwords don\'t match.';

  @override
  String get mePasswordChanged =>
      'Password changed. Other devices were signed out.';

  @override
  String meBusyRetry(int minutes) {
    return 'Try again in $minutes min.';
  }

  @override
  String get meNetworkError => 'Can\'t reach Freeva. Check your connection.';

  @override
  String get meSecAlways => 'Always on';

  @override
  String get tagsSearch => 'Search tags';

  @override
  String get tagsAdd => 'Create tag';

  @override
  String get tagsName => 'Tag name';

  @override
  String get tagsRenameTitle => 'Rename tag';

  @override
  String get tagsRename => 'Rename';

  @override
  String get tagsDelete => 'Delete';

  @override
  String tagsDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get tagsDeleteBody => 'Transactions stay; only this tag comes off.';

  @override
  String get tagsEmptyTitle => 'No tags yet';

  @override
  String get tagsEmptyBody => 'Tag transactions to group them your way.';

  @override
  String get tagsNoMatch => 'No tag matches';

  @override
  String get tagsLoadError => 'Couldn\'t load tags';

  @override
  String tagsRowSemantics(String name, int count) {
    return '$name, $count transactions';
  }

  @override
  String tagsMore(String name) {
    return 'Actions for $name';
  }

  @override
  String get fbHeading => 'What would you like to tell Freeva?';

  @override
  String get fbKindBug => 'Bug';

  @override
  String get fbKindIdea => 'Idea';

  @override
  String get fbKindPraise => 'Praise';

  @override
  String get fbAbout => 'Which part?';

  @override
  String get fbTopicRecord => 'Recording';

  @override
  String get fbTopicReports => 'Reports';

  @override
  String get fbTopicWallets => 'Wallets';

  @override
  String get fbTopicCategories => 'Categories';

  @override
  String get fbTopicAppearance => 'Appearance';

  @override
  String get fbTopicOther => 'Other';

  @override
  String get fbLabelBug => 'What went wrong?';

  @override
  String get fbLabelIdea => 'Your idea';

  @override
  String get fbLabelPraise => 'What do you like?';

  @override
  String fbCount(int count) {
    return '$count/2000';
  }

  @override
  String get fbReply => 'Reply to me by email';

  @override
  String get fbSend => 'Send feedback';

  @override
  String get fbSending => 'Sending…';

  @override
  String get fbThanks => 'Thank you!';

  @override
  String get fbThanksReply => 'Freeva will read it and reply by email.';

  @override
  String get fbThanksNoReply => 'Freeva will read every message.';

  @override
  String get fbDone => 'Done';

  @override
  String get fbError => 'Couldn\'t send. Try again.';

  @override
  String get faqSearch => 'Search questions';

  @override
  String get faqNoMatch => 'No question matches';

  @override
  String get faqMissing => 'Not finding your answer?';

  @override
  String get faqSend => 'Send feedback to Freeva';

  @override
  String get notifyReminders => 'Reminders';

  @override
  String get notifyAlerts => 'Alerts';

  @override
  String get notifyRecord => 'Log reminder';

  @override
  String get notifyRecordSub => 'Every day';

  @override
  String notifyRecordAt(String time) {
    return 'Every day at $time';
  }

  @override
  String get notifyTimeTitle => 'Pick a reminder time';

  @override
  String get notifyTimeHint => 'No reminder on days you already logged.';

  @override
  String notifyTimePick(String time) {
    return 'Pick $time';
  }

  @override
  String get notifyTimeHour => 'Hour';

  @override
  String get notifyTimeMinute => 'Minute';

  @override
  String get notifyInboxDailyLogTitle => 'Log today';

  @override
  String get notifyInboxDailyLogBody =>
      'You haven\'t logged anything today. Add it before you forget.';

  @override
  String get notifyDigest => 'Spending summary';

  @override
  String get notifyDigestSub => 'Every week or month';

  @override
  String get notifyBudget => 'Budget running out';

  @override
  String get notifyBudgetSub => 'At the levels you picked';

  @override
  String notifyBudgetAt(String levels) {
    return 'Alert at $levels';
  }

  @override
  String get notifyBudgetLevels => 'the levels you picked';

  @override
  String get notifyCard => 'Credit cards';

  @override
  String get notifyCardSub => 'Due soon, near the limit';

  @override
  String get notifySession => 'New device signed in';

  @override
  String get notifyRecurring => 'Recurring and bills';

  @override
  String get notifyRecurringSub => 'Before the due date and when overdue';

  @override
  String get notifyGoal => 'Goal contributions';

  @override
  String get notifyGoalSub => 'When a contribution is due';

  @override
  String get notifyDebt => 'Debt due';

  @override
  String get notifyDebtSub => '3 days before the due date';

  @override
  String get notifyMonthReview => 'Month review';

  @override
  String get notifyMonthReviewSub => 'At the start of each month';

  @override
  String get notifyInsight => 'New insight';

  @override
  String get notifyInsightSub => 'When a new tip is ready';

  @override
  String get notifyQuietTitle => 'Quiet hours';

  @override
  String get notifyQuietHours => 'Enable quiet hours';

  @override
  String get notifyQuietEdit => 'Quiet window';

  @override
  String get notifyQuietStart => 'Quiet hours start';

  @override
  String get notifyQuietEnd => 'Quiet hours end';

  @override
  String notifyQuietWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String get notifyMarkAllRead => 'Mark all read';

  @override
  String notifyInboxBudgetTitle(String threshold) {
    return 'Budget reached $threshold%';
  }

  @override
  String notifyInboxBudgetBody(String threshold) {
    return 'You have used $threshold% of this month’s budget.';
  }

  @override
  String get notifyInboxRecurringTitle => 'Recurring due soon';

  @override
  String notifyInboxRecurringBody(String date) {
    return 'A recurring transaction runs on $date.';
  }

  @override
  String get notifyInboxCardDueTitle => 'Card payment due soon';

  @override
  String notifyInboxCardDueBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A card payment is due in $count days.',
      one: 'A card payment is due in 1 day.',
      zero: 'A card payment is due today.',
    );
    return '$_temp0';
  }

  @override
  String get notifyInboxCardHighDebtTitle => 'High card balance';

  @override
  String notifyInboxCardHighDebtBody(String threshold) {
    return 'You have used $threshold% of this card’s limit.';
  }

  @override
  String get notifyInboxCardNearLimitTitle => 'Card near limit';

  @override
  String notifyInboxCardNearLimitBody(String threshold) {
    return 'You have used $threshold% of this card’s limit.';
  }

  @override
  String get authOr => 'or';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authContinueApple => 'Continue with Apple';

  @override
  String get authNoAccount => 'Don’t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authLaterLink => 'Later';

  @override
  String get authDone => 'Done';

  @override
  String authVerifySent(String email) {
    return 'Freeva sent a confirmation link to $email.';
  }

  @override
  String get authVerifyWhyTitle => 'A confirmed email helps you';

  @override
  String get authVerifyWhyReset => 'Get your password back if you forget it';

  @override
  String get authVerifyWhyAlert => 'Get alerts about unusual sign-ins';

  @override
  String get authVerifyWhyNotice => 'Never miss important account notices';

  @override
  String get authResendPrompt => 'Didn’t get it?';

  @override
  String get authResendLink => 'Send again';

  @override
  String get authVerificationSent => 'Confirmation link sent again.';

  @override
  String get authVerifyLater =>
      'You can use the app without confirming. Confirm later in Profile.';

  @override
  String get authSendResetLink => 'Send reset link';

  @override
  String get authResetSentTitle => 'Check your email';

  @override
  String authResetSent(String email) {
    return 'If $email has an account, Freeva sent a reset link.';
  }

  @override
  String get authBackToLogin => 'Back to sign in';

  @override
  String get authConfirmNewPassword => 'Repeat new password';

  @override
  String get authSaveAndLogin => 'Save and sign in';

  @override
  String get authSocialSoon => 'Coming soon';

  @override
  String get passwordWeak => 'Not enough yet';

  @override
  String get passwordGood => 'Good';

  @override
  String get passwordStrong => 'Very strong';

  @override
  String passwordRuleLength(int count) {
    return 'At least $count characters';
  }

  @override
  String get passwordRuleLetterDigit => 'Letters and numbers';

  @override
  String get passwordRuleSymbol => 'Add a symbol like ! @ # to be stronger';

  @override
  String get passwordRuleMatch => 'Both passwords match';

  @override
  String get passwordRuleMet => 'done';

  @override
  String get passwordRuleNotMet => 'not yet';

  @override
  String get consentLabel => 'Agree to the terms';

  @override
  String get consentPrefix => 'I agree to Freeva’s ';

  @override
  String get consentTerms => 'Terms of Use';

  @override
  String get consentAnd => ' and ';

  @override
  String get consentPrivacy => 'Privacy Policy';

  @override
  String get consentSuffix => '.';

  @override
  String get authPinSetupTitle => 'Set a PIN';

  @override
  String get authPinSetupSub => '6 digits to unlock Freeva on this device.';

  @override
  String get authPinConfirmTitle => 'Repeat your PIN';

  @override
  String get authPinConfirmSub => 'Enter the 6 digits again to be sure.';

  @override
  String get authPinConfirmHint => 'If they don’t match you start again.';

  @override
  String get authPinMismatch => 'The PINs didn’t match. Let’s start again.';

  @override
  String get authConfirm => 'Confirm';

  @override
  String get authBiometricTitleFace => 'Set up Face ID';

  @override
  String get authBiometricSubFace =>
      'Unlock Freeva with your face, faster than a PIN.';

  @override
  String get authBiometricTitle => 'Unlock faster';

  @override
  String get authBiometricSub =>
      'Use your fingerprint or face instead of typing the PIN.';

  @override
  String get authBiometricSetup => 'Set up';

  @override
  String get authLockTitle => 'Enter your PIN';

  @override
  String get authLockWelcome => 'Welcome back';

  @override
  String get authForgotPin => 'Forgot your PIN?';

  @override
  String get authForgotPinMessage =>
      'You’ll sign in again with your email and password.';

  @override
  String get authForgotPinConfirm => 'Sign in again';

  @override
  String get authCancel => 'Cancel';

  @override
  String pinDigitsEntered(int count, int total) {
    return '$count of $total digits entered';
  }

  @override
  String get meSecPinSetTitle => 'Set a PIN';

  @override
  String get meSecPinNone => 'Not set';

  @override
  String get authUseFaceId => 'Unlock with Face ID';

  @override
  String get meSecPinSetDone => 'PIN set';

  @override
  String get welcomeTitleLine1 => 'Money, made clear.';

  @override
  String get welcomeTitleLine2 => 'Life, made light.';

  @override
  String get welcomeSub => 'Log spending in seconds, every day.';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get welcomeSampleBalance => 'Total balance';

  @override
  String get welcomeSampleFood => 'Pho lunch';

  @override
  String get welcomeSampleSalary => 'Salary';

  @override
  String get signUpTitle => 'Create your Freeva account';

  @override
  String get signUpSub =>
      'Your data is safe and moves with you to a new phone.';

  @override
  String get authContinueEmail => 'Continue with email';

  @override
  String get signUpTermsPrefix => 'By continuing you agree to the ';

  @override
  String get signUpTermsLink => 'Terms';

  @override
  String get signUpTermsSuffix => '.';

  @override
  String onbProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get onbGoalsTitle => 'What can Freeva help you with?';

  @override
  String onbGoalsSub(int count) {
    return 'Pick up to $count.';
  }

  @override
  String get onbGoalTrack => 'Track spending';

  @override
  String get onbGoalTrackSub => 'Know where the money goes each month';

  @override
  String get onbGoalSave => 'Save';

  @override
  String get onbGoalSaveSub => 'Put money aside for something';

  @override
  String get onbGoalBudget => 'Manage a budget';

  @override
  String get onbGoalBudgetSub => 'Set a spending limit and stick to it';

  @override
  String get onbIncomeTitle => 'About how much do you earn a month?';

  @override
  String get onbIncomeSub => 'So the suggested budget fits.';

  @override
  String get onbIncomeHint =>
      'A rough number is fine. You can change it in Me.';

  @override
  String get onbIncomeAmount => 'Monthly income';

  @override
  String onbIncomeChip(String amount) {
    return '$amount million';
  }

  @override
  String get onbSavingTitle => 'What are you saving for?';

  @override
  String get onbSavingTarget => 'Amount';

  @override
  String get onbSavingDate => 'By';

  @override
  String get onbSavingNeed => 'Save each month';

  @override
  String onbSavingShare(String percent) {
    return '$percent% of income';
  }

  @override
  String get onbSuggestTitle => 'Each month, spend about';

  @override
  String get onbSuggestIncome => 'Income';

  @override
  String onbSuggestSaveFor(String goal) {
    return 'Saving for $goal';
  }

  @override
  String onbSuggestSaveDefault(int percent) {
    return 'Save $percent% of income';
  }

  @override
  String get onbSuggestSpend => 'Spending';

  @override
  String onbSuggestNoGoal(int percent) {
    return 'No goal yet, so $percent% goes to savings for now.';
  }

  @override
  String get onbSuggestHint => 'You can change it any time in Monthly budget.';

  @override
  String get onbSuggestUse => 'Use this amount';

  @override
  String get dailyLogAskTitle => 'Remind you to log spending each evening?';

  @override
  String get dailyLogAskBody => 'No reminder on days you already logged.';

  @override
  String get dailyLogAskTime => 'Reminder time';

  @override
  String get dailyLogAskOn => 'Turn on';

  @override
  String get meIncome => 'Monthly income';

  @override
  String get meIncomeNone => 'Not set';

  @override
  String get meIncomeClear => 'Remove income';

  @override
  String get meIncomeSave => 'Save';

  @override
  String get meIncomeFailed => 'Could not save. Try again later.';

  @override
  String get setupWalletsTitle => 'Where is your money?';

  @override
  String get setupWalletsSub =>
      'Add wallets and balances. A rough number is enough.';

  @override
  String get setupAdd => 'Add';

  @override
  String get setupSkip => 'Skip';

  @override
  String get checklistTitle => 'Let’s get started';

  @override
  String get checklistWallet => 'Create a wallet';

  @override
  String get checklistExpense => 'Record your first expense';

  @override
  String get checklistRecordNow => 'Record now';

  @override
  String get checklistPin => 'Lock the app with a PIN';

  @override
  String authLockGreeting(String name) {
    return 'Hi $name';
  }

  @override
  String get syncTitle => 'Sync';

  @override
  String syncBannerBoth(int attention, int waiting) {
    return '$attention changes need you · $waiting more waiting to send';
  }

  @override
  String syncBannerAttention(int count) {
    return '$count changes need you';
  }

  @override
  String syncBannerWaiting(int count) {
    return '$count changes waiting to send';
  }

  @override
  String get syncOffline => 'No connection';

  @override
  String get syncUnavailable => 'Couldn’t send yet';

  @override
  String get syncUnavailableSub => 'Try again later';

  @override
  String get syncWaitingCard => 'Changes are waiting to send';

  @override
  String syncLastTime(String when) {
    return 'Last $when';
  }

  @override
  String get syncLastNever => 'Not synced yet';

  @override
  String syncToday(String time) {
    return 'today $time';
  }

  @override
  String syncOnDay(String date, String time) {
    return '$date $time';
  }

  @override
  String get syncRetry => 'Try again';

  @override
  String syncSending(int count) {
    return 'Sending $count changes';
  }

  @override
  String get syncSendingSub => 'You can keep using the app';

  @override
  String get syncAllDone => 'Everything is synced';

  @override
  String syncSectionAttention(int count) {
    return 'NEEDS YOU · $count';
  }

  @override
  String syncSectionWaiting(int count) {
    return 'WAITING TO SEND · $count';
  }

  @override
  String syncSectionHolding(int count) {
    return 'KEPT ON THIS DEVICE · $count';
  }

  @override
  String get syncActionAdd => 'Add';

  @override
  String get syncActionEdit => 'Edit';

  @override
  String get syncActionDelete => 'Delete';

  @override
  String get syncActionRestore => 'Restore';

  @override
  String syncItemLine(String action, String detail) {
    return '$action · $detail';
  }

  @override
  String get syncReasonChanged => 'Changed on another device';

  @override
  String get syncReasonWallet => 'The wallet was removed';

  @override
  String get syncReasonMissing => 'The transaction was removed elsewhere';

  @override
  String get syncReasonInvalid => 'The details are no longer valid';

  @override
  String get syncReasonCategoryKind =>
      'The category does not fit the transaction type';

  @override
  String get transactionCategoryKind =>
      'This category is not used for the chosen transaction type. Pick another category.';

  @override
  String get syncReasonOther => 'Couldn’t send · Try again later';

  @override
  String get syncFooter => 'Your data stays on this device until it is sent.';

  @override
  String get syncUpdateTitle => 'Freeva needs an update';

  @override
  String get syncUpdateBody => 'To keep syncing. Your changes are kept.';

  @override
  String get syncDiscardTitle => 'Discard this change?';

  @override
  String syncDiscardMessage(String name, String amount) {
    return '$name $amount won’t be saved.';
  }

  @override
  String syncDiscardMessageShort(String name) {
    return '$name won’t be saved.';
  }

  @override
  String get syncDiscardKeep => 'Keep it';

  @override
  String get syncDiscardConfirm => 'Discard';

  @override
  String syncDiscardSemantics(String name) {
    return 'Discard change $name';
  }

  @override
  String get syncChipReview => 'Needs a look';

  @override
  String get syncChipWaiting => 'Waiting to sync';

  @override
  String get syncViewAction => 'View';

  @override
  String get syncCompareTitle => 'Choose which to keep';

  @override
  String syncCompareIntroA(String name) {
    return '$name was just changed on another device. The differences are ';
  }

  @override
  String get syncCompareIntroB => 'highlighted';

  @override
  String get syncCompareIntroC => '.';

  @override
  String get syncCompareMine => 'This device’s version';

  @override
  String syncCompareMineWhen(String when) {
    return 'You changed it $when';
  }

  @override
  String get syncCompareSaved => 'Saved version';

  @override
  String syncCompareSavedWhen(String when) {
    return 'Changed elsewhere $when';
  }

  @override
  String get syncCompareSavedNoTime => 'Saved on the server';

  @override
  String get syncCompareDeleted => 'Deleted';

  @override
  String get syncFieldAmount => 'Amount';

  @override
  String get syncFieldCategory => 'Category';

  @override
  String get syncFieldNotes => 'Note';

  @override
  String get syncFieldDate => 'Date';

  @override
  String get syncFieldMerchant => 'Store';

  @override
  String get syncKeepSaved => 'Keep the saved version';

  @override
  String get syncKeepMine => 'Keep this device’s version';

  @override
  String get syncDupTitle => 'You may have recorded this already';

  @override
  String get syncDupSub => 'These two look the same.';

  @override
  String get syncDupJust => 'JUST RECORDED';

  @override
  String get syncDupExisting => 'ALREADY THERE';

  @override
  String get syncDupKeepBoth => 'Keep both';

  @override
  String get syncDupDeleteNew => 'Delete the new one';

  @override
  String syncBannerOthersWaiting(Object count) {
    return '$count other changes waiting to send';
  }

  @override
  String syncLastToday(Object time) {
    return 'Last synced $time today';
  }

  @override
  String get syncSectionSending => 'SENDING';

  @override
  String get reportDonutTotalExpense => 'Total spent';

  @override
  String get reportDonutTotalIncome => 'Total income';

  @override
  String get reportBarGeneralSuffix => '(general)';

  @override
  String reportEmptyTitleMonth(Object month) {
    return 'No data for month $month yet';
  }

  @override
  String get meLegal => 'Terms and privacy';

  @override
  String meNotifyOnCount(Object count) {
    return '$count on';
  }

  @override
  String meGoalsCount(Object count) {
    return '$count goals';
  }

  @override
  String get meProfileEmailVerified => 'Email · verified';

  @override
  String get meProfileEmailUnverified => 'Email · not verified';

  @override
  String get meDeleteAccount => 'Delete account';

  @override
  String get meExportData => 'Export data';

  @override
  String get meExportHint => 'Save or send a copy of your data';

  @override
  String get meExportError => 'Couldn\'t export. Try again.';

  @override
  String get meDeleteTitle => 'Delete account?';

  @override
  String get meDeleteBody =>
      'All your data is deleted right away and can\'t be restored. You can export it first.';

  @override
  String get meDeleteConfirm => 'Delete permanently';

  @override
  String get meDeleteError => 'Couldn\'t delete. Your data is untouched.';

  @override
  String get meChangeAvatar => 'Change photo';

  @override
  String get meSecurityValueFaceId => 'PIN · Face ID';

  @override
  String get meSecFaceId => 'Unlock with Face ID';

  @override
  String get notifySessionSubAlways => 'Always on so you can check';

  @override
  String get faqRecordQ => 'How do I record an expense?';

  @override
  String get faqRecordA =>
      'Tap + in the middle of the bottom bar, enter the amount, pick a category and save. Wallet and date reuse your last choice.';

  @override
  String get faqTransferQ => 'Moving money between two wallets?';

  @override
  String get faqTransferA =>
      'Tap +, choose Transfer, pick the from and to wallets and enter the amount. Both balances update together.';

  @override
  String get faqDeletedQ => 'Deleted a transaction by mistake?';

  @override
  String get faqDeletedA =>
      'Tap Undo right after deleting. Later you can still restore it from Deleted in Transactions.';

  @override
  String get faqMonthQ => 'What is a financial month?';

  @override
  String get faqMonthA =>
      'It\'s the period your monthly totals cover. If you\'re paid on the 5th, set Month starts on day 5 in Me so the numbers match.';

  @override
  String get faqLockAppQ => 'Locking the app with PIN or Face ID';

  @override
  String get faqLockAppA =>
      'Go to Me, Security to set a PIN. With a PIN you can turn on Face ID. Without a PIN the app doesn\'t lock.';

  @override
  String get faqSafeQ => 'Is my data safe?';

  @override
  String get faqSafeA =>
      'Your data lives in your Freeva account, so changing phones doesn\'t lose it. Lock the app with a PIN so others can\'t see it.';

  @override
  String get homeOfflineHeading => 'You\'re offline';

  @override
  String homeOfflineDetail(Object time) {
    return 'Figures as of $time. You can still record spending.';
  }

  @override
  String get homeCreditUsedLabel => 'Used';

  @override
  String homeCreditLimit(Object limit) {
    return 'Limit $limit';
  }

  @override
  String homeOtherCurrencyMeta(Object currency, Object count) {
    return '$currency · $count wallets';
  }

  @override
  String get homeTotalBalanceLabel => 'Total balance';

  @override
  String authResetVerified(Object email) {
    return 'Verified $email';
  }

  @override
  String get currencyNameVnd => 'Vietnamese dong';

  @override
  String get currencyNameUsd => 'US dollar';

  @override
  String get currencyNameEur => 'Euro';

  @override
  String get currencyNameJpy => 'Japanese yen';

  @override
  String get currencyNameKrw => 'South Korean won';

  @override
  String get currencyNameCny => 'Chinese yuan';

  @override
  String get currencyNameSgd => 'Singapore dollar';

  @override
  String get currencyNameThb => 'Thai baht';

  @override
  String get currencyNameAud => 'Australian dollar';

  @override
  String get currencyNameGbp => 'British pound';

  @override
  String currencyCodeName(Object code, Object name) {
    return '$code · $name';
  }

  @override
  String get tagsViewTransactions => 'View transactions';

  @override
  String homeTotalConverted(int count, String currency) {
    return 'Total in $currency · $count wallets';
  }

  @override
  String homeDisplayCurrencyAction(String currency) {
    return 'Show totals in $currency';
  }

  @override
  String get homeDisplayCurrencyTitle => 'Show totals in';

  @override
  String homeUnconvertedMissing(String currency) {
    return '$currency: no rate yet, tap to add';
  }

  @override
  String homeUnconvertedFractional(String currency) {
    return '$currency: rate doesn\'t convert evenly, tap to edit';
  }

  @override
  String homeRateInputLabel(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get homeRateSaveFailed =>
      'Couldn\'t save. Check the rate and try again.';

  @override
  String get convertedRowTitle => 'Converted';

  @override
  String convertedAmount(String amount) {
    return '≈ $amount';
  }

  @override
  String convertedRateLine(String from, String rate, String to, String time) {
    return '1 $from = $rate $to · rate you entered at $time';
  }

  @override
  String get goalsAdd => 'Add goal';

  @override
  String get goalsEmptyTitle => 'No goals yet';

  @override
  String get goalsEmptyBody =>
      'Set a goal and Freeva works out how much to save each month.';

  @override
  String get goalsCreate => 'Create goal';

  @override
  String get goalsSaved => 'Saved so far';

  @override
  String get goalsCountLabel => 'Goals';

  @override
  String get goalsNeededMonth => 'Needed this month';

  @override
  String get goalsOverdue => 'Overdue';

  @override
  String get goalsReached => 'Reached';

  @override
  String get goalsArchivedLink => 'Archived goals';

  @override
  String get goalsLoadError => 'Couldn’t load goals';

  @override
  String get goalsNew => 'New goal';

  @override
  String get goalsEdit => 'Edit goal';

  @override
  String get goalsFor => 'Saving for';

  @override
  String get goalKindEmergency => 'Emergency fund';

  @override
  String get goalKindHome => 'Buy a home';

  @override
  String get goalKindCar => 'Buy a car';

  @override
  String get goalKindTravel => 'Travel';

  @override
  String get goalKindEducation => 'Education';

  @override
  String get goalKindWedding => 'Wedding';

  @override
  String get goalKindRetirement => 'Retirement';

  @override
  String get goalKindCustom => 'Other';

  @override
  String get goalName => 'Goal name';

  @override
  String get goalNameMissing => 'Give the goal a name.';

  @override
  String get goalTarget => 'Target';

  @override
  String get goalTargetMissing => 'Enter the target amount.';

  @override
  String get goalCurrent => 'Saved';

  @override
  String get goalDate => 'Target date';

  @override
  String get goalDateNone => 'Not set';

  @override
  String get goalDateClear => 'Clear date';

  @override
  String get goalWallet => 'Kept in';

  @override
  String get goalWalletMissing => 'Pick the wallet that holds the money.';

  @override
  String goalWalletValue(String name, String amount) {
    return '$name · $amount left';
  }

  @override
  String goalNeedLine(String amount) {
    return 'Save $amount a month.';
  }

  @override
  String goalNeedLineShare(String amount, String percent) {
    return 'Save $amount a month, about $percent% of your income.';
  }

  @override
  String get goalHave => 'Saved';

  @override
  String goalOf(String amount) {
    return '/ $amount';
  }

  @override
  String goalProgressLine(String percent, String amount) {
    return '$percent% · $amount to go';
  }

  @override
  String goalProgressDone(String percent) {
    return '$percent% · reached';
  }

  @override
  String get goalNeedPerMonth => 'Needed a month';

  @override
  String get goalLeft => 'Left';

  @override
  String goalMonths(int count) {
    return '$count months';
  }

  @override
  String goalLineActive(int months, String amount) {
    return '$months months left · save $amount a month';
  }

  @override
  String get goalLineNoDate => 'No target date';

  @override
  String goalLineOverdue(String date, String amount) {
    return 'Due $date has passed · $amount to go';
  }

  @override
  String goalLineReached(String date) {
    return 'Reached on $date';
  }

  @override
  String get goalContribute => 'Add money';

  @override
  String get goalWithdraw => 'Withdraw';

  @override
  String get goalHistory => 'History';

  @override
  String get goalHistoryContribute => 'Added';

  @override
  String get goalHistoryContributeTransfer => 'Added from another wallet';

  @override
  String get goalHistoryWithdraw => 'Withdrawn';

  @override
  String get goalHistoryWithdrawTransfer => 'Withdrawn to another wallet';

  @override
  String get goalHistoryAdjust => 'Saved amount corrected';

  @override
  String goalHistoryStays(String date) {
    return '$date · money was already in the wallet';
  }

  @override
  String get goalHistoryEmpty => 'Nothing added yet';

  @override
  String get goalMoveIn => 'Add';

  @override
  String get goalMoveOut => 'Withdraw';

  @override
  String goalMoveTitleIn(String name) {
    return 'Add to $name';
  }

  @override
  String goalMoveTitleOut(String name) {
    return 'Withdraw from $name';
  }

  @override
  String get goalMoveAmount => 'Amount';

  @override
  String get goalMoveFrom => 'Take from';

  @override
  String get goalMoveTo => 'Send to';

  @override
  String goalMoveStaysIn(String wallet) {
    return 'Already in $wallet';
  }

  @override
  String goalMoveStaysOut(String wallet) {
    return 'Leave in $wallet';
  }

  @override
  String get goalMoveOnlyRecord => 'Just record it, no money moves';

  @override
  String goalMoveWalletLeft(String amount) {
    return '$amount left';
  }

  @override
  String get goalMoveHint => 'Recorded as a wallet transfer, not as spending.';

  @override
  String goalMoveConfirmIn(String amount) {
    return 'Add $amount';
  }

  @override
  String goalMoveConfirmOut(String amount) {
    return 'Withdraw $amount';
  }

  @override
  String get goalMoveTooMuch => 'More than the goal holds.';

  @override
  String get goalArchive => 'Archive goal';

  @override
  String get goalArchiveBody =>
      'The goal is put away; the money stays in your wallet.';

  @override
  String get goalSaveFailed => 'Couldn’t save. Try again.';

  @override
  String get goalConflict =>
      'This goal changed elsewhere. Reopen it to see the latest.';

  @override
  String get goalsHomeTitle => 'Goals';

  @override
  String get goalsSeeAll => 'See all';

  @override
  String goalPercent(String percent) {
    return '$percent%';
  }

  @override
  String get goalSaveAction => 'Save';

  @override
  String recDueTotal(String amount) {
    return 'To pay $amount';
  }

  @override
  String recDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills unpaid',
      one: '1 bill unpaid',
    );
    return '$_temp0 · see calendar';
  }

  @override
  String get recGroupDue => 'TO PAY';

  @override
  String get recGroupAuto => 'AUTOMATIC';

  @override
  String get recTagOverdue => 'Overdue';

  @override
  String get recTagToday => 'Today';

  @override
  String recTagDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get recTagPaused => 'Paused';

  @override
  String recDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get recOneOff => 'one-off';

  @override
  String recAbout(String amount) {
    return 'about $amount';
  }

  @override
  String get recPaid => 'Paid';

  @override
  String recPaidA11y(String name) {
    return 'Mark $name as paid';
  }

  @override
  String recDayOfMonth(String day) {
    return 'Day $day every month';
  }

  @override
  String get recEveryDay => 'Every day';

  @override
  String get recEveryWeek => 'Every week';

  @override
  String get recEveryMonth => 'Every month';

  @override
  String get recEveryYear => 'Every year';

  @override
  String recEveryNDays(String count) {
    return 'Every $count days';
  }

  @override
  String recEveryNWeeks(String count) {
    return 'Every $count weeks';
  }

  @override
  String recEveryNMonths(String count) {
    return 'Every $count months';
  }

  @override
  String recEveryNYears(String count) {
    return 'Every $count years';
  }

  @override
  String get recOnce => 'Once';

  @override
  String get recModeAuto => 'Post automatically';

  @override
  String get recModeAutoSub => 'Good for salary, rent';

  @override
  String get recModeRemind => 'Ask before posting';

  @override
  String get recModeRemindSub => 'Good for electricity, water';

  @override
  String get recName => 'Name';

  @override
  String get recVaries => 'Amount can differ each time';

  @override
  String get recVariesSub => 'Enter the real amount when you confirm';

  @override
  String get recRepeat => 'Repeat';

  @override
  String get recFirstDue => 'First due date';

  @override
  String get recNextRun => 'Next date';

  @override
  String get recRemindBefore => 'Remind me';

  @override
  String get recRemindSameDay => 'On the day';

  @override
  String recRemindDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get recPayFrom => 'Pay from';

  @override
  String get recPause => 'Pause';

  @override
  String get recPauseSub =>
      'Nothing is posted or reminded until you turn it back on';

  @override
  String get recRemove => 'Delete recurring';

  @override
  String recPaidTitle(String name) {
    return 'Paid $name?';
  }

  @override
  String get recRealAmount => 'Actual amount';

  @override
  String get recPaidOn => 'Paid on';

  @override
  String get recConfirm => 'Confirm paid';

  @override
  String get recLinkExisting => 'Already logged this expense? Pick it';

  @override
  String get recPickExpense => 'Pick an expense';

  @override
  String get recNoExpense => 'No expense to link yet';

  @override
  String get recConfirmed => 'Marked as paid';

  @override
  String get recNeedWallet => 'Pick a wallet to pay from';

  @override
  String get recRemoveBody => 'Entries already posted stay as they are.';

  @override
  String recRemindDaysShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get recNeedCategory => 'Pick a category';

  @override
  String get transactionAdjustment => 'Adjustment';

  @override
  String get txKindAdjustment => 'adjustment';

  @override
  String get txAdjustTitle => 'Balance adjustment';

  @override
  String get walletReconcileLink => 'Match balance';

  @override
  String walletReconcileTitle(String name) {
    return 'Match $name balance';
  }

  @override
  String get walletReconcileCurrent => 'Balance in app';

  @override
  String get walletReconcileCurrentDebt => 'Debt in app';

  @override
  String get walletReconcileField => 'Real balance in your bank app';

  @override
  String get walletReconcileFieldDebt => 'Real debt in your bank app';

  @override
  String get walletReconcileDiff => 'Difference';

  @override
  String get walletReconcileHint =>
      'The difference is saved as an adjustment, not counted in income or spending.';

  @override
  String get walletReconcileConfirm => 'Match balance';

  @override
  String get walletReconcileDone => 'Balance matched';

  @override
  String get txAdjustEditTitle => 'Edit adjustment';

  @override
  String get txAdjustAmount => 'Adjustment amount';

  @override
  String get txAdjustHint => 'Positive raises the wallet, negative lowers it.';

  @override
  String get walletReconcileFailed => 'Couldn\'t match the balance. Try again.';

  @override
  String get meDebts => 'Loans and debts';

  @override
  String meDebtsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get transactionDebt => 'Lending';

  @override
  String get txKindDebt => 'lending';

  @override
  String get txDebtTitle => 'Loans and debts';

  @override
  String get txDebtReadOnly =>
      'This belongs to Loans and debts and can’t be edited.';

  @override
  String get debtsTabPeople => 'People';

  @override
  String get debtsTabLoans => 'Loans';

  @override
  String get debtsAdd => 'Record a debt';

  @override
  String get debtsEmptyTitle => 'Nobody owes anybody';

  @override
  String get debtsEmptyBody =>
      'Lent to a friend or borrowed from family? Note it so you don’t forget.';

  @override
  String get debtsLoadError => 'Couldn’t load debts';

  @override
  String get debtsOwedToYou => 'Others owe you';

  @override
  String get debtsYouOwe => 'You owe';

  @override
  String get debtsGroupOwedToYou => 'Who owes you';

  @override
  String get debtsGroupYouOwe => 'Whom you owe';

  @override
  String get debtsGroupSettled => 'Settled';

  @override
  String debtsSettledLink(int count) {
    return 'Settled ($count)';
  }

  @override
  String debtLentOn(String date) {
    return 'Lent $date';
  }

  @override
  String debtBorrowedOn(String date) {
    return 'Borrowed $date';
  }

  @override
  String debtDueOn(String date) {
    return 'due $date';
  }

  @override
  String get debtNoDue => 'no due date';

  @override
  String get debtNoDueValue => 'None';

  @override
  String get debtLend => 'Lend';

  @override
  String get debtBorrow => 'Borrow';

  @override
  String get debtHistoryBorrowed => 'Borrowed';

  @override
  String get debtAmount => 'Amount';

  @override
  String get debtBorrower => 'Borrower';

  @override
  String get debtLender => 'Lender';

  @override
  String get debtFromWallet => 'From wallet';

  @override
  String get debtFromWalletShort => 'From wallet';

  @override
  String get debtToWallet => 'To wallet';

  @override
  String debtWalletLeft(String wallet, String amount) {
    return '$wallet · $amount left';
  }

  @override
  String get debtDate => 'Date';

  @override
  String get debtDueDate => 'Due date';

  @override
  String get debtPickDate => 'Pick a date';

  @override
  String get debtClearDue => 'Clear due date';

  @override
  String get debtDueBeforeDate => 'The due date must be after the date.';

  @override
  String get debtNote => 'Note';

  @override
  String get debtNoteHint => 'Add a note';

  @override
  String get debtNotCounted => 'Not counted as income or spending.';

  @override
  String get debtSave => 'Save';

  @override
  String get debtEditTitle => 'Edit debt';

  @override
  String debtTheyOwe(String name) {
    return '$name still owes you';
  }

  @override
  String debtYouOweName(String name) {
    return 'You still owe $name';
  }

  @override
  String debtOfPrincipal(String amount) {
    return '/ $amount';
  }

  @override
  String debtReceived(String amount) {
    return 'Received $amount';
  }

  @override
  String debtPaid(String amount) {
    return 'Paid $amount';
  }

  @override
  String get debtLentDate => 'Lent on';

  @override
  String get debtBorrowedDate => 'Borrowed on';

  @override
  String get debtHistory => 'History';

  @override
  String debtTheyPaid(String name) {
    return '$name paid';
  }

  @override
  String get debtYouPaid => 'You paid';

  @override
  String debtInto(String date, String wallet) {
    return '$date · into $wallet';
  }

  @override
  String debtOutOf(String date, String wallet) {
    return '$date · from $wallet';
  }

  @override
  String get debtRecordReceived => 'Record money back';

  @override
  String get debtRecordPaid => 'Record a payment';

  @override
  String debtPayTheyTitle(String name) {
    return '$name pays you';
  }

  @override
  String debtPayYouTitle(String name) {
    return 'You pay $name';
  }

  @override
  String get debtHalf => 'Half';

  @override
  String debtAll(String amount) {
    return 'All $amount';
  }

  @override
  String get debtSettleHintLent => 'Once it’s all back, this moves to Settled.';

  @override
  String get debtSettleHintBorrowed =>
      'Once it’s all paid, this moves to Settled.';

  @override
  String get debtTooMuch => 'That’s more than what’s owed.';

  @override
  String get loansAdd => 'Add a loan';

  @override
  String get loansLoadError => 'Couldn’t load loans';

  @override
  String get loansEmptyTitle => 'No loans yet';

  @override
  String get loansEmptyBody =>
      'Home, car or personal loan? Add it to follow the repayments.';

  @override
  String get loansOwed => 'Still owed';

  @override
  String get loansPaidPrincipal => 'Principal paid';

  @override
  String get loansDueThisMonth => 'Due this month';

  @override
  String get loanPaidOff => 'Paid off';

  @override
  String loanRateYear(String rate) {
    return '$rate%/yr';
  }

  @override
  String loanNextOn(String date) {
    return 'next $date';
  }

  @override
  String get loanEdit => 'Edit loan';

  @override
  String get loanEditShort => 'Edit';

  @override
  String loanPaidPercent(String percent) {
    return '$percent% of principal paid';
  }

  @override
  String loanDoneBy(String month) {
    return 'done by $month';
  }

  @override
  String get loanNextPeriod => 'Next payment';

  @override
  String loanNextOnTitle(String date) {
    return 'Next · $date';
  }

  @override
  String loanSplit(String principal, String interest) {
    return 'Principal $principal · interest $interest';
  }

  @override
  String loanInterestOnly(String amount) {
    return 'Interest this period $amount';
  }

  @override
  String get loanRecordPayment => 'Record a payment';

  @override
  String get loanHow => 'How it works';

  @override
  String loanHowText(String rate, String frequency) {
    return '$rate% a year on what is still owed, paid $frequency. Interest comes first, the rest lowers the principal.';
  }

  @override
  String get loanSchedule => 'Repayments';

  @override
  String get loanFullSchedule => 'See all';

  @override
  String get loanNextTag => 'Next';

  @override
  String loanPeriod(int index) {
    return 'Payment $index';
  }

  @override
  String get loanKindMortgage => 'Home loan';

  @override
  String get loanKindPersonal => 'Personal loan';

  @override
  String get loanKindOther => 'Other';

  @override
  String get loanFreqWeekly => 'Weekly';

  @override
  String get loanFreqMonthly => 'Monthly';

  @override
  String get loanFreqQuarterly => 'Quarterly';

  @override
  String get loanFreqYearly => 'Yearly';

  @override
  String get loanName => 'Name';

  @override
  String get loanAmountGroup => 'Amounts';

  @override
  String get loanPrincipal => 'Amount borrowed';

  @override
  String get loanRate => 'Interest rate';

  @override
  String get loanRateUnit => '%/yr';

  @override
  String get loanInstallment => 'Each payment';

  @override
  String get loanFrequency => 'Paid';

  @override
  String get loanNextDue => 'Next payment';

  @override
  String get loanStart => 'Start';

  @override
  String get loanEnd => 'End';

  @override
  String get loanPayFrom => 'Pay from';

  @override
  String get loanInstallmentHint =>
      'Leave \"Each payment\" empty and Freeva works it out from the end date.';

  @override
  String get loanSave => 'Save loan';

  @override
  String get loanOwedTooMuch =>
      'What’s owed can’t be more than the amount borrowed.';

  @override
  String loanPayTitle(String date) {
    return 'Payment due $date';
  }

  @override
  String get loanPrincipalPart => 'Principal';

  @override
  String get loanInterestPart => 'Interest';

  @override
  String loanWalletLeft(String amount) {
    return '$amount left';
  }

  @override
  String get loanPrincipalHint => 'Only the principal lowers what is owed.';

  @override
  String get loanTooMuch => 'The principal is more than what is owed.';

  @override
  String get notifyInboxDebtDueTitle => 'A debt is due soon';

  @override
  String get notifyInboxDebtDueLentTitle => 'Money owed to you is due';

  @override
  String get notifyInboxDebtOverdueTitle => 'A debt is overdue';

  @override
  String get notifyInboxDebtOverdueLentTitle => 'Money owed to you is overdue';

  @override
  String notifyInboxDebtDueBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due in $days days.',
      one: 'Due in 1 day.',
      zero: 'Due today.',
    );
    return '$_temp0';
  }

  @override
  String notifyInboxDebtOverdueBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days overdue.',
      one: '1 day overdue.',
    );
    return '$_temp0';
  }

  @override
  String get transactionRefund => 'Refund';

  @override
  String get txKindRefund => 'refund';

  @override
  String get txRefundTitle => 'Refund';

  @override
  String txRefundedNote(String amount) {
    return '$amount refunded';
  }

  @override
  String get txDetailRefunded => 'Refunded';

  @override
  String get txDetailRefundOf => 'Refund for';

  @override
  String get refundAction => 'Record a refund';

  @override
  String get refundActionSub => 'Return or partial refund';

  @override
  String refundTitle(String name) {
    return 'Refund $name';
  }

  @override
  String refundSpent(String amount, String date) {
    return 'Spent $amount · $date';
  }

  @override
  String get refundAmount => 'Refund amount';

  @override
  String refundAll(String amount) {
    return 'Refund all $amount';
  }

  @override
  String get refundToWallet => 'To wallet';

  @override
  String get refundDate => 'Date';

  @override
  String refundHint(String category, int month) {
    return 'Comes off $category spending for month $month, not counted as income.';
  }

  @override
  String get refundTooMuch => 'More than what is left of this expense.';

  @override
  String get refundSave => 'Record refund';

  @override
  String get refundSaved => 'Refund recorded';

  @override
  String get refundDeleteTitle => 'Delete this expense?';

  @override
  String refundDeleteBody(String amount) {
    return 'It has $amount refunded.';
  }

  @override
  String get refundDeleteCascade => 'Delete the refunds too';

  @override
  String refundDeleteCascadeSub(String amount) {
    return 'Wallets go down by $amount';
  }

  @override
  String get refundDeleteKeep => 'Keep the refunds';

  @override
  String get refundDeleteKeepSub => 'They become income';

  @override
  String get installmentAction => 'Turn into installments';

  @override
  String get installmentActionSub => 'Split over card periods';

  @override
  String get installmentTitle => 'Installments';

  @override
  String get installmentCount => 'Periods';

  @override
  String get installmentOther => 'Other';

  @override
  String get installmentOtherTitle => 'Number of periods';

  @override
  String installmentOtherLabel(int min, int max) {
    return 'From $min to $max';
  }

  @override
  String get installmentEach => 'Each period';

  @override
  String get installmentEditEach => 'Amount each period';

  @override
  String get installmentFirst => 'First period';

  @override
  String installmentMore(int count, String date) {
    return '… $count more, done $date';
  }

  @override
  String installmentHint(int month) {
    return 'The purchase still counts once, in month $month. Each period adds to the card\'s amount due.';
  }

  @override
  String get installmentCreate => 'Create schedule';

  @override
  String get installmentCreated => 'Schedule created';

  @override
  String installmentEachInvalid(int count) {
    return 'This amount can\'t make $count periods add up to the price.';
  }

  @override
  String get installmentFirstTooEarly =>
      'The first period can\'t be before the purchase.';

  @override
  String get installmentPreviewError =>
      'Couldn\'t show the schedule. Check your connection.';

  @override
  String get installmentConflict => 'This purchase can\'t be split anymore.';

  @override
  String get installmentLeft => 'Left to pay';

  @override
  String installmentPaidOf(int past, int count, String wallet) {
    return '$past/$count periods paid · $wallet';
  }

  @override
  String get installmentEachAdds =>
      'Each period adds to the card\'s amount due.';

  @override
  String get installmentClose => 'End installments';

  @override
  String get installmentCloseSub => 'Use when paid off early';

  @override
  String get installmentCloseTitle => 'End installments?';

  @override
  String get installmentCloseBody =>
      'Remaining periods stop adding to the card\'s amount due. The purchase stays as it is.';

  @override
  String get installmentCloseConfirm => 'End';

  @override
  String get installmentClosed => 'Installments ended';

  @override
  String get installmentClosedTag => 'Ended';

  @override
  String get installmentLoadError => 'Couldn\'t load the schedule';

  @override
  String installmentRowSub(int index, int count, String date, String amount) {
    return 'Period $index/$count · $date · $amount';
  }

  @override
  String creditDueThisPeriod(String date) {
    return 'Due this period · $date';
  }

  @override
  String creditDaysLeftTag(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String creditIncludes(String installment, String minimum) {
    return 'Includes $installment installments · minimum $minimum';
  }

  @override
  String creditIncludesNoMin(String installment) {
    return 'Includes $installment installments';
  }

  @override
  String get installmentView => 'View installment schedule';

  @override
  String get installmentViewSub => 'Periods and what is left to pay';

  @override
  String get dataExportTitle => 'Export data';

  @override
  String get dataExportTable => 'Transactions table';

  @override
  String get dataExportTableHint => 'CSV, opens in Excel';

  @override
  String get dataExportFull => 'Full copy';

  @override
  String get dataExportFullHint => 'JSON, for safekeeping';

  @override
  String get dataExportFullNote =>
      'Everything in your account, not filtered. Meant for safekeeping, not for reading.';

  @override
  String get dataExportPeriodThisMonth => 'This month';

  @override
  String get dataExportPeriod3Months => '3 months';

  @override
  String get dataExportPeriodThisYear => 'This year';

  @override
  String get dataExportPeriodAll => 'All';

  @override
  String get dataExportPeriodCustom => 'Custom';

  @override
  String get dataExportWallets => 'Wallets';

  @override
  String get dataExportAllWallets => 'All wallets';

  @override
  String dataExportSummaryRange(String from, String to, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: 'No transactions',
    );
    return '$from – $to · $_temp0';
  }

  @override
  String dataExportSummaryAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: 'No transactions',
    );
    return 'All · $_temp0';
  }

  @override
  String dataExportTooMany(String count) {
    return 'More than $count transactions. Pick a shorter range or fewer wallets.';
  }

  @override
  String get dataExportButton => 'Export file';

  @override
  String get meImportData => 'Import from another app';

  @override
  String get importTitle => 'Import transactions';

  @override
  String get importSourceHeading => 'Data source';

  @override
  String get importSourceMoneyLover => 'Money Lover';

  @override
  String get importSourceMoneyLoverHint =>
      'Export a CSV file in the Money Lover app';

  @override
  String get importSourceMisa => 'MISA Sổ thu chi';

  @override
  String get importSourceMisaHint => 'Export a CSV file in the MISA app';

  @override
  String get importSourceFreeva => 'Freeva';

  @override
  String get importSourceFreevaHint => 'A file you exported from Freeva';

  @override
  String get importSourceOther => 'Somewhere else';

  @override
  String get importSourceOtherHint => 'You pick the date and amount columns';

  @override
  String importSourceNote(String count) {
    return 'Up to $count rows at a time. Transactions you already have are skipped.';
  }

  @override
  String get importPickFile => 'Choose CSV file';

  @override
  String get importProblemUnreadable =>
      'Can\'t read this file. Choose a CSV file.';

  @override
  String get importProblemEmpty => 'This file has no rows yet.';

  @override
  String importProblemTooMany(String count) {
    return 'This file has more than $count rows. Split it and import in parts.';
  }

  @override
  String get importProblemTooLarge =>
      'This file is too large. Split it and import in parts.';

  @override
  String get importError => 'Couldn\'t import';

  @override
  String get importColumnsTitle => 'Choose columns';

  @override
  String importFileRows(int count) {
    return '$count rows';
  }

  @override
  String get importColumnsHeader => 'COLUMNS IN THE FILE';

  @override
  String get importFieldDate => 'Date';

  @override
  String get importFieldAmount => 'Amount';

  @override
  String get importFieldType => 'Income or expense';

  @override
  String get importFieldCategory => 'Category';

  @override
  String get importFieldWallet => 'Wallet';

  @override
  String get importFieldNotes => 'Note';

  @override
  String get importColumnNone => 'Don\'t use';

  @override
  String get importDateFormat => 'Date style';

  @override
  String get importNumberFormat => 'Number style';

  @override
  String get importFirstRow => 'First readable row';

  @override
  String get importNext => 'Next';

  @override
  String get importMapTitle => 'Match wallets and categories';

  @override
  String importMapRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items left to match.',
      one: '$count item left to match.',
    );
    return '$_temp0';
  }

  @override
  String get importMapWallets => 'WALLETS IN THE FILE';

  @override
  String get importMapCategories => 'CATEGORIES IN THE FILE';

  @override
  String get importMapAllRows => 'Every row in the file';

  @override
  String get importMapChoose => 'Choose';

  @override
  String get importMapPreview => 'Preview';

  @override
  String get importPickWallet => 'Choose a wallet';

  @override
  String get importPickCategory => 'Pick a category';

  @override
  String get importPreviewTitle => 'Preview';

  @override
  String get importReady => 'Ready';

  @override
  String get importDuplicate => 'Duplicates';

  @override
  String get importInvalid => 'Errors';

  @override
  String get importFilterAll => 'All';

  @override
  String get importNoRows => 'No rows';

  @override
  String get importDuplicatesToggle => 'Import duplicates anyway';

  @override
  String get importDuplicatesHint => 'You usually don\'t need this';

  @override
  String importCommit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count transactions',
      one: 'Import $count transaction',
    );
    return '$_temp0';
  }

  @override
  String get importTagDuplicate => 'Duplicate';

  @override
  String get importTagDate => 'No date';

  @override
  String get importTagAmount => 'Bad amount';

  @override
  String get importTagType => 'Type not supported';

  @override
  String get importTagWallet => 'No wallet';

  @override
  String get importTagCategory => 'No category';

  @override
  String get importTagCategoryKind => 'Wrong category type';

  @override
  String get importTagCurrency => 'Currency differs';

  @override
  String get importTagTransfer => 'Missing other side';

  @override
  String get importTagSameWallet => 'Same wallet';

  @override
  String get importTagOther => 'Can\'t read';

  @override
  String importDoneTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count transactions',
      one: 'Imported $count transaction',
    );
    return '$_temp0';
  }

  @override
  String importDoneSkipBoth(int duplicates, int invalid) {
    return 'Skipped $duplicates duplicates and $invalid bad rows.';
  }

  @override
  String importDoneSkipDuplicates(int count) {
    return 'Skipped $count duplicates.';
  }

  @override
  String importDoneSkipInvalid(int count) {
    return 'Skipped $count bad rows.';
  }

  @override
  String get importDoneView => 'View transactions';

  @override
  String get importUndo => 'Undo this import';

  @override
  String get importDoneKept =>
      'Transactions you edited after importing are kept.';

  @override
  String importUndone(int count) {
    return 'Undid $count transactions';
  }

  @override
  String get importUndoError => 'Couldn\'t undo';

  @override
  String get meGroupManage => 'Manage money';

  @override
  String get meGroupSetup => 'Setup';

  @override
  String get meGroupData => 'Data';

  @override
  String get meBudgetShort => 'Budget';

  @override
  String get meCalendarShort => 'Calendar';

  @override
  String get meMoneyTitle => 'Income and period';

  @override
  String get meMoneyHint =>
      'Paid mid-month? Set your payday so budgets and reports use the right period.';

  @override
  String meWalletsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets',
      one: '$count wallet',
    );
    return '$_temp0';
  }

  @override
  String meRecurringCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String meCalendarMonth(int month) {
    return 'Month $month';
  }

  @override
  String get forecastTitle => 'Balance forecast';

  @override
  String forecastRange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get forecastRangeSemantics => 'Forecast range';

  @override
  String forecastEndOfMonth(int month) {
    return 'About this much left at the end of month $month';
  }

  @override
  String forecastChange(String amount) {
    return '$amount vs today';
  }

  @override
  String get forecastToday => 'Today';

  @override
  String get forecastHowTitle => 'How it is worked out';

  @override
  String get forecastStartsFrom => 'Starting balance';

  @override
  String forecastStartsFromWallets(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets',
      one: '1 wallet',
    );
    return '$amount · $_temp0';
  }

  @override
  String forecastStartsFromYou(String amount) {
    return '$amount · set by you';
  }

  @override
  String get forecastEdit => 'Edit';

  @override
  String get forecastScope =>
      'Only recurring items and bills. Daily spending is not included.';

  @override
  String forecastOtherCurrency(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items in other currencies are left out.',
      one: '1 item in another currency is left out.',
    );
    return '$_temp0';
  }

  @override
  String get forecastRulesHeader => 'Included items';

  @override
  String forecastRuleToggle(String name) {
    return 'Include $name';
  }

  @override
  String forecastEstimated(String schedule) {
    return '$schedule · estimate';
  }

  @override
  String forecastOneOff(String date) {
    return 'Once, $date';
  }

  @override
  String get forecastNoRules =>
      'No recurring items or bills yet, so the balance stays the same.';

  @override
  String forecastChartSemantics(String items) {
    return 'Forecast balance at the end of each month: $items';
  }

  @override
  String get forecastBalanceTitle => 'Starting balance';

  @override
  String get forecastBalanceHint =>
      'The forecast adds your recurring items to this amount.';

  @override
  String get forecastBalanceApply => 'Use this amount';

  @override
  String get forecastBalanceReset => 'Use the total of my wallets';

  @override
  String get forecastBalanceInvalid => 'Enter a valid amount.';

  @override
  String forecastDayEstimated(int day) {
    return 'Day $day · estimate';
  }

  @override
  String get meNetWorth => 'Net worth';

  @override
  String get netWorthTitle => 'Net worth';

  @override
  String netWorthToday(String date) {
    return 'Today · $date';
  }

  @override
  String netWorthDate(String date) {
    return '$date';
  }

  @override
  String netWorthChange(String amount, String window) {
    String _temp0 = intl.Intl.selectLogic(window, {
      'week': 'in 7 days',
      'month': 'in 30 days',
      'quarter': 'in 3 months',
      'half': 'in 6 months',
      'year': 'in 1 year',
      'other': 'overall',
    });
    return '$amount $_temp0';
  }

  @override
  String netWorthRange(String window) {
    String _temp0 = intl.Intl.selectLogic(window, {
      'week': '7 days',
      'month': '30 days',
      'quarter': '3 months',
      'half': '6 months',
      'year': '1 year',
      'other': 'All',
    });
    return '$_temp0';
  }

  @override
  String get netWorthRangeSemantics => 'Chart range';

  @override
  String get netWorthAssets => 'Assets';

  @override
  String get netWorthDebts => 'Debts';

  @override
  String get netWorthInAssets => 'In assets';

  @override
  String get netWorthWallets => 'Wallets';

  @override
  String get netWorthInvestments => 'Investments';

  @override
  String netWorthChartSemantics(String range, String from, String to) {
    return 'Net worth, $range, from $from to $to';
  }

  @override
  String get transactionInvestment => 'Investment';

  @override
  String get txKindInvestment => 'investment';

  @override
  String get txInvestmentTitle => 'Investment';

  @override
  String get txInvestmentReadOnly =>
      'This belongs to Investments and can’t be edited.';

  @override
  String get meInvestments => 'Investments';

  @override
  String get investmentOversell => 'You can’t sell more than you still hold.';

  @override
  String get investmentUnsupported => 'This investment doesn’t allow that.';

  @override
  String get investmentsTitle => 'Investments';

  @override
  String get investmentsEmptyTitle => 'No investments yet';

  @override
  String get investmentsEmptyBody =>
      'Record gold, stocks, deposits… to see your assets in one place.';

  @override
  String get investmentsTotal => 'Total investment value';

  @override
  String get investmentsCost => 'Cost';

  @override
  String get investmentsGain => 'Expected gain/loss';

  @override
  String get investmentsValue => 'Value';

  @override
  String get investmentsAllocation => 'Share by category';

  @override
  String get investmentsKinds => 'Categories';

  @override
  String get investmentsUnpriced => 'No price yet';

  @override
  String investmentKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'gold': 'Gold',
      'stock': 'Stocks',
      'fund': 'Funds',
      'savings_deposit': 'Deposits',
      'real_estate': 'Real estate',
      'crypto': 'Crypto',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String investmentsSemantics(
    String kind,
    String value,
    String cost,
    String gain,
  ) {
    return '$kind, value $value, cost $cost, expected gain or loss $gain';
  }

  @override
  String get investmentAdd => 'Add investment';

  @override
  String get investmentNewTitle => 'New investment';

  @override
  String get investmentName => 'Asset name';

  @override
  String get investmentGoldByChi => 'Count by chỉ';

  @override
  String get investmentGoldByLuong => 'Count by lượng';

  @override
  String get investmentQuantity => 'Quantity';

  @override
  String investmentUnit(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'chi': 'chỉ',
      'luong': 'lượng',
      'share': 'shares',
      'unit': 'units',
      'coin': 'coins',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String investmentUnitPrice(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'chi': 'Price per chỉ',
      'luong': 'Price per lượng',
      'share': 'Price per share',
      'unit': 'Price per unit',
      'coin': 'Price per coin',
      'other': 'Price',
    });
    return '$_temp0';
  }

  @override
  String get investmentBuyDate => 'Buy date';

  @override
  String get investmentTotalMoney => 'Total';

  @override
  String get investmentFromWallet => 'Take from wallet';

  @override
  String investmentWalletLeft(String amount) {
    return '$amount left';
  }

  @override
  String get investmentExisting => 'Already held';

  @override
  String get investmentExistingHint => 'Doesn’t take from a wallet';

  @override
  String get investmentNote => 'Note (optional)';

  @override
  String get investmentSave => 'Save investment';

  @override
  String get investmentPurchasePrice => 'Purchase price';

  @override
  String get investmentDepositAmount => 'Deposit amount';

  @override
  String get investmentRate => 'Interest rate/year';

  @override
  String get investmentDepositDate => 'Deposit date';

  @override
  String get investmentMaturity => 'Maturity date';

  @override
  String get investmentPickDate => 'Pick a date';

  @override
  String investmentHolding(String kind) {
    return '$kind held';
  }

  @override
  String get investmentTradesHeader => 'Buys';

  @override
  String get investmentBuyMore => 'Buy more';

  @override
  String get investmentSell => 'Sell';

  @override
  String get investmentUpdatePrice => 'Update price';

  @override
  String investmentPerUnit(String price, String unit) {
    return '$price/$unit';
  }

  @override
  String investmentTradePrice(String price, String unit) {
    return 'Price $price/$unit';
  }

  @override
  String investmentTradeCost(String price, String unit) {
    return 'Cost $price/$unit';
  }

  @override
  String get investmentExistingBox => 'held';

  @override
  String get investmentSold => 'Sold';

  @override
  String investmentSoldLine(String quantity, String gain) {
    return '$quantity · realized $gain';
  }

  @override
  String investmentSoldGain(String gain) {
    return 'Realized $gain';
  }

  @override
  String investmentSellTitle(String name) {
    return 'Sell $name';
  }

  @override
  String investmentHeld(String quantity) {
    return 'Holding $quantity';
  }

  @override
  String get investmentReceive => 'You receive';

  @override
  String get investmentSellQty => 'Quantity to sell';

  @override
  String investmentSellPrice(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'chi': 'Sell price per chỉ',
      'luong': 'Sell price per lượng',
      'share': 'Sell price per share',
      'unit': 'Sell price per unit',
      'coin': 'Sell price per coin',
      'other': 'Sell price',
    });
    return '$_temp0';
  }

  @override
  String investmentSellAll(String quantity) {
    return 'Sell all $quantity';
  }

  @override
  String get investmentSellDate => 'Sell date';

  @override
  String get investmentToWallet => 'Into wallet';

  @override
  String investmentRealized(String gain) {
    return 'Realized $gain';
  }

  @override
  String investmentSellButton(String quantity, String amount) {
    return 'Sell $quantity · $amount';
  }

  @override
  String investmentPriceTitle(String name) {
    return 'Price of $name';
  }

  @override
  String investmentPriceOne(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'chi': 'Price per chỉ',
      'luong': 'Price per lượng',
      'share': 'Price per share',
      'unit': 'Price per unit',
      'coin': 'Price per coin',
      'other': 'Price',
    });
    return '$_temp0';
  }

  @override
  String investmentPricePrev(String price, String date) {
    return 'Previous $price · $date';
  }

  @override
  String get investmentQuoteDate => 'Quote date';

  @override
  String get investmentSavePrice => 'Save price';

  @override
  String get depositValueToday => 'Value today';

  @override
  String get depositPrincipal => 'Principal';

  @override
  String get depositInterest => 'Interest so far';

  @override
  String get depositRateLabel => 'Interest rate';

  @override
  String depositRatePerYear(String rate) {
    return '$rate/year';
  }

  @override
  String depositMaturityLeft(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$date · $_temp0';
  }

  @override
  String depositMatured(String date) {
    return '$date · matured';
  }

  @override
  String get depositWithdraw => 'Withdraw deposit';

  @override
  String get depositEdit => 'Edit';

  @override
  String get depositDelete => 'Delete';

  @override
  String get depositReceive => 'You receive';

  @override
  String get depositWithdrawDate => 'Withdraw date';

  @override
  String get depositToWallet => 'Into wallet';

  @override
  String depositWithdrawButton(String amount) {
    return 'Withdraw $amount';
  }

  @override
  String get depositDeleteTitle => 'Delete this deposit?';

  @override
  String get depositDeleteBody =>
      'The deposit is removed and the principal goes back to the wallet it came from.';

  @override
  String get depositEditTitle => 'Edit deposit';

  @override
  String get depositEditSave => 'Save';

  @override
  String get depositMaturityRow => 'Matures';

  @override
  String tradeTitle(String date) {
    return 'Buy $date';
  }

  @override
  String tradeCardTitle(String name) {
    return '$name · current value';
  }

  @override
  String tradeQuantityTimes(String quantity, String price) {
    return '$quantity × $price';
  }

  @override
  String get tradeCurrentPrice => 'Current price';

  @override
  String get tradeNoteRow => 'Note';

  @override
  String get tradeEdit => 'Edit';

  @override
  String get tradeDelete => 'Delete';

  @override
  String get tradeEditTitle => 'Edit buy';

  @override
  String get tradeDeleteLink => 'Delete this buy';

  @override
  String tradeDeleteTitle(String date) {
    return 'Delete buy $date?';
  }

  @override
  String tradeDeleteLine(String quantity, String name) {
    return '$quantity $name';
  }

  @override
  String tradeRefund(String wallet) {
    return 'Back to $wallet';
  }

  @override
  String get tradeDeleteConfirm => 'Delete buy';

  @override
  String get tradeKeep => 'Keep';

  @override
  String get tradeSave => 'Save';

  @override
  String get tradePriceRow => 'Purchase price';

  @override
  String get serverConfigErrorTitle => 'Settings did not load';

  @override
  String get serverConfigErrorMessage => 'Check your connection and try again.';

  @override
  String get commonAnd => 'and';

  @override
  String get autoSuggestTitle => 'Auto suggestions';

  @override
  String get autoSuggestOn => 'On';

  @override
  String get autoSuggestOff => 'Off';

  @override
  String get autoSuggestSubtitle => 'Categories, insights, forecasts';

  @override
  String get autoSuggestPrivacy =>
      'Worked out from your records only, never sent elsewhere.';

  @override
  String autoSuggestMerchants(int count) {
    return 'Remembered shops · $count';
  }

  @override
  String autoSuggestForget(String merchant) {
    return 'Forget $merchant';
  }

  @override
  String get autoSuggestClear => 'Delete learned data';

  @override
  String get autoSuggestClearTitle => 'Delete learned data?';

  @override
  String autoSuggestClearBody(int count) {
    return '$count remembered shops will be deleted. Your transactions stay as they are.';
  }

  @override
  String get autoSuggestDelete => 'Delete';

  @override
  String get autoSuggestError => 'Could not save. Please try again.';

  @override
  String autoSuggestSeeAll(int count) {
    return 'See all $count';
  }

  @override
  String txSuggestTitle(String category) {
    return 'File under $category?';
  }

  @override
  String txSuggestHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Same as $count times before here',
      one: 'Same as last time here',
    );
    return '$_temp0';
  }

  @override
  String get txSuggestUse => 'Use';

  @override
  String importFilterSuggested(int count) {
    return 'Suggested $count';
  }

  @override
  String get importSuggestHint =>
      'Categories guessed from the shop. Tap to change.';

  @override
  String get importPickSheetLabel => 'Change category';

  @override
  String get importPickSuggested => 'Suggested';

  @override
  String get importPickOther => 'Or pick another category';

  @override
  String importApplySame(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Apply to $count items here',
      one: 'Apply to 1 item here',
    );
    return '$_temp0';
  }

  @override
  String importApplySameHint(String merchant) {
    return '$merchant items in this file';
  }

  @override
  String get importPickDone => 'Done';
}
