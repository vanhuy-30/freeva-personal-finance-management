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
  String get authWrongPin =>
      'Incorrect PIN. After five failed attempts, sign in again.';

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
  String get meGroupFinance => 'Money setup';

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
  String get meBills => 'Bills';

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
  String get billsTitle => 'Bills';

  @override
  String get billsAdd => 'Add bill';

  @override
  String get billsEdit => 'Edit bill';

  @override
  String get billsDelete => 'Delete';

  @override
  String get billsSave => 'Save';

  @override
  String get billsEmptyTitle => 'No bills yet';

  @override
  String get billsEmptyBody =>
      'Track utilities and subscriptions. Mark paid by linking an existing transaction.';

  @override
  String get billsLoadError => 'Couldn’t load bills';

  @override
  String get billsName => 'Name';

  @override
  String get billsAmount => 'Amount';

  @override
  String get billsAmountFixed => 'Fixed';

  @override
  String get billsAmountEstimated => 'Estimated';

  @override
  String get billsDueOn => 'Due date (YYYY-MM-DD)';

  @override
  String get billsRecurring => 'Link recurring';

  @override
  String get billsOneOff => 'One-off';

  @override
  String get billsLinkedRecurring => 'Linked recurring';

  @override
  String get billsFilterAll => 'All';

  @override
  String get billsStatusOpen => 'Open';

  @override
  String get billsStatusOverdue => 'Overdue';

  @override
  String get billsStatusPaid => 'Paid';

  @override
  String get billsMarkPaid => 'Mark as paid';

  @override
  String get billsUnpay => 'Clear paid mark';

  @override
  String get billsPickTransaction => 'Choose a transaction';

  @override
  String get billsNoTransactions => 'No transactions to link yet';

  @override
  String get billsMarkedPaid => 'Payment linked';

  @override
  String get billsClearedPaid => 'Paid mark cleared';

  @override
  String get billsInvalid => 'Enter a valid name and amount';

  @override
  String get recurringTitle => 'Recurring';

  @override
  String get recurringAdd => 'Add recurring';

  @override
  String get recurringEdit => 'Edit recurring';

  @override
  String get recurringDelete => 'Delete';

  @override
  String get recurringSave => 'Save';

  @override
  String get recurringEmptyTitle => 'No recurring yet';

  @override
  String get recurringEmptyBody =>
      'Set rent, salary, or transfers once and Freeva posts them on schedule.';

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
  String get recurringFrequency => 'Frequency';

  @override
  String get recurringInterval => 'Every';

  @override
  String recurringEvery(String count) {
    return 'Every $count';
  }

  @override
  String get recurringUnitDay => 'Daily';

  @override
  String get recurringUnitWeek => 'Weekly';

  @override
  String get recurringUnitMonth => 'Monthly';

  @override
  String get recurringUnitYear => 'Yearly';

  @override
  String get recurringStart => 'Start date (YYYY-MM-DD)';

  @override
  String get recurringNextLabel => 'Next run (YYYY-MM-DD)';

  @override
  String get recurringEnd => 'End date (optional)';

  @override
  String get recurringActive => 'Active';

  @override
  String recurringNext(String date) {
    return 'Next $date';
  }

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
  String get mePinWrong => 'Wrong PIN. After 5 misses you sign in again.';

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
  String get mePasswordHint =>
      'At least 12 characters, with letters and digits.';

  @override
  String get mePasswordWrong => 'That isn\'t your current password.';

  @override
  String get mePasswordWeak =>
      'Use at least 12 characters with letters and digits, different from the old one.';

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
  String get notifyRecord => 'Record reminder';

  @override
  String get notifyRecordSub => 'Every day';

  @override
  String get notifyDigest => 'Spending summary';

  @override
  String get notifyDigestSub => 'Every week or month';

  @override
  String get notifyBudget => 'Budget running out';

  @override
  String get notifyBudgetSub => 'At 80% and 100% used';

  @override
  String get notifyCard => 'Credit card due';

  @override
  String get notifyCardSub => '3 days before';

  @override
  String get notifySession => 'New device signed in';

  @override
  String get notifyRecurring => 'Recurring due soon';

  @override
  String get notifyRecurringSub => 'One day before the next run';

  @override
  String get notifyGoal => 'Goal contribution reminder';

  @override
  String get notifyGoalSub => 'When a contribution is due';

  @override
  String get notifyDebt => 'Debt due';

  @override
  String get notifyDebtSub => 'Before the due date';

  @override
  String get notifyMonthReview => 'Month review';

  @override
  String get notifyMonthReviewSub => 'When a month summary is ready';

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
  String get passwordRuleLength => 'At least 12 characters';

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
  String get onbGoalsTitle => 'What would you like to improve?';

  @override
  String get onbGoalsSub => 'Pick up to 2.';

  @override
  String get onbGoalTrack => 'Track spending';

  @override
  String get onbGoalSave => 'Save more';

  @override
  String get onbGoalBudget => 'Stay on budget';

  @override
  String get onbGoalDebt => 'Manage debt';

  @override
  String get onbGoalEmergency => 'Build an emergency fund';

  @override
  String get onbGoalUnderstand => 'Understand my finances';

  @override
  String get onbHabitTitle => 'How do you manage money now?';

  @override
  String get onbHabitManual => 'Notes by hand';

  @override
  String get onbHabitSpreadsheet => 'Excel or Sheets';

  @override
  String get onbHabitApp => 'Another app';

  @override
  String get onbHabitNone => 'Not tracking yet';

  @override
  String get onbCadenceTitle => 'How often do you review spending?';

  @override
  String get onbCadenceDaily => 'Every day';

  @override
  String get onbCadenceWeekly => 'Every week';

  @override
  String get onbCadenceMonthly => 'Every month';

  @override
  String get onbCadenceRarely => 'Hardly ever';

  @override
  String get onbBudgetTitle => 'How much do you plan to spend each month?';

  @override
  String get onbBudgetAmount => 'Monthly budget';

  @override
  String get onbBudgetLater => 'Set up later';

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
}
