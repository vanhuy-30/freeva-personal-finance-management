// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class SVi extends S {
  SVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Freeva';

  @override
  String get splashTagline => 'Your money. Your freedom.';

  @override
  String get brandWordmark => 'FREEVA';

  @override
  String get authLogin => 'Đăng nhập';

  @override
  String get authRegister => 'Đăng ký';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Mật khẩu';

  @override
  String get authInvalidInput => 'Kiểm tra lại email và mật khẩu.';

  @override
  String get authInvalidCredentials => 'Email hoặc mật khẩu không đúng.';

  @override
  String get authInvalidToken => 'Mã không hợp lệ, đã dùng hoặc đã hết hạn.';

  @override
  String authRateLimited(int seconds) {
    return 'Quá nhiều yêu cầu. Thử lại sau $seconds giây.';
  }

  @override
  String get authNetworkError =>
      'Không thể kết nối. Kiểm tra mạng rồi thử lại.';

  @override
  String get authStorageError =>
      'Không thể truy cập bộ nhớ bảo mật. Vui lòng thử lại.';

  @override
  String get authUnavailable =>
      'Chưa thể thực hiện. Kiểm tra cấu hình dịch vụ hoặc sử dụng PIN nếu sinh trắc học không khả dụng.';

  @override
  String get authWrongPin =>
      'PIN không đúng. Sau 5 lần sai, cần đăng nhập lại.';

  @override
  String get authExpired =>
      'Phiên hết hạn, bị thu hồi hoặc PIN sai quá giới hạn. Vui lòng đăng nhập lại.';

  @override
  String get authBiometricReason => 'Xác thực để mở khóa Freeva';

  @override
  String get authUseBiometric => 'Dùng sinh trắc học';

  @override
  String get authSessions => 'Quản lý phiên đăng nhập';

  @override
  String get authCurrentSession => 'Phiên hiện tại';

  @override
  String get authOtherSession => 'Phiên khác';

  @override
  String authSessionExpiry(String date) {
    return 'Hết hạn: $date';
  }

  @override
  String get authRevoke => 'Thu hồi phiên';

  @override
  String get authRevokeAll => 'Đăng xuất mọi phiên';

  @override
  String get authLockNow => 'Khóa ngay';

  @override
  String get authLogout => 'Đăng xuất';

  @override
  String get authContinue => 'Tiếp tục';

  @override
  String get authCreateAccount => 'Tạo tài khoản';

  @override
  String get authVerifyTitle => 'Xác nhận email';

  @override
  String get authRecoverTitle => 'Quên mật khẩu?';

  @override
  String get authRecoverSubtitle => 'Nhập email, Freeva gửi link đặt lại.';

  @override
  String get authNewPasswordTitle => 'Đặt mật khẩu mới';

  @override
  String get authNewPassword => 'Mật khẩu mới';

  @override
  String get authConfirmPassword => 'Nhập lại mật khẩu';

  @override
  String get authPasswordChanged =>
      'Đã đổi mật khẩu. Đăng nhập bằng mật khẩu mới.';

  @override
  String get authPasswordMismatch =>
      'Hai mật khẩu chưa khớp. Vui lòng nhập lại.';

  @override
  String get authInvalidEmail => 'Vui lòng nhập địa chỉ email hợp lệ.';

  @override
  String get authBack => 'Quay lại';

  @override
  String get profileTitle => 'Hồ sơ tài chính';

  @override
  String get profileLanguage => 'Ngôn ngữ';

  @override
  String get profileVietnamese => 'Tiếng Việt';

  @override
  String get profileEnglish => 'Tiếng Anh';

  @override
  String get profileCurrency => 'Tiền tệ mặc định';

  @override
  String get profileCurrencyHint =>
      'Áp dụng mặc định cho dữ liệu mới; không quy đổi số tiền hiện có.';

  @override
  String get profileTimezone => 'Múi giờ';

  @override
  String get profileFiscalDay => 'Ngày bắt đầu tháng tài chính';

  @override
  String get profileFiscalHint =>
      'Chọn ngày từ 1 đến 28 để kỳ tài chính luôn bắt đầu đúng ngày mỗi tháng.';

  @override
  String get profileSave => 'Lưu thay đổi';

  @override
  String get profileCancel => 'Hủy thay đổi';

  @override
  String get profileSaved => 'Đã lưu hồ sơ.';

  @override
  String get profileLoadError => 'Không tải được hồ sơ. Vui lòng thử lại.';

  @override
  String get profileSaveError => 'Chưa lưu được thay đổi. Vui lòng thử lại.';

  @override
  String get profileConflict =>
      'Hồ sơ đã thay đổi trên thiết bị khác. Tải lại trước khi chỉnh sửa.';

  @override
  String get profileReload => 'Tải lại';

  @override
  String get profileInvalid =>
      'Kiểm tra ngôn ngữ, tiền tệ, múi giờ và ngày bắt đầu kỳ (1–28).';

  @override
  String get profileBack => 'Về trang chủ';

  @override
  String get profileSearch => 'Tìm múi giờ';

  @override
  String get walletTitle => 'Ví của tôi';

  @override
  String get walletAdd => 'Thêm ví';

  @override
  String get walletEdit => 'Sửa ví';

  @override
  String get walletCash => 'Tiền mặt';

  @override
  String get walletBank => 'Ngân hàng';

  @override
  String get walletEwallet => 'Ví điện tử';

  @override
  String get walletCredit => 'Thẻ tín dụng';

  @override
  String get walletName => 'Tên ví';

  @override
  String get walletType => 'Loại ví';

  @override
  String get walletInitialBalance => 'Số dư ban đầu';

  @override
  String get walletHide => 'Ẩn ví';

  @override
  String get walletHiddenEmpty => 'Không có ví đã ẩn.';

  @override
  String get walletInvalid => 'Kiểm tra lại tên và số tiền.';

  @override
  String get walletConflict => 'Ví vừa đổi ở nơi khác. Mở lại để sửa tiếp.';

  @override
  String get walletError => 'Chưa lưu được ví. Thử lại nhé.';

  @override
  String get transactionTitle => 'Giao dịch';

  @override
  String get transactionRecord => 'Ghi giao dịch';

  @override
  String get transactionExpense => 'Chi';

  @override
  String get transactionIncome => 'Thu';

  @override
  String get transactionTransfer => 'Chuyển';

  @override
  String get transactionAll => 'Tất cả';

  @override
  String get transactionAmount => 'Số tiền';

  @override
  String get transactionWallet => 'Ví';

  @override
  String get transactionDestination => 'Ví đích';

  @override
  String get transactionCategory => 'Danh mục';

  @override
  String get transactionAllCategories => 'Tất cả danh mục';

  @override
  String get transactionDate => 'Ngày';

  @override
  String get transactionNotes => 'Ghi chú';

  @override
  String get transactionMerchant => 'Người nhận / cửa hàng';

  @override
  String get transactionTags => 'Nhãn';

  @override
  String get transactionTagCreate => 'Tạo nhãn';

  @override
  String get transactionTagCreateTitle => 'Tạo nhãn mới';

  @override
  String get transactionTagName => 'Tên nhãn';

  @override
  String get transactionTagLimit => 'Tối đa 20 nhãn';

  @override
  String get transactionSave => 'Lưu';

  @override
  String get transactionEdit => 'Sửa giao dịch';

  @override
  String get transactionCopy => 'Sao chép';

  @override
  String get transactionDelete => 'Xóa';

  @override
  String get transactionRestore => 'Khôi phục';

  @override
  String get transactionDeleteTitle => 'Xóa giao dịch?';

  @override
  String get transactionDeleteBody =>
      'Giao dịch được xóa mềm và không còn tính vào số dư.';

  @override
  String get transactionCancel => 'Hủy';

  @override
  String get transactionEmpty => 'Chưa có giao dịch.';

  @override
  String get transactionDeletedEmpty => 'Không có giao dịch đã xóa.';

  @override
  String get transactionNoWallet =>
      'Cần ít nhất một ví đang dùng trước khi ghi giao dịch.';

  @override
  String get transactionCreateWallet => 'Tạo ví';

  @override
  String get transactionShowDeleted => 'Xem giao dịch đã xóa';

  @override
  String get transactionSearch => 'Tìm trong ghi chú';

  @override
  String get transactionInvalid =>
      'Kiểm tra số tiền, ví, danh mục, ngày hoặc tỷ giá. Chi cần danh mục. Chuyển khoản khác tiền tệ chỉ nhận tỷ giá đúng đơn vị.';

  @override
  String get transactionConflict =>
      'Giao dịch đã thay đổi ở nơi khác. Tải lại danh sách trước khi sửa tiếp.';

  @override
  String get transactionError =>
      'Không thể tải hoặc lưu giao dịch. Vui lòng thử lại.';

  @override
  String get transactionReloadRequired =>
      'Dữ liệu đã cũ. Tải lại trước khi ghi tiếp.';

  @override
  String get transactionRate => 'Tỷ giá';

  @override
  String get transactionRateHint =>
      'Nhập tỷ giá thủ công. Số tiền đích phải khớp đúng đơn vị nhỏ nhất, không làm tròn.';

  @override
  String get transactionLoadMore => 'Tải thêm';

  @override
  String get categoryTitle => 'Danh mục';

  @override
  String get categoryAdd => 'Thêm danh mục';

  @override
  String get categoryEdit => 'Sửa danh mục';

  @override
  String get categoryName => 'Tên danh mục';

  @override
  String get categoryColor => 'Màu';

  @override
  String get categoryIcon => 'Biểu tượng';

  @override
  String get categoryHiddenEmpty => 'Không có danh mục đã ẩn.';

  @override
  String get categoryInvalid => 'Kiểm tra lại tên và danh mục chính.';

  @override
  String get categoryConflict =>
      'Danh mục vừa đổi ở nơi khác. Mở lại để sửa tiếp.';

  @override
  String get categoryError => 'Chưa lưu được danh mục. Thử lại nhé.';

  @override
  String get reportTitle => 'Báo cáo';

  @override
  String get reportOverview => 'Tổng quan';

  @override
  String get reportThisMonth => 'Tháng này';

  @override
  String get reportNetWorth => 'Tài sản ròng';

  @override
  String get reportAssets => 'Tài sản';

  @override
  String get reportLiabilities => 'Nợ';

  @override
  String get reportIncome => 'Thu';

  @override
  String get reportExpense => 'Chi';

  @override
  String get monthReviewTitle => 'Soát tháng';

  @override
  String get monthReviewOpen => 'Xem bản soát tháng';

  @override
  String get monthReviewSavings => 'Tiết kiệm';

  @override
  String get monthReviewSavingsRate => 'Tỷ lệ tiết kiệm';

  @override
  String get monthReviewTopCategories => 'Danh mục hàng đầu';

  @override
  String get monthReviewNoCategories => 'Chưa có danh mục chi tháng này.';

  @override
  String get reportWeek => 'Tuần';

  @override
  String get reportMonth => 'Tháng';

  @override
  String get reportRange => 'Tuỳ chọn';

  @override
  String get reportPrevious => 'Kỳ trước';

  @override
  String get reportNext => 'Kỳ sau';

  @override
  String get reportApply => 'Xem khoảng này';

  @override
  String get reportError => 'Không thể tải báo cáo. Vui lòng thử lại.';

  @override
  String get reportInvalid => 'Khoảng ngày chưa hợp lệ.';

  @override
  String reportPeriod(String from, String to) {
    return '$from – $to';
  }

  @override
  String reportAmount(String label, String amount, String currency) {
    return '$label: $amount $currency';
  }

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsBack => 'Quay lại';

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsThemeSystem => 'Theo hệ thống';

  @override
  String get settingsProfile => 'Ngôn ngữ, tiền tệ và múi giờ';

  @override
  String get settingsPermissions => 'Quyền hệ thống';

  @override
  String get settingsBiometric => 'Mở khóa bằng sinh trắc';

  @override
  String get settingsBiometricReason => 'Xác thực để đổi mở khóa sinh trắc';

  @override
  String get settingsBiometricOn => 'Đang bật';

  @override
  String get settingsBiometricOff => 'Đang tắt';

  @override
  String get settingsBiometricUnavailable => 'Thiết bị này không có sinh trắc.';

  @override
  String get settingsBiometricPin =>
      'Hãy tạo PIN ở màn khóa trước khi bật sinh trắc.';

  @override
  String get settingsBiometricFailed =>
      'Chưa xác nhận sinh trắc. Cài đặt không đổi.';

  @override
  String get settingsHelp => 'Trợ giúp';

  @override
  String get settingsFaq => 'Câu hỏi thường gặp';

  @override
  String get settingsTerms => 'Điều khoản dịch vụ (nháp)';

  @override
  String get settingsPrivacy => 'Chính sách bảo mật (nháp)';

  @override
  String settingsVersion(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get settingsStorageError =>
      'Chưa lưu được cài đặt trên thiết bị này. Vui lòng thử lại.';

  @override
  String get faqTitle => 'Câu hỏi thường gặp';

  @override
  String get legalDraft =>
      'Bản nháp cho PRD-P0-002. Đây không phải tư vấn pháp lý và chưa có hiệu lực. Pháp nhân vận hành và kênh liên hệ chưa được chốt.';

  @override
  String get tosTitle => 'Điều khoản dịch vụ';

  @override
  String get tosBody =>
      'Freeva để bạn ghi ví và giao dịch do bạn nhập. Bạn giữ dữ liệu tài chính của mình. Đơn vị vận hành chưa được chốt. Bạn có thể xuất dữ liệu và xóa tài khoản trong Hồ sơ. Bản tóm tắt này không thay điều khoản đã được luật sư rà.';

  @override
  String get privacyTitle => 'Chính sách bảo mật';

  @override
  String get privacyBody =>
      'Tài khoản lưu email, ngôn ngữ, múi giờ, tiền tệ mặc định và ngày bắt đầu tháng tài chính. Số tiền bạn nhập không được ghi vào log. Phản hồi bạn soạn ở lại trên thiết bị cho đến khi có kênh liên hệ. Sự kiện phân tích không gồm email, số dư hoặc số tài khoản. Bản tóm tắt này không thay chính sách đã được luật sư rà.';

  @override
  String get balanceHiddenMask => '••••';

  @override
  String get balanceHide => 'Ẩn số dư';

  @override
  String get balanceShow => 'Hiện số dư';

  @override
  String get settingsPrivacyControls => 'Quyền riêng tư';

  @override
  String get settingsHideBalances => 'Ẩn số dư';

  @override
  String get settingsHideBalancesHelp =>
      'Che số tiền đang hiển thị trên máy này. Ô đang nhập vẫn hiện số bạn gõ.';

  @override
  String get settingsSessionAlerts => 'Cảnh báo phiên mới';

  @override
  String get settingsSessionAlertsHelp =>
      'Báo trên máy này khi có phiên đăng nhập khác. Không gồm email, số dư hay tên thiết bị.';

  @override
  String get sessionAlertTitle => 'Phiên đăng nhập mới';

  @override
  String get sessionAlertBody =>
      'Có phiên đăng nhập khác. Mở Freeva để xem và thu hồi nếu không phải bạn.';

  @override
  String get sessionAlertReview => 'Xem các phiên';

  @override
  String get navOverview => 'Tổng quan';

  @override
  String get navTransactions => 'Giao dịch';

  @override
  String get navReports => 'Báo cáo';

  @override
  String get navMe => 'Cá nhân';

  @override
  String get navRecord => 'Ghi giao dịch';

  @override
  String get commonUndo => 'Hoàn tác';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get balanceHiddenSemantics => 'số dư đã ẩn';

  @override
  String get keypadDelete => 'Xoá';

  @override
  String get commonLoading => 'Đang tải';

  @override
  String get passwordShow => 'Hiện mật khẩu';

  @override
  String get passwordHide => 'Ẩn mật khẩu';

  @override
  String get homeDatePattern => 'EEEE, dd/MM';

  @override
  String get homeMonthPattern => 'M';

  @override
  String homeGreeting(String name) {
    return 'Chào $name';
  }

  @override
  String get homeGreetingAnon => 'Chào bạn';

  @override
  String get homeSearch => 'Tìm giao dịch';

  @override
  String get homeNotifications => 'Thông báo';

  @override
  String homeTotalBalance(int count) {
    return 'Tổng số dư · $count ví';
  }

  @override
  String homeTotalBalanceIn(int count, String currency) {
    return 'Tổng số dư · $count ví $currency';
  }

  @override
  String homeOtherCurrency(String amount, String currency, int count) {
    return '$amount $currency · $count ví';
  }

  @override
  String homeIncomeMonth(String month) {
    return 'Thu tháng $month';
  }

  @override
  String homeExpenseMonth(String month) {
    return 'Chi tháng $month';
  }

  @override
  String get homeQuickIncome => 'Ghi thu';

  @override
  String get homeQuickTransfer => 'Chuyển ví';

  @override
  String get homeQuickWallets => 'Ví của tôi';

  @override
  String get homeQuickCategories => 'Danh mục';

  @override
  String get homeSpendOther => 'Khác';

  @override
  String get homeSpendEmpty => 'Chưa có khoản chi nào.';

  @override
  String get homeSpendRecord => 'Ghi chi';

  @override
  String homeOtherCurrencySpend(String currency, String amount) {
    return 'Ví $currency: chi $amount $currency tháng này';
  }

  @override
  String homeReviewMonth(String month) {
    return 'Xem lại tháng $month';
  }

  @override
  String homeReviewLine(String expense, String income) {
    return 'Chi $expense · Thu $income';
  }

  @override
  String get homeCreditTitle => 'Thẻ tín dụng';

  @override
  String homeCreditDue(String date) {
    return 'Đến hạn $date';
  }

  @override
  String get homeRecent => 'Gần đây';

  @override
  String get homeSeeTransactions => 'Xem giao dịch';

  @override
  String get homeRecentEmpty => 'Giao dịch sẽ hiện ở đây';

  @override
  String get homePendingSync => 'Chờ đồng bộ';

  @override
  String get homeErrorTitle => 'Chưa tải được số dư';

  @override
  String get homeErrorBody => 'Dữ liệu của bạn vẫn an toàn.';

  @override
  String homeSpokenExpense(String amount, String currency) {
    return 'trừ $amount $currency';
  }

  @override
  String homeSpokenIncome(String amount, String currency) {
    return 'cộng $amount $currency';
  }

  @override
  String homeSpokenRow(String amount, String title, String detail) {
    return '$amount, $title, $detail';
  }

  @override
  String get homeUncategorized => 'Chưa phân loại';

  @override
  String get notificationsEmpty => 'Chưa có thông báo';

  @override
  String get notificationsEmptyBody => 'Nhắc việc và cảnh báo sẽ hiện ở đây.';

  @override
  String get homeSpokenVnd => 'đồng';

  @override
  String get txSearchAction => 'Tìm kiếm';

  @override
  String get txFilterAction => 'Bộ lọc';

  @override
  String get txFilterActive => 'Bộ lọc đang bật';

  @override
  String get txPeriodThisWeek => 'Tuần này';

  @override
  String get txPeriodThisMonth => 'Tháng này';

  @override
  String get txPeriodLastMonth => 'Tháng trước';

  @override
  String get txPeriodCustom => 'Tuỳ chọn';

  @override
  String get txPeriodAllTime => 'Mọi lúc';

  @override
  String txMonthChip(String month) {
    return 'Tháng $month';
  }

  @override
  String txRangeChip(String from, String to) {
    return '$from – $to';
  }

  @override
  String get txToday => 'Hôm nay';

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
    return 'Bỏ $label';
  }

  @override
  String get txFilterReset => 'Đặt lại';

  @override
  String get txFilterPeriod => 'Thời gian';

  @override
  String get txFilterWallets => 'Ví';

  @override
  String get txFilterCategories => 'Danh mục';

  @override
  String get txFilterTags => 'Nhãn';

  @override
  String get txFilterAny => 'Tất cả';

  @override
  String get txFilterDeleted => 'Đã xoá';

  @override
  String txFilterApply(int count) {
    return 'Xem $count giao dịch';
  }

  @override
  String get txFilterApplyUnknown => 'Xem giao dịch';

  @override
  String get txFilterDone => 'Xong';

  @override
  String get txNoResultTitle => 'Không có giao dịch phù hợp';

  @override
  String get txNoResultBody => 'Thử bỏ bớt bộ lọc.';

  @override
  String get txNoResultClear => 'Xoá bộ lọc';

  @override
  String get txEmptyTitle => 'Chưa có giao dịch';

  @override
  String get txEmptyBody => 'Ghi khoản chi đầu tiên chỉ mất vài giây.';

  @override
  String get txEmptyAction => 'Ghi khoản chi';

  @override
  String get txSearchHint => 'Tìm giao dịch';

  @override
  String get txSearchCancel => 'Huỷ';

  @override
  String get txSearchClear => 'Xoá chữ';

  @override
  String txSearchResults(int count) {
    return '$count kết quả';
  }

  @override
  String get txSearchPrompt => 'Tìm theo cửa hàng, ghi chú hoặc số tiền.';

  @override
  String get txDetailCategory => 'Danh mục';

  @override
  String get txDetailWallet => 'Ví';

  @override
  String get txDetailDate => 'Thời gian';

  @override
  String get txDetailTags => 'Nhãn';

  @override
  String get txDetailNotes => 'Ghi chú';

  @override
  String get txDetailFrom => 'Từ';

  @override
  String get txDetailTo => 'Đến';

  @override
  String get txDetailDelete => 'Xoá giao dịch';

  @override
  String get txDetailCopy => 'Sao chép';

  @override
  String get txDetailEdit => 'Sửa';

  @override
  String get txKindExpense => 'khoản chi';

  @override
  String get txKindIncome => 'khoản thu';

  @override
  String get txKindTransfer => 'chuyển ví';

  @override
  String txDeletedToast(String kind) {
    return 'Đã xoá $kind';
  }

  @override
  String get txRestoredToast => 'Đã khôi phục';

  @override
  String get txTrashTitle => 'Đã xoá';

  @override
  String get txTrashBody => 'Khôi phục để đưa giao dịch về danh sách.';

  @override
  String get txTrashRestore => 'Khôi phục';

  @override
  String get txTrashEmpty => 'Không có giao dịch đã xoá';

  @override
  String get txLoadFailed => 'Chưa tải được giao dịch';

  @override
  String get txTransferTitle => 'Chuyển ví';

  @override
  String get txAmountLabel => 'Số tiền';

  @override
  String get txTransferAmountLabel => 'Số tiền chuyển';

  @override
  String get txDateLabel => 'Ngày';

  @override
  String get txMoreButton => 'Ghi chú, cửa hàng, nhãn';

  @override
  String get txSaveExpense => 'Lưu khoản chi';

  @override
  String get txSaveIncome => 'Lưu khoản thu';

  @override
  String get txSaveTransfer => 'Lưu chuyển ví';

  @override
  String get txSaveChanges => 'Lưu thay đổi';

  @override
  String txEditTitle(String kind) {
    return 'Sửa $kind';
  }

  @override
  String get txMerchantLabel => 'Cửa hàng';

  @override
  String get txMerchantHint => 'Ví dụ: Phở Thìn';

  @override
  String get txNotesHint => 'Thêm ghi chú';

  @override
  String get txAddTag => 'Thêm nhãn';

  @override
  String get txPickCategory => 'Chọn danh mục';

  @override
  String get txFindCategory => 'Tìm danh mục';

  @override
  String get txFrequent => 'Hay dùng';

  @override
  String get txFindOrCreateTag => 'Tìm hoặc tạo nhãn';

  @override
  String txCreateTag(String name) {
    return 'Tạo nhãn “$name”';
  }

  @override
  String get txSelected => 'Đã chọn';

  @override
  String get txSwap => 'Đổi chiều chuyển';

  @override
  String get txPickWallet => 'Chọn ví';

  @override
  String get txWalletSubExpense => 'Khoản chi sẽ trừ vào ví này';

  @override
  String get txWalletSubIncome => 'Khoản thu sẽ cộng vào ví này';

  @override
  String txRateLabel(String time) {
    return 'Tỷ giá lúc $time';
  }

  @override
  String get txRateEmpty => 'Nhập tỷ giá';

  @override
  String txRateValue(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String get txReceived => 'Nhận được';

  @override
  String get txRateTitle => 'Tỷ giá';

  @override
  String get txDateTitle => 'Chọn ngày';

  @override
  String get txDateTimeTitle => 'Chọn thời gian';

  @override
  String get txTimeLabel => 'Giờ';

  @override
  String get txTimeNone => 'Không có giờ';

  @override
  String get txTimeClear => 'Bỏ giờ';

  @override
  String get txDateTimeDone => 'Xong';

  @override
  String get txYesterday => 'Hôm qua';

  @override
  String txSavedToast(String kind) {
    return 'Đã lưu $kind';
  }

  @override
  String txDiscardTitle(String kind) {
    return 'Bỏ $kind đang nhập?';
  }

  @override
  String get txDiscardBody => 'Số tiền và ghi chú sẽ không được lưu.';

  @override
  String get txKeepEditing => 'Tiếp tục nhập';

  @override
  String get txDiscard => 'Bỏ';

  @override
  String get txAmountMissing => 'Nhập số tiền trước khi lưu.';

  @override
  String get txPickDestination => 'Chọn ví nhận tiền.';

  @override
  String get txRateInvalid => 'Tỷ giá chưa hợp lệ với số tiền này.';

  @override
  String walletTotal(int count) {
    return 'Tổng số dư · $count ví';
  }

  @override
  String walletOtherTotal(String amount, int count) {
    return '$amount · $count ví';
  }

  @override
  String get walletSort => 'Sắp xếp';

  @override
  String get walletSortTitle => 'Sắp xếp ví';

  @override
  String get walletSortHint => 'Giữ và kéo, hoặc dùng mũi tên.';

  @override
  String get walletSortDone => 'Xong';

  @override
  String walletMoveUpNamed(String name) {
    return 'Đưa $name lên';
  }

  @override
  String walletMoveDownNamed(String name) {
    return 'Đưa $name xuống';
  }

  @override
  String get walletSortFailed => 'Chưa lưu được thứ tự. Thử lại nhé.';

  @override
  String get walletHiddenTitle => 'Ví đã ẩn';

  @override
  String get walletHiddenHint =>
      'Lịch sử vẫn giữ, khôi phục lúc nào cũng được.';

  @override
  String get walletRestoreShort => 'Khôi phục';

  @override
  String walletRestored(String name) {
    return 'Đã khôi phục $name';
  }

  @override
  String walletRestoreNamed(String name) {
    return 'Khôi phục $name';
  }

  @override
  String walletDueOn(String date) {
    return 'đến hạn $date';
  }

  @override
  String walletTypeCurrency(String type, String currency) {
    return '$type · $currency';
  }

  @override
  String walletMonthIn(String month) {
    return 'Vào tháng $month';
  }

  @override
  String walletMonthOut(String month) {
    return 'Ra tháng $month';
  }

  @override
  String get walletRecordFrom => 'Ghi từ ví này';

  @override
  String get walletTransfer => 'Chuyển ví';

  @override
  String get walletEditCard => 'Sửa thẻ';

  @override
  String get walletNoTransactions => 'Chưa có giao dịch';

  @override
  String get walletNoTransactionsBody => 'Ghi khoản đầu tiên từ ví này.';

  @override
  String get creditNoTransactionsBody => 'Ghi khoản đầu tiên từ thẻ này.';

  @override
  String get walletNotFound => 'Không tìm thấy ví này';

  @override
  String get walletEmptyTitle => 'Chưa có ví';

  @override
  String get walletEmptyBody => 'Thêm ví đầu tiên để bắt đầu ghi.';

  @override
  String get creditDebtLabel => 'Dư nợ · Thẻ tín dụng';

  @override
  String get creditAvailableLabel => 'Còn dùng được';

  @override
  String creditLimit(String amount) {
    return 'Hạn mức $amount';
  }

  @override
  String get creditDueTitle => 'Đến hạn thanh toán';

  @override
  String creditDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'còn $count ngày',
      zero: 'hôm nay',
    );
    return '$_temp0';
  }

  @override
  String get creditCloseTitle => 'Ngày chốt sao kê';

  @override
  String creditCloseValue(int day) {
    return 'Ngày $day hằng tháng';
  }

  @override
  String get creditNotSet => 'Chưa đặt';

  @override
  String get creditRecordFrom => 'Ghi từ thẻ này';

  @override
  String get creditPay => 'Trả thẻ';

  @override
  String get walletLoadError => 'Chưa tải được ví';

  @override
  String get cardName => 'Tên thẻ';

  @override
  String get walletCurrencyField => 'Tiền tệ';

  @override
  String get walletCurrencyTitle => 'Chọn tiền tệ';

  @override
  String get walletCurrentBalance => 'Số dư hiện tại';

  @override
  String get walletBalanceHint => 'Nhập số gần đúng, có thể sửa lại sau.';

  @override
  String get creditCurrentDebt => 'Dư nợ hiện tại';

  @override
  String get creditInitialDebt => 'Dư nợ ban đầu';

  @override
  String get creditLimitField => 'Hạn mức';

  @override
  String get creditMinimumField => 'Số trả tối thiểu';

  @override
  String get creditMinimumTitle => 'Số trả tối thiểu';

  @override
  String get creditCloseField => 'Ngày chốt';

  @override
  String get creditDueField => 'Đến hạn';

  @override
  String creditDayValue(int day) {
    return 'Ngày $day';
  }

  @override
  String get creditPickDay => 'Chọn ngày';

  @override
  String get creditOptionalHint =>
      'Hạn mức, số trả tối thiểu và ngày có thể để trống.';

  @override
  String get walletSave => 'Lưu ví';

  @override
  String get creditSave => 'Lưu thẻ';

  @override
  String get walletSaveChanges => 'Lưu thay đổi';

  @override
  String get walletLockedLabel => 'Loại ví · Tiền tệ';

  @override
  String walletLockedSemantics(String type, String currency) {
    return '$type, $currency, đã khoá vì ví có giao dịch';
  }

  @override
  String walletHiddenToast(String name) {
    return 'Đã ẩn $name';
  }

  @override
  String get walletNameMissing => 'Đặt tên cho ví nhé.';

  @override
  String get walletAmountInvalid => 'Số tiền chưa đúng.';

  @override
  String get dayDueTitle => 'Đến hạn ngày nào?';

  @override
  String get dayCloseTitle => 'Chốt sao kê ngày nào?';

  @override
  String get dayMonthly => 'Hằng tháng';

  @override
  String dayConfirm(int day) {
    return 'Chọn ngày $day';
  }

  @override
  String get dayClear => 'Để trống';

  @override
  String get dayCloseMark => 'Ngày chốt';

  @override
  String get dayDueMark => 'Ngày đến hạn';

  @override
  String dayMarkedSemantics(int day, String mark) {
    return '$day, $mark';
  }

  @override
  String get categoryTabExpense => 'Chi';

  @override
  String get categoryTabIncome => 'Thu';

  @override
  String get categoryTabs => 'Loại danh mục';

  @override
  String categoryChildCount(int count) {
    return '$count danh mục con';
  }

  @override
  String categoryToggleSemantics(String name) {
    return '$name: mở hoặc thu danh mục con';
  }

  @override
  String get categoryHiddenTitle => 'Danh mục đã ẩn';

  @override
  String get categoryHiddenHint => 'Giao dịch cũ vẫn giữ danh mục này.';

  @override
  String get categoryRestoreShort => 'Khôi phục';

  @override
  String categoryRestoreNamed(String name) {
    return 'Khôi phục $name';
  }

  @override
  String categoryRestored(String name) {
    return 'Đã khôi phục $name';
  }

  @override
  String get categoryEmptyTitle => 'Chưa có danh mục';

  @override
  String get categoryEmptyBody => 'Thêm một danh mục để bắt đầu.';

  @override
  String get categoryLoadError => 'Chưa tải được danh mục';

  @override
  String get categoryIconFood => 'Ăn uống';

  @override
  String get categoryIconCoffee => 'Cà phê';

  @override
  String get categoryIconGroceries => 'Đi chợ';

  @override
  String get categoryIconShopping => 'Mua sắm';

  @override
  String get categoryIconClothes => 'Quần áo';

  @override
  String get categoryIconGifts => 'Quà tặng';

  @override
  String get categoryIconTransport => 'Ô tô, xe máy';

  @override
  String get categoryIconBus => 'Xe buýt';

  @override
  String get categoryIconFuel => 'Xăng';

  @override
  String get categoryIconTravel => 'Du lịch';

  @override
  String get categoryIconHousing => 'Nhà';

  @override
  String get categoryIconRepair => 'Sửa chữa';

  @override
  String get categoryIconElectricity => 'Điện';

  @override
  String get categoryIconWater => 'Nước';

  @override
  String get categoryIconInternet => 'Internet';

  @override
  String get categoryIconPhone => 'Điện thoại';

  @override
  String get categoryIconHealth => 'Sức khỏe';

  @override
  String get categoryIconMedicine => 'Thuốc';

  @override
  String get categoryIconSports => 'Thể thao';

  @override
  String get categoryIconFamily => 'Gia đình';

  @override
  String get categoryIconPets => 'Thú cưng';

  @override
  String get categoryIconBeauty => 'Làm đẹp';

  @override
  String get categoryIconEducation => 'Học tập';

  @override
  String get categoryIconBooks => 'Sách';

  @override
  String get categoryIconMusic => 'Âm nhạc';

  @override
  String get categoryIconEntertainment => 'Phim';

  @override
  String get categoryIconGames => 'Trò chơi';

  @override
  String get categoryIconSalary => 'Lương';

  @override
  String get categoryIconBonus => 'Thưởng';

  @override
  String get categoryIconInvestment => 'Đầu tư';

  @override
  String get categoryIconWork => 'Công việc';

  @override
  String get categoryIconOtherIncome => 'Tiết kiệm';

  @override
  String get categoryIconBills => 'Thuế, phí';

  @override
  String get categoryIconInsurance => 'Bảo hiểm';

  @override
  String get categoryIconSubscription => 'Gói định kỳ';

  @override
  String get categoryIconOtherExpense => 'Khác';

  @override
  String get categoryColorNone => 'Không màu';

  @override
  String get categoryColorBrandPrimary => 'Xanh dương';

  @override
  String get categoryColorBlueDeep => 'Xanh dương đậm';

  @override
  String get categoryColorBrandSecondary => 'Xanh trời';

  @override
  String get categoryColorOceanDeep => 'Xanh biển đậm';

  @override
  String get categoryColorBrandAccent => 'Tím';

  @override
  String get categoryColorVioletDeep => 'Tím đậm';

  @override
  String get categoryColorSuccess => 'Xanh lá';

  @override
  String get categoryColorWarning => 'Vàng';

  @override
  String get categoryColorBlueLight => 'Xanh dương nhạt';

  @override
  String get categoryColorBrandHighlight => 'Xanh trời nhạt';

  @override
  String get categoryColorVioletLight => 'Tím nhạt';

  @override
  String get categoryColorGreenLight => 'Xanh lá nhạt';

  @override
  String get categoryColorYellowLight => 'Vàng nhạt';

  @override
  String get categoryColorPink => 'Hồng';

  @override
  String get categoryColorOrange => 'Cam';

  @override
  String get categoryColorBrown => 'Nâu';

  @override
  String get categoryColorLime => 'Xanh chanh';

  @override
  String get categoryColorOlive => 'Ô liu';

  @override
  String get categoryColorPlum => 'Mận';

  @override
  String get categoryColorGray => 'Xám';

  @override
  String get categoryIconGroupFood => 'Ăn uống · mua sắm';

  @override
  String get categoryIconGroupHome => 'Đi lại · nhà cửa';

  @override
  String get categoryIconGroupLife => 'Sức khỏe · gia đình · giải trí';

  @override
  String get categoryIconGroupMoney => 'Thu nhập · tài chính';

  @override
  String get categoryLevelMain => 'Danh mục chính';

  @override
  String get categoryLevelChild => 'Danh mục con';

  @override
  String get categoryParentField => 'Thuộc';

  @override
  String get categoryPickParent => 'Chọn danh mục chính';

  @override
  String get categoryParentSheet => 'Thuộc danh mục chính';

  @override
  String get categoryParentMissing => 'Chọn danh mục chính nhé.';

  @override
  String get categoryNameMissing => 'Đặt tên cho danh mục nhé.';

  @override
  String get categoryMoreIcons => 'Thêm biểu tượng';

  @override
  String get categoryIconSearch => 'Tìm: xăng, thú cưng…';

  @override
  String get categoryIconSearchLabel => 'Tìm biểu tượng';

  @override
  String get categoryIconDone => 'Xong';

  @override
  String get categoryIconNoMatch => 'Không thấy biểu tượng nào.';

  @override
  String get categorySave => 'Lưu danh mục';

  @override
  String get categorySaveChanges => 'Lưu thay đổi';

  @override
  String get categoryHideShort => 'Ẩn';

  @override
  String get categoryDeleteShort => 'Xoá';

  @override
  String categoryChildrenBlock(int count) {
    return 'Còn $count danh mục con';
  }

  @override
  String categoryHiddenToast(String name) {
    return 'Đã ẩn $name';
  }

  @override
  String categoryDeletedToast(String name) {
    return 'Đã xoá $name';
  }

  @override
  String categoryDeleteQuestion(String name) {
    return 'Xoá “$name”?';
  }

  @override
  String get categoryDeleteNoUndo => 'Không khôi phục được.';

  @override
  String categoryDeleteMove(int count) {
    return 'Không khôi phục được. $count giao dịch sẽ chuyển sang:';
  }

  @override
  String get categoryMoveTo => 'Chuyển giao dịch sang';

  @override
  String get reportYear => 'Năm';

  @override
  String reportYearTitle(String year) {
    return 'Năm $year';
  }

  @override
  String get reportMonthTitlePattern => '\'Tháng\' M, yyyy';

  @override
  String get reportShortDatePattern => 'dd/MM';

  @override
  String reportRangeDays(int count) {
    return '$count ngày';
  }

  @override
  String get reportAverageDay => 'Chi trung bình/ngày';

  @override
  String get reportRemaining => 'Còn lại';

  @override
  String reportVsMonth(String month) {
    return 'so với T$month';
  }

  @override
  String get reportVsWeek => 'so với tuần trước';

  @override
  String reportVsYear(String year) {
    return 'so với $year';
  }

  @override
  String get reportVsPeriod => 'so với kỳ trước';

  @override
  String reportChange(String percent, String versus) {
    return '$percent% $versus';
  }

  @override
  String get reportBudgetSet => 'Đặt ngân sách tháng';

  @override
  String get reportBudgetSoon => 'Ngân sách sắp có';

  @override
  String get reportTrendTitle => 'Xu hướng chi';

  @override
  String reportTrendAverageWeeks(int count) {
    return 'Trung bình $count tuần';
  }

  @override
  String reportTrendAverageMonths(int count) {
    return 'Trung bình $count tháng';
  }

  @override
  String reportTrendAverageYears(int count) {
    return 'Trung bình $count năm';
  }

  @override
  String get reportViewExpense => 'Chi';

  @override
  String get reportViewIncome => 'Thu';

  @override
  String get reportViewWallet => 'Ví';

  @override
  String get reportOther => 'Khác';

  @override
  String reportOtherCount(int count) {
    return 'Khác · $count danh mục';
  }

  @override
  String reportFlowIn(String amount) {
    return 'Vào +$amount';
  }

  @override
  String reportFlowOut(String amount) {
    return 'Ra −$amount';
  }

  @override
  String reportFlowTransfer(String amount) {
    return 'Chuyển ví $amount';
  }

  @override
  String reportEmptyTitle(String period) {
    return 'Chưa có số liệu $period';
  }

  @override
  String get reportEmptyHint => 'Ghi giao dịch để thấy số liệu.';

  @override
  String get reportBackWeek => 'Về tuần này';

  @override
  String get reportBackMonth => 'Về tháng này';

  @override
  String get reportBackYear => 'Về năm nay';

  @override
  String get reportUnitThousand => 'k';

  @override
  String get reportUnitMillion => 'tr';

  @override
  String get reportUnitBillion => 'tỷ';

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
    return 'Chi $count kỳ gần nhất: $items';
  }

  @override
  String reportMonthShort(String month) {
    return 'T$month';
  }

  @override
  String get reportRangeTitle => 'Chọn khoảng ngày';

  @override
  String get reportQuick7 => '7 ngày qua';

  @override
  String get reportQuick30 => '30 ngày qua';

  @override
  String get reportQuickQuarter => 'Quý này';

  @override
  String get reportWeekdays => 'T2,T3,T4,T5,T6,T7,CN';

  @override
  String get reportRangePickStart => 'Chọn ngày đầu';

  @override
  String get reportRangePickEnd => 'Chọn ngày cuối';

  @override
  String reportDayFrom(String date) {
    return 'Từ $date';
  }

  @override
  String reportDayTo(String date) {
    return 'Đến $date';
  }

  @override
  String reportDayToday(String date) {
    return 'Hôm nay, $date';
  }

  @override
  String reportShareExpense(String percent) {
    return '$percent% tổng chi';
  }

  @override
  String reportShareIncome(String percent) {
    return '$percent% tổng thu';
  }

  @override
  String reportShareCount(String share, int count) {
    return '$share · $count giao dịch';
  }

  @override
  String get reportLargest => 'Giao dịch lớn nhất';

  @override
  String reportSeeAll(int count) {
    return 'Xem cả $count';
  }

  @override
  String get reportLargestError => 'Không tải được giao dịch';

  @override
  String get meTitle => 'Cá nhân';

  @override
  String get meGroupFinance => 'Thiết lập tài chính';

  @override
  String get meGroupApp => 'Ứng dụng';

  @override
  String get meGroupHelp => 'Hỗ trợ';

  @override
  String get meWallets => 'Ví của tôi';

  @override
  String get meCategories => 'Danh mục';

  @override
  String get meTags => 'Nhãn';

  @override
  String get meRecurring => 'Định kỳ';

  @override
  String get meBills => 'Hóa đơn';

  @override
  String get meCalendar => 'Lịch tài chính';

  @override
  String get meCurrency => 'Tiền tệ mặc định';

  @override
  String get calendarTitle => 'Lịch tài chính';

  @override
  String get calendarLoadError => 'Không tải được lịch';

  @override
  String get calendarEmptyTitle => 'Tháng này trống';

  @override
  String get calendarEmptyBody =>
      'Chưa có giao dịch, định kỳ hay hóa đơn trong tháng này.';

  @override
  String get calendarPrevMonth => 'Tháng trước';

  @override
  String get calendarNextMonth => 'Tháng sau';

  @override
  String get calendarSectionTransactions => 'Giao dịch';

  @override
  String get calendarSectionRecurring => 'Định kỳ';

  @override
  String get calendarSectionBills => 'Hóa đơn';

  @override
  String get calendarLegend => 'Chấm màu theo loại mục trên ngày';

  @override
  String get calendarTransfer => 'Chuyển khoản';

  @override
  String get calendarEstimated => 'Ước tính';

  @override
  String get billsTitle => 'Hóa đơn';

  @override
  String get billsAdd => 'Thêm hóa đơn';

  @override
  String get billsEdit => 'Sửa hóa đơn';

  @override
  String get billsDelete => 'Xóa';

  @override
  String get billsSave => 'Lưu';

  @override
  String get billsEmptyTitle => 'Chưa có hóa đơn';

  @override
  String get billsEmptyBody =>
      'Theo dõi hạn điện, nước, internet. Đánh dấu đã trả bằng một giao dịch có sẵn.';

  @override
  String get billsLoadError => 'Không tải được hóa đơn';

  @override
  String get billsName => 'Tên';

  @override
  String get billsAmount => 'Số tiền';

  @override
  String get billsAmountFixed => 'Cố định';

  @override
  String get billsAmountEstimated => 'Ước tính';

  @override
  String get billsDueOn => 'Hạn (YYYY-MM-DD)';

  @override
  String get billsRecurring => 'Gắn định kỳ';

  @override
  String get billsOneOff => 'Một lần';

  @override
  String get billsLinkedRecurring => 'Đã gắn định kỳ';

  @override
  String get billsFilterAll => 'Tất cả';

  @override
  String get billsStatusOpen => 'Mở';

  @override
  String get billsStatusOverdue => 'Quá hạn';

  @override
  String get billsStatusPaid => 'Đã trả';

  @override
  String get billsMarkPaid => 'Đánh dấu đã trả';

  @override
  String get billsUnpay => 'Bỏ đánh dấu đã trả';

  @override
  String get billsPickTransaction => 'Chọn giao dịch';

  @override
  String get billsNoTransactions => 'Chưa có giao dịch để gắn';

  @override
  String get billsMarkedPaid => 'Đã gắn giao dịch thanh toán';

  @override
  String get billsClearedPaid => 'Đã bỏ đánh dấu đã trả';

  @override
  String get billsInvalid => 'Nhập tên và số tiền hợp lệ';

  @override
  String get recurringTitle => 'Giao dịch định kỳ';

  @override
  String get recurringAdd => 'Thêm định kỳ';

  @override
  String get recurringEdit => 'Sửa định kỳ';

  @override
  String get recurringDelete => 'Xóa';

  @override
  String get recurringSave => 'Lưu';

  @override
  String get recurringEmptyTitle => 'Chưa có định kỳ';

  @override
  String get recurringEmptyBody =>
      'Thiết lập tiền thuê, lương hoặc chuyển khoản một lần; Freeva sẽ ghi đúng lịch.';

  @override
  String get recurringLoadError => 'Không tải được định kỳ';

  @override
  String get recurringAmount => 'Số tiền';

  @override
  String get recurringWallet => 'Ví';

  @override
  String get recurringCounterWallet => 'Ví nhận';

  @override
  String get recurringCategory => 'Danh mục';

  @override
  String get recurringFrequency => 'Chu kỳ';

  @override
  String get recurringInterval => 'Mỗi';

  @override
  String recurringEvery(String count) {
    return 'Mỗi $count';
  }

  @override
  String get recurringUnitDay => 'Ngày';

  @override
  String get recurringUnitWeek => 'Tuần';

  @override
  String get recurringUnitMonth => 'Tháng';

  @override
  String get recurringUnitYear => 'Năm';

  @override
  String get recurringStart => 'Ngày bắt đầu (YYYY-MM-DD)';

  @override
  String get recurringNextLabel => 'Lần tới (YYYY-MM-DD)';

  @override
  String get recurringEnd => 'Ngày kết thúc (tuỳ chọn)';

  @override
  String get recurringActive => 'Đang bật';

  @override
  String recurringNext(String date) {
    return 'Tới $date';
  }

  @override
  String get recurringTypeExpense => 'Chi';

  @override
  String get recurringTypeIncome => 'Thu';

  @override
  String get recurringTypeTransfer => 'Chuyển';

  @override
  String get meBudget => 'Ngân sách tháng';

  @override
  String get budgetTitle => 'Ngân sách tháng';

  @override
  String get budgetSave => 'Lưu';

  @override
  String get budgetSaved => 'Đã lưu ngân sách';

  @override
  String get budgetCleared => 'Đã xoá ngân sách';

  @override
  String get budgetLoadError => 'Chưa tải được ngân sách';

  @override
  String get budgetOverallLimit => 'Hạn mức tháng';

  @override
  String get budgetCategoryLimit => 'Hạn mức danh mục';

  @override
  String get budgetTapToSet => 'Chạm để đặt';

  @override
  String get budgetCategoriesTitle => 'Theo danh mục';

  @override
  String get budgetCategoriesHint =>
      'Tuỳ chọn: đặt hạn mức cho từng danh mục chi.';

  @override
  String get budgetAddCategory => 'Thêm danh mục';

  @override
  String get budgetNoCategories => 'Không còn danh mục chi để thêm';

  @override
  String get budgetUnknownCategory => 'Danh mục';

  @override
  String get budgetClearTitle => 'Xoá ngân sách?';

  @override
  String get budgetClearBody =>
      'Thanh đã chi trên Tổng quan sẽ ẩn đi đến khi bạn đặt lại.';

  @override
  String get budgetClearAction => 'Xoá ngân sách';

  @override
  String get budgetSpentLabel => 'Đã chi';

  @override
  String get budgetRemainingLabel => 'Còn lại';

  @override
  String budgetUsedPercent(String percent) {
    return 'Đã dùng $percent%';
  }

  @override
  String budgetLimitLine(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get budgetThresholdsTitle => 'Ngưỡng cảnh báo';

  @override
  String get budgetScopeDefault => 'Mọi tháng';

  @override
  String get budgetScopeMonth => 'Tháng này';

  @override
  String get budgetScopeMonthHint =>
      'Đang dùng hạn mức mặc định. Lưu sẽ tạo chỉnh riêng cho tháng này.';

  @override
  String get budgetScopeMonthOverrideHint =>
      'Tháng này có hạn mức riêng, không theo mặc định.';

  @override
  String get budgetClearMonthTitle => 'Bỏ chỉnh tháng này?';

  @override
  String get budgetClearMonthBody =>
      'Tháng này sẽ lại dùng hạn mức mặc định (nếu có).';

  @override
  String get budgetClearMonthAction => 'Bỏ chỉnh tháng';

  @override
  String get budgetMonthCleared => 'Đã bỏ chỉnh tháng này';

  @override
  String get budgetStatusHealthy => 'Đúng nhịp';

  @override
  String get budgetStatusWarning => 'Hơi nhanh';

  @override
  String get budgetStatusCritical => 'Gần hết';

  @override
  String get budgetStatusOver => 'Vượt ngân sách';

  @override
  String budgetHomeLine(String spent, String limit) {
    return 'Đã chi $spent / $limit';
  }

  @override
  String get meFiscal => 'Tháng tính từ';

  @override
  String meFiscalDay(int day) {
    return 'Ngày $day';
  }

  @override
  String get meGoals => 'Mục tiêu';

  @override
  String get meTheme => 'Giao diện';

  @override
  String get meThemeLight => 'Sáng';

  @override
  String get meThemeDark => 'Tối';

  @override
  String get meThemeSystem => 'Theo máy';

  @override
  String get meLanguage => 'Ngôn ngữ';

  @override
  String get meTimezone => 'Múi giờ';

  @override
  String get meNotifications => 'Thông báo';

  @override
  String get meHideBalances => 'Ẩn số dư';

  @override
  String get meSecurity => 'Bảo mật';

  @override
  String get meSecurityValueBiometric => 'PIN · Sinh trắc';

  @override
  String get meSecurityValuePin => 'PIN';

  @override
  String get meFaq => 'Câu hỏi thường gặp';

  @override
  String get meFeedback => 'Góp ý';

  @override
  String get meSoon => 'Sắp có';

  @override
  String get meLogout => 'Đăng xuất';

  @override
  String get meLogoutTitle => 'Đăng xuất khỏi máy này?';

  @override
  String get meLogoutBody => 'Dữ liệu vẫn nằm trong tài khoản của bạn.';

  @override
  String get meProfileTitle => 'Hồ sơ';

  @override
  String get meProfileName => 'Tên hiển thị';

  @override
  String get meProfileEmail => 'Email';

  @override
  String get meChange => 'Đổi';

  @override
  String get meSave => 'Lưu thay đổi';

  @override
  String get meSaved => 'Đã lưu';

  @override
  String get meSaveError => 'Chưa lưu được. Thử lại nhé.';

  @override
  String get meConflict =>
      'Đã thay đổi trên máy khác. Tải lại rồi thử lại nhé.';

  @override
  String meAvatarSemantics(String letter) {
    return 'Ảnh đại diện, chữ $letter';
  }

  @override
  String get meSecUnlock => 'Mở khoá';

  @override
  String get meSecPin => 'Khoá bằng mã PIN';

  @override
  String get meSecPinSub => 'Khi mở lại Freeva';

  @override
  String get meSecBiometric => 'Mở bằng sinh trắc';

  @override
  String get meSecChangePin => 'Đổi mã PIN';

  @override
  String get meSecLogin => 'Đăng nhập';

  @override
  String get meSecSessions => 'Phiên đăng nhập';

  @override
  String get meSecChangePassword => 'Đổi mật khẩu';

  @override
  String get meSessionsHint => 'Không nhận ra phiên nào thì thu hồi ngay.';

  @override
  String get meSessionThis => 'Máy này';

  @override
  String get meSessionOther => 'Phiên khác';

  @override
  String get meSessionInUse => 'Đang dùng';

  @override
  String meSessionDates(String from, String to) {
    return 'Từ $from · hết hạn $to';
  }

  @override
  String get meRevoke => 'Thu hồi';

  @override
  String meRevokeSemantics(String date) {
    return 'Thu hồi phiên đăng nhập ngày $date';
  }

  @override
  String get meRevokeTitle => 'Thu hồi phiên này?';

  @override
  String get meRevokeBody => 'Máy đó sẽ bị đăng xuất.';

  @override
  String get meRevokeOthers => 'Đăng xuất mọi máy khác';

  @override
  String get meRevokeOthersTitle => 'Đăng xuất mọi máy khác?';

  @override
  String get meRevokeOthersBody => 'Máy này vẫn đăng nhập.';

  @override
  String get meChangePinTitle => 'Đổi mã PIN';

  @override
  String get mePinCurrent => 'Mã PIN hiện tại';

  @override
  String get mePinNew => 'Mã PIN mới';

  @override
  String get mePinRepeat => 'Nhập lại mã PIN mới';

  @override
  String get mePinWrong =>
      'Mã PIN chưa đúng. Sai 5 lần thì phải đăng nhập lại.';

  @override
  String get mePinMismatch => 'Hai mã PIN mới chưa khớp.';

  @override
  String get mePinSame => 'Chọn mã PIN khác mã cũ nhé.';

  @override
  String get mePinInvalid => 'Mã PIN gồm 6 chữ số.';

  @override
  String get mePinChanged => 'Đã đổi mã PIN';

  @override
  String get meChangePasswordTitle => 'Đổi mật khẩu';

  @override
  String get mePasswordCurrent => 'Mật khẩu hiện tại';

  @override
  String get mePasswordNew => 'Mật khẩu mới';

  @override
  String get mePasswordRepeat => 'Nhập lại mật khẩu mới';

  @override
  String get mePasswordHint => 'Từ 12 ký tự, có cả chữ và số.';

  @override
  String get mePasswordWrong => 'Mật khẩu hiện tại chưa đúng.';

  @override
  String get mePasswordWeak =>
      'Dùng từ 12 ký tự, có cả chữ và số, khác mật khẩu cũ.';

  @override
  String get mePasswordMismatch => 'Hai mật khẩu mới chưa khớp.';

  @override
  String get mePasswordChanged => 'Đã đổi mật khẩu. Các máy khác đã đăng xuất.';

  @override
  String meBusyRetry(int minutes) {
    return 'Thử lại sau $minutes phút nhé.';
  }

  @override
  String get meNetworkError => 'Chưa kết nối được. Kiểm tra mạng nhé.';

  @override
  String get meSecAlways => 'Luôn bật';

  @override
  String get tagsSearch => 'Tìm nhãn';

  @override
  String get tagsAdd => 'Tạo nhãn';

  @override
  String get tagsName => 'Tên nhãn';

  @override
  String get tagsRenameTitle => 'Đổi tên nhãn';

  @override
  String get tagsRename => 'Đổi tên';

  @override
  String get tagsDelete => 'Xoá';

  @override
  String tagsDeleteTitle(String name) {
    return 'Xoá nhãn “$name”?';
  }

  @override
  String get tagsDeleteBody => 'Giao dịch vẫn còn, chỉ gỡ nhãn này.';

  @override
  String get tagsEmptyTitle => 'Chưa có nhãn nào';

  @override
  String get tagsEmptyBody => 'Gắn nhãn để gom giao dịch theo cách của bạn.';

  @override
  String get tagsNoMatch => 'Không có nhãn khớp';

  @override
  String get tagsLoadError => 'Không tải được nhãn';

  @override
  String tagsRowSemantics(String name, int count) {
    return '$name, $count giao dịch';
  }

  @override
  String tagsMore(String name) {
    return 'Tác vụ cho $name';
  }

  @override
  String get fbHeading => 'Bạn muốn nói gì với Freeva?';

  @override
  String get fbKindBug => 'Lỗi';

  @override
  String get fbKindIdea => 'Ý tưởng';

  @override
  String get fbKindPraise => 'Lời khen';

  @override
  String get fbAbout => 'Về phần nào?';

  @override
  String get fbTopicRecord => 'Ghi chi';

  @override
  String get fbTopicReports => 'Báo cáo';

  @override
  String get fbTopicWallets => 'Ví';

  @override
  String get fbTopicCategories => 'Danh mục';

  @override
  String get fbTopicAppearance => 'Giao diện';

  @override
  String get fbTopicOther => 'Khác';

  @override
  String get fbLabelBug => 'Bạn gặp lỗi gì?';

  @override
  String get fbLabelIdea => 'Ý tưởng của bạn';

  @override
  String get fbLabelPraise => 'Bạn thích điều gì?';

  @override
  String fbCount(int count) {
    return '$count/2000';
  }

  @override
  String get fbReply => 'Trả lời tôi qua email';

  @override
  String get fbSend => 'Gửi góp ý';

  @override
  String get fbSending => 'Đang gửi…';

  @override
  String get fbThanks => 'Cảm ơn bạn!';

  @override
  String get fbThanksReply => 'Freeva sẽ đọc và trả lời qua email.';

  @override
  String get fbThanksNoReply => 'Freeva sẽ đọc từng góp ý.';

  @override
  String get fbDone => 'Xong';

  @override
  String get fbError => 'Chưa gửi được. Thử lại nhé.';

  @override
  String get faqSearch => 'Tìm câu hỏi';

  @override
  String get faqNoMatch => 'Không có câu hỏi khớp';

  @override
  String get faqMissing => 'Chưa thấy câu trả lời?';

  @override
  String get faqSend => 'Gửi góp ý cho Freeva';

  @override
  String get notifyReminders => 'Nhắc nhở';

  @override
  String get notifyAlerts => 'Cảnh báo';

  @override
  String get notifyRecord => 'Nhắc ghi chi';

  @override
  String get notifyRecordSub => 'Mỗi ngày';

  @override
  String get notifyDigest => 'Tổng kết chi tiêu';

  @override
  String get notifyDigestSub => 'Mỗi tuần hoặc mỗi tháng';

  @override
  String get notifyBudget => 'Ngân sách sắp hết';

  @override
  String get notifyBudgetSub => 'Khi dùng 80% và 100%';

  @override
  String get notifyCard => 'Thẻ tín dụng';

  @override
  String get notifyCardSub => 'Sắp đến hạn, dư nợ cao và sắp vượt hạn mức';

  @override
  String get notifySession => 'Máy mới đăng nhập';

  @override
  String get notifyRecurring => 'Định kỳ sắp chạy';

  @override
  String get notifyRecurringSub => 'Một ngày trước lần chạy';

  @override
  String get notifyGoal => 'Nhắc đóng góp mục tiêu';

  @override
  String get notifyGoalSub => 'Khi đến hạn đóng góp';

  @override
  String get notifyDebt => 'Nợ đến hạn';

  @override
  String get notifyDebtSub => 'Trước ngày đến hạn';

  @override
  String get notifyMonthReview => 'Soát tháng';

  @override
  String get notifyMonthReviewSub => 'Khi có bản tóm tắt tháng';

  @override
  String get notifyInsight => 'Insight mới';

  @override
  String get notifyInsightSub => 'Khi có gợi ý mới';

  @override
  String get notifyQuietTitle => 'Giờ yên';

  @override
  String get notifyQuietHours => 'Bật giờ yên';

  @override
  String get notifyQuietEdit => 'Khung giờ';

  @override
  String get notifyQuietStart => 'Bắt đầu giờ yên';

  @override
  String get notifyQuietEnd => 'Hết giờ yên';

  @override
  String notifyQuietWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String get notifyMarkAllRead => 'Đọc hết';

  @override
  String notifyInboxBudgetTitle(String threshold) {
    return 'Ngân sách đã chạm $threshold%';
  }

  @override
  String notifyInboxBudgetBody(String threshold) {
    return 'Bạn đã dùng đến $threshold% hạn mức tháng này.';
  }

  @override
  String get notifyInboxRecurringTitle => 'Định kỳ sắp chạy';

  @override
  String notifyInboxRecurringBody(String date) {
    return 'Một giao dịch định kỳ chạy vào $date.';
  }

  @override
  String get notifyInboxCardDueTitle => 'Thẻ sắp đến hạn';

  @override
  String notifyInboxCardDueBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Thẻ đến hạn trong $count ngày.',
      one: 'Thẻ đến hạn trong 1 ngày.',
      zero: 'Thẻ đến hạn hôm nay.',
    );
    return '$_temp0';
  }

  @override
  String get notifyInboxCardHighDebtTitle => 'Dư nợ thẻ cao';

  @override
  String notifyInboxCardHighDebtBody(String threshold) {
    return 'Bạn đã dùng đến $threshold% hạn mức thẻ.';
  }

  @override
  String get notifyInboxCardNearLimitTitle => 'Thẻ sắp vượt hạn mức';

  @override
  String notifyInboxCardNearLimitBody(String threshold) {
    return 'Bạn đã dùng đến $threshold% hạn mức thẻ.';
  }

  @override
  String get authOr => 'hoặc';

  @override
  String get authContinueGoogle => 'Tiếp tục với Google';

  @override
  String get authContinueApple => 'Tiếp tục với Apple';

  @override
  String get authNoAccount => 'Chưa có tài khoản?';

  @override
  String get authHaveAccount => 'Đã có tài khoản?';

  @override
  String get authLaterLink => 'Để sau';

  @override
  String get authDone => 'Xong';

  @override
  String authVerifySent(String email) {
    return 'Freeva đã gửi link xác nhận tới $email.';
  }

  @override
  String get authVerifyWhyTitle => 'Email đã xác nhận giúp bạn';

  @override
  String get authVerifyWhyReset => 'Lấy lại mật khẩu khi quên';

  @override
  String get authVerifyWhyAlert => 'Nhận cảnh báo khi có đăng nhập lạ';

  @override
  String get authVerifyWhyNotice =>
      'Không lỡ thông báo quan trọng về tài khoản';

  @override
  String get authResendPrompt => 'Chưa nhận được?';

  @override
  String get authResendLink => 'Gửi lại';

  @override
  String get authVerificationSent => 'Đã gửi lại link xác nhận.';

  @override
  String get authVerifyLater =>
      'Chưa xác nhận vẫn dùng app bình thường. Bạn có thể xác nhận sau ở Cá nhân.';

  @override
  String get authSendResetLink => 'Gửi link đặt lại';

  @override
  String get authResetSentTitle => 'Kiểm tra email';

  @override
  String authResetSent(String email) {
    return 'Nếu $email có tài khoản, Freeva đã gửi link đặt lại.';
  }

  @override
  String get authBackToLogin => 'Về đăng nhập';

  @override
  String get authConfirmNewPassword => 'Nhập lại mật khẩu mới';

  @override
  String get authSaveAndLogin => 'Lưu và đăng nhập';

  @override
  String get authSocialSoon => 'Sắp có';

  @override
  String get passwordWeak => 'Chưa đủ';

  @override
  String get passwordGood => 'Khá tốt';

  @override
  String get passwordStrong => 'Rất chắc chắn';

  @override
  String get passwordRuleLength => 'Ít nhất 12 ký tự';

  @override
  String get passwordRuleLetterDigit => 'Có cả chữ và số';

  @override
  String get passwordRuleSymbol => 'Thêm ký hiệu như ! @ # để mạnh hơn';

  @override
  String get passwordRuleMatch => 'Hai mật khẩu khớp nhau';

  @override
  String get passwordRuleMet => 'đã đạt';

  @override
  String get passwordRuleNotMet => 'chưa đạt';

  @override
  String get consentLabel => 'Đồng ý điều khoản';

  @override
  String get consentPrefix => 'Tôi đồng ý với ';

  @override
  String get consentTerms => 'Điều khoản sử dụng';

  @override
  String get consentAnd => ' và ';

  @override
  String get consentPrivacy => 'Chính sách bảo mật';

  @override
  String get consentSuffix => ' của Freeva.';

  @override
  String get authPinSetupTitle => 'Đặt mã PIN';

  @override
  String get authPinSetupSub => '6 số để mở khoá Freeva trên máy này.';

  @override
  String get authPinConfirmTitle => 'Nhập lại mã PIN';

  @override
  String get authPinConfirmSub => 'Nhập lại 6 số vừa đặt để chắc chắn.';

  @override
  String get authPinConfirmHint => 'Không khớp sẽ được nhập lại từ đầu.';

  @override
  String get authPinMismatch => 'Hai mã chưa khớp. Đặt lại từ đầu nhé.';

  @override
  String get authConfirm => 'Xác nhận';

  @override
  String get authBiometricTitleFace => 'Thiết lập Face ID';

  @override
  String get authBiometricSubFace =>
      'Mở khoá Freeva bằng khuôn mặt, nhanh hơn nhập PIN.';

  @override
  String get authBiometricTitle => 'Mở khoá nhanh hơn';

  @override
  String get authBiometricSub =>
      'Dùng vân tay hoặc khuôn mặt thay cho nhập PIN.';

  @override
  String get authBiometricSetup => 'Thiết lập';

  @override
  String get authLockTitle => 'Nhập mã PIN';

  @override
  String get authLockWelcome => 'Chào mừng trở lại';

  @override
  String get authForgotPin => 'Quên mã PIN?';

  @override
  String get authForgotPinMessage =>
      'Bạn sẽ đăng nhập lại bằng email và mật khẩu.';

  @override
  String get authForgotPinConfirm => 'Đăng nhập lại';

  @override
  String get authCancel => 'Huỷ';

  @override
  String pinDigitsEntered(int count, int total) {
    return 'Đã nhập $count trên $total số';
  }

  @override
  String get meSecPinSetTitle => 'Đặt mã PIN';

  @override
  String get meSecPinNone => 'Chưa đặt';

  @override
  String get authUseFaceId => 'Mở bằng Face ID';

  @override
  String get meSecPinSetDone => 'Đã đặt mã PIN';

  @override
  String get welcomeTitleLine1 => 'Tiền rõ ràng.';

  @override
  String get welcomeTitleLine2 => 'Sống nhẹ nhàng.';

  @override
  String get welcomeSub => 'Ghi chi tiêu chỉ vài giây mỗi ngày.';

  @override
  String get welcomeStart => 'Bắt đầu';

  @override
  String get welcomeSampleBalance => 'Tổng số dư';

  @override
  String get welcomeSampleFood => 'Phở Thìn';

  @override
  String get welcomeSampleSalary => 'Lương';

  @override
  String get signUpTitle => 'Tạo tài khoản Freeva';

  @override
  String get signUpSub => 'Dữ liệu được lưu an toàn, đổi máy không mất.';

  @override
  String get authContinueEmail => 'Tiếp tục với email';

  @override
  String get signUpTermsPrefix => 'Tiếp tục nghĩa là bạn đồng ý với ';

  @override
  String get signUpTermsLink => 'Điều khoản';

  @override
  String get signUpTermsSuffix => '.';

  @override
  String onbProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get onbGoalsTitle => 'Bạn muốn cải thiện điều gì?';

  @override
  String get onbGoalsSub => 'Chọn tối đa 2.';

  @override
  String get onbGoalTrack => 'Theo dõi chi tiêu';

  @override
  String get onbGoalSave => 'Tiết kiệm nhiều hơn';

  @override
  String get onbGoalBudget => 'Chi đúng ngân sách';

  @override
  String get onbGoalDebt => 'Quản lý khoản nợ';

  @override
  String get onbGoalEmergency => 'Lập quỹ dự phòng';

  @override
  String get onbGoalUnderstand => 'Hiểu rõ tài chính';

  @override
  String get onbHabitTitle => 'Bạn đang quản lý tiền thế nào?';

  @override
  String get onbHabitManual => 'Ghi chép bằng tay';

  @override
  String get onbHabitSpreadsheet => 'Dùng Excel hoặc Sheets';

  @override
  String get onbHabitApp => 'Dùng một app khác';

  @override
  String get onbHabitNone => 'Chưa theo dõi gì cả';

  @override
  String get onbCadenceTitle => 'Bao lâu bạn xem lại chi tiêu?';

  @override
  String get onbCadenceDaily => 'Mỗi ngày';

  @override
  String get onbCadenceWeekly => 'Mỗi tuần';

  @override
  String get onbCadenceMonthly => 'Mỗi tháng';

  @override
  String get onbCadenceRarely => 'Hầu như không';

  @override
  String get onbBudgetTitle => 'Mỗi tháng bạn định chi bao nhiêu?';

  @override
  String get onbBudgetAmount => 'Ngân sách mỗi tháng';

  @override
  String get onbBudgetLater => 'Thiết lập sau';

  @override
  String get setupWalletsTitle => 'Tiền của bạn ở đâu?';

  @override
  String get setupWalletsSub => 'Thêm ví và số dư. Ước chừng là đủ.';

  @override
  String get setupAdd => 'Thêm';

  @override
  String get setupSkip => 'Bỏ qua';

  @override
  String get checklistTitle => 'Bắt đầu nào';

  @override
  String get checklistWallet => 'Tạo ví';

  @override
  String get checklistExpense => 'Ghi khoản chi đầu tiên';

  @override
  String get checklistRecordNow => 'Ghi ngay';

  @override
  String get checklistPin => 'Khoá app bằng PIN';

  @override
  String authLockGreeting(String name) {
    return 'Chào $name';
  }

  @override
  String get syncTitle => 'Đồng bộ';

  @override
  String syncBannerBoth(int attention, int waiting) {
    return '$attention thay đổi cần bạn xem · $waiting thay đổi khác đang chờ gửi';
  }

  @override
  String syncBannerAttention(int count) {
    return '$count thay đổi cần bạn xem';
  }

  @override
  String syncBannerWaiting(int count) {
    return '$count thay đổi đang chờ gửi';
  }

  @override
  String get syncOffline => 'Chưa có mạng';

  @override
  String get syncUnavailable => 'Chưa gửi được';

  @override
  String get syncUnavailableSub => 'Thử lại sau';

  @override
  String get syncWaitingCard => 'Có thay đổi chờ gửi';

  @override
  String syncLastTime(String when) {
    return 'Lần cuối $when';
  }

  @override
  String get syncLastNever => 'Chưa đồng bộ lần nào';

  @override
  String syncToday(String time) {
    return 'hôm nay $time';
  }

  @override
  String syncOnDay(String date, String time) {
    return '$date $time';
  }

  @override
  String get syncRetry => 'Thử lại';

  @override
  String syncSending(int count) {
    return 'Đang gửi $count thay đổi';
  }

  @override
  String get syncSendingSub => 'Có thể dùng app như bình thường';

  @override
  String get syncAllDone => 'Đã đồng bộ hết';

  @override
  String syncSectionAttention(int count) {
    return 'CẦN BẠN XEM · $count';
  }

  @override
  String syncSectionWaiting(int count) {
    return 'ĐANG CHỜ GỬI · $count';
  }

  @override
  String syncSectionHolding(int count) {
    return 'ĐANG GIỮ TRÊN MÁY · $count';
  }

  @override
  String get syncActionAdd => 'Thêm';

  @override
  String get syncActionEdit => 'Sửa';

  @override
  String get syncActionDelete => 'Xoá';

  @override
  String get syncActionRestore => 'Khôi phục';

  @override
  String syncItemLine(String action, String detail) {
    return '$action · $detail';
  }

  @override
  String get syncReasonChanged => 'Đã đổi trên máy khác';

  @override
  String get syncReasonWallet => 'Ví đã bị xoá';

  @override
  String get syncReasonMissing => 'Giao dịch đã bị xoá ở máy khác';

  @override
  String get syncReasonInvalid => 'Dữ liệu không còn hợp lệ';

  @override
  String get syncReasonCategoryKind => 'Danh mục không hợp với loại giao dịch';

  @override
  String get transactionCategoryKind =>
      'Danh mục này không dùng cho loại giao dịch đã chọn. Hãy chọn danh mục khác.';

  @override
  String get syncReasonOther => 'Chưa gửi được · Thử lại sau';

  @override
  String get syncFooter => 'Dữ liệu vẫn nằm trên máy này cho tới khi gửi xong.';

  @override
  String get syncUpdateTitle => 'Cần cập nhật Freeva';

  @override
  String get syncUpdateBody => 'Để tiếp tục đồng bộ. Thay đổi vẫn được giữ.';

  @override
  String get syncDiscardTitle => 'Bỏ thay đổi này?';

  @override
  String syncDiscardMessage(String name, String amount) {
    return 'Khoản $name $amount sẽ không được lưu.';
  }

  @override
  String syncDiscardMessageShort(String name) {
    return 'Khoản $name sẽ không được lưu.';
  }

  @override
  String get syncDiscardKeep => 'Giữ lại';

  @override
  String get syncDiscardConfirm => 'Bỏ';

  @override
  String syncDiscardSemantics(String name) {
    return 'Bỏ thay đổi $name';
  }

  @override
  String get syncChipReview => 'Cần xem lại';

  @override
  String get syncChipWaiting => 'Chờ đồng bộ';

  @override
  String get syncViewAction => 'Xem';

  @override
  String get syncCompareTitle => 'Chọn bản giữ lại';

  @override
  String syncCompareIntroA(String name) {
    return '$name vừa được sửa ở máy khác. Khác nhau chỗ ';
  }

  @override
  String get syncCompareIntroB => 'tô vàng';

  @override
  String get syncCompareIntroC => '.';

  @override
  String get syncCompareMine => 'Bản trên máy này';

  @override
  String syncCompareMineWhen(String when) {
    return 'Bạn sửa lúc $when';
  }

  @override
  String get syncCompareSaved => 'Bản đã lưu';

  @override
  String syncCompareSavedWhen(String when) {
    return 'Sửa ở máy khác lúc $when';
  }

  @override
  String get syncCompareSavedNoTime => 'Đã lưu trên máy chủ';

  @override
  String get syncCompareDeleted => 'Đã xoá';

  @override
  String get syncFieldAmount => 'Số tiền';

  @override
  String get syncFieldCategory => 'Danh mục';

  @override
  String get syncFieldNotes => 'Ghi chú';

  @override
  String get syncFieldDate => 'Ngày';

  @override
  String get syncFieldMerchant => 'Cửa hàng';

  @override
  String get syncKeepSaved => 'Giữ bản đã lưu';

  @override
  String get syncKeepMine => 'Giữ bản trên máy này';

  @override
  String get syncDupTitle => 'Có thể bạn đã ghi rồi';

  @override
  String get syncDupSub => 'Hai khoản này giống nhau.';

  @override
  String get syncDupJust => 'VỪA GHI';

  @override
  String get syncDupExisting => 'ĐÃ CÓ';

  @override
  String get syncDupKeepBoth => 'Giữ cả hai';

  @override
  String get syncDupDeleteNew => 'Xoá bản vừa ghi';

  @override
  String syncBannerOthersWaiting(Object count) {
    return '$count thay đổi khác đang chờ gửi';
  }

  @override
  String syncLastToday(Object time) {
    return 'Lần cuối $time hôm nay';
  }

  @override
  String get syncSectionSending => 'ĐANG GỬI';

  @override
  String get reportDonutTotalExpense => 'Tổng chi';

  @override
  String get reportDonutTotalIncome => 'Tổng thu';

  @override
  String get reportBarGeneralSuffix => '(chung)';

  @override
  String reportEmptyTitleMonth(Object month) {
    return 'Chưa có số liệu tháng $month';
  }

  @override
  String get meLegal => 'Điều khoản và quyền riêng tư';

  @override
  String meNotifyOnCount(Object count) {
    return '$count đang bật';
  }

  @override
  String meGoalsCount(Object count) {
    return '$count mục tiêu';
  }

  @override
  String get meProfileEmailVerified => 'Email · đã xác nhận';

  @override
  String get meProfileEmailUnverified => 'Email · chưa xác nhận';

  @override
  String get meDeleteAccount => 'Xoá tài khoản';

  @override
  String get meExportData => 'Xuất dữ liệu';

  @override
  String get meExportHint => 'Lưu hoặc gửi một bản sao dữ liệu của bạn';

  @override
  String get meExportError => 'Chưa xuất được. Thử lại nhé.';

  @override
  String get meDeleteTitle => 'Xóa tài khoản?';

  @override
  String get meDeleteBody =>
      'Mọi dữ liệu của bạn sẽ bị xóa ngay và không khôi phục được. Bạn có thể xuất dữ liệu trước.';

  @override
  String get meDeleteConfirm => 'Xóa vĩnh viễn';

  @override
  String get meDeleteError => 'Chưa xóa được. Dữ liệu của bạn vẫn còn nguyên.';

  @override
  String get meChangeAvatar => 'Đổi ảnh đại diện';

  @override
  String get meSecurityValueFaceId => 'PIN · Face ID';

  @override
  String get meSecFaceId => 'Mở bằng Face ID';

  @override
  String get notifySessionSubAlways => 'Luôn báo để bạn kiểm tra';

  @override
  String get faqRecordQ => 'Ghi một khoản chi thế nào?';

  @override
  String get faqRecordA =>
      'Chạm nút + ở giữa thanh dưới, nhập số tiền, chọn danh mục rồi lưu. Ví và ngày lấy sẵn lần gần nhất.';

  @override
  String get faqTransferQ => 'Chuyển tiền giữa hai ví?';

  @override
  String get faqTransferA =>
      'Chạm nút +, chọn Chuyển, chọn ví đi và ví nhận rồi nhập số tiền. Số dư hai ví cập nhật cùng lúc.';

  @override
  String get faqDeletedQ => 'Xoá nhầm giao dịch thì sao?';

  @override
  String get faqDeletedA =>
      'Chạm Hoàn tác ngay khi vừa xoá. Sau đó vẫn khôi phục được trong Giao dịch, mục Đã xoá.';

  @override
  String get faqMonthQ => 'Tháng tài chính là gì?';

  @override
  String get faqMonthA =>
      'Là khoảng tính thu chi mỗi tháng. Nếu lương về ngày 5, chọn Tháng tính từ ngày 5 trong Cá nhân để số liệu khớp với bạn.';

  @override
  String get faqLockAppQ => 'Khoá app bằng PIN, Face ID';

  @override
  String get faqLockAppA =>
      'Vào Cá nhân, Bảo mật để đặt mã PIN. Có PIN rồi thì bật được Face ID. Không đặt PIN thì app không khoá.';

  @override
  String get faqSafeQ => 'Dữ liệu của tôi có an toàn?';

  @override
  String get faqSafeA =>
      'Dữ liệu lưu trong tài khoản Freeva của bạn nên đổi máy không mất. Bạn có thể khoá app bằng PIN để người khác không xem được.';

  @override
  String get homeOfflineHeading => 'Đang ngoại tuyến';

  @override
  String homeOfflineDetail(Object time) {
    return 'Số liệu lúc $time. Vẫn ghi chi được.';
  }

  @override
  String get homeCreditUsedLabel => 'Đã dùng';

  @override
  String homeCreditLimit(Object limit) {
    return 'Hạn mức $limit';
  }

  @override
  String homeOtherCurrencyMeta(Object currency, Object count) {
    return '$currency · $count ví';
  }

  @override
  String get homeTotalBalanceLabel => 'Tổng số dư';

  @override
  String authResetVerified(Object email) {
    return 'Đã xác nhận $email';
  }

  @override
  String get currencyNameVnd => 'Đồng Việt Nam';

  @override
  String get currencyNameUsd => 'Đô la Mỹ';

  @override
  String get currencyNameEur => 'Euro';

  @override
  String get currencyNameJpy => 'Yên Nhật';

  @override
  String get currencyNameKrw => 'Won Hàn Quốc';

  @override
  String get currencyNameCny => 'Nhân dân tệ';

  @override
  String get currencyNameSgd => 'Đô la Singapore';

  @override
  String get currencyNameThb => 'Baht Thái';

  @override
  String get currencyNameAud => 'Đô la Úc';

  @override
  String get currencyNameGbp => 'Bảng Anh';

  @override
  String currencyCodeName(Object code, Object name) {
    return '$code · $name';
  }

  @override
  String get tagsViewTransactions => 'Xem giao dịch';

  @override
  String homeTotalConverted(int count, String currency) {
    return 'Tổng quy đổi $currency · $count ví';
  }

  @override
  String homeDisplayCurrencyAction(String currency) {
    return 'Xem tổng theo $currency';
  }

  @override
  String get homeDisplayCurrencyTitle => 'Xem tổng theo';

  @override
  String homeUnconvertedMissing(String currency) {
    return '$currency: chưa có tỷ giá, chạm để nhập';
  }

  @override
  String homeUnconvertedFractional(String currency) {
    return '$currency: tỷ giá không đổi chẵn, chạm để sửa';
  }

  @override
  String homeRateInputLabel(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get homeRateSaveFailed =>
      'Chưa lưu được. Kiểm tra tỷ giá rồi thử lại.';

  @override
  String get convertedRowTitle => 'Quy đổi';

  @override
  String convertedAmount(String amount) {
    return '≈ $amount';
  }

  @override
  String convertedRateLine(String from, String rate, String to, String time) {
    return '1 $from = $rate $to · tỷ giá bạn nhập lúc $time';
  }
}
