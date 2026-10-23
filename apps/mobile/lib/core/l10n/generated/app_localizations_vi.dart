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
  String get authResendVerification => 'Gửi mã xác thực email';

  @override
  String get authVerifyEmail => 'Xác thực email';

  @override
  String get authForgotPassword => 'Quên mật khẩu';

  @override
  String get authResetPassword => 'Đặt lại mật khẩu';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Mật khẩu';

  @override
  String get authPasswordHelp => 'Ít nhất 12 ký tự, có cả chữ và số.';

  @override
  String get authEmailCode => 'Mã 64 ký tự trong email';

  @override
  String get authSuccess =>
      'Đã xử lý yêu cầu. Nếu vừa yêu cầu gửi mã, hãy kiểm tra email nếu tài khoản đủ điều kiện. Sau khi xác thực hoặc đặt lại mật khẩu, bạn có thể đăng nhập.';

  @override
  String get authInvalidInput =>
      'Kiểm tra email, mật khẩu, mã email hoặc PIN 6 chữ số và xác nhận trùng khớp.';

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
  String get authSetupPin => 'Thiết lập PIN';

  @override
  String get authLocked => 'Freeva đã khóa';

  @override
  String get authPinHelp =>
      'PIN gồm 6 chữ số, dùng để mở khóa trên thiết bị này.';

  @override
  String get authPin => 'PIN';

  @override
  String get authConfirmPin => 'Nhập lại PIN';

  @override
  String get authEnableBiometric => 'Bật mở khóa sinh trắc học';

  @override
  String get authBiometricReason => 'Xác thực để mở khóa Freeva';

  @override
  String get authUnlock => 'Mở khóa';

  @override
  String get authUseBiometric => 'Dùng sinh trắc học';

  @override
  String get authForgetDevice => 'Quên PIN / đăng nhập lại';

  @override
  String get authForgetHelp =>
      'Xóa thông tin đăng nhập trên máy này. Phiên trên máy chủ vẫn tồn tại đến khi hết hạn hoặc được thu hồi trong quản lý phiên.';

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
  String get authWelcomeTitle => 'Bắt đầu cùng Freeva';

  @override
  String get authWelcomeSubtitle =>
      'Một bước nhỏ hôm nay, tài chính vững vàng ngày mai.';

  @override
  String get authEmailPlaceholder => 'Nhập email của bạn';

  @override
  String get authContinue => 'Tiếp tục';

  @override
  String get authWelcomeBack => 'Chào mừng trở lại';

  @override
  String get authLoginSubtitle =>
      'Nhập mật khẩu để tiếp tục hành trình của bạn.';

  @override
  String get authCreateTitle => 'Tạo tài khoản Freeva';

  @override
  String get authRegisterSubtitle =>
      'Đặt mật khẩu để bắt đầu quản lý tài chính của bạn.';

  @override
  String get authCreateAccount => 'Tạo tài khoản';

  @override
  String get authVerifyTitle => 'Kiểm tra email của bạn';

  @override
  String get authVerifySubtitle =>
      'Mã xác thực đã được gửi khi đăng ký. Nhập mã trong email để hoàn tất.';

  @override
  String get authVerifyAndContinue => 'Xác thực và tiếp tục';

  @override
  String get authResendCode => 'Chưa nhận được mã? Gửi lại';

  @override
  String get authCodeResent =>
      'Đã yêu cầu gửi lại mã. Hãy kiểm tra hộp thư và thư rác.';

  @override
  String get authVerifiedNotice =>
      'Email đã được xác thực. Đăng nhập để tiếp tục.';

  @override
  String get authRecoverTitle => 'Quên mật khẩu?';

  @override
  String get authRecoverSubtitle =>
      'Chúng tôi sẽ gửi mã khôi phục đến email của bạn.';

  @override
  String get authSendResetCode => 'Gửi mã khôi phục';

  @override
  String get authNewPasswordTitle => 'Tạo mật khẩu mới';

  @override
  String get authResetSubtitle =>
      'Kiểm tra email để lấy mã khôi phục, sau đó đặt mật khẩu mới.';

  @override
  String get authNewPassword => 'Mật khẩu mới';

  @override
  String get authConfirmPassword => 'Nhập lại mật khẩu';

  @override
  String get authSavePassword => 'Lưu mật khẩu mới';

  @override
  String get authPasswordChanged =>
      'Đã đổi mật khẩu. Hãy đăng nhập bằng mật khẩu mới.';

  @override
  String get authPasswordMismatch =>
      'Hai mật khẩu chưa khớp. Vui lòng nhập lại.';

  @override
  String get authInvalidEmail => 'Vui lòng nhập địa chỉ email hợp lệ.';

  @override
  String get authShowPassword => 'Hiện mật khẩu';

  @override
  String get authHidePassword => 'Ẩn mật khẩu';

  @override
  String get authBack => 'Quay lại';

  @override
  String get authSecurityNote =>
      'Tài khoản của bạn được bảo vệ bằng mật khẩu và khóa ứng dụng.';

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
  String syncPending(int count) {
    return '$count thay đổi chờ đồng bộ';
  }

  @override
  String get syncNow => 'Đồng bộ';

  @override
  String get syncing => 'Đang đồng bộ';

  @override
  String get syncConflict => 'Không ghi đè. Tải lại để xem bản trên máy chủ.';

  @override
  String get syncReview => 'Số tiền khác bản đã lưu. Không ghi đè.';

  @override
  String get syncFailedItem => 'Không đồng bộ được thay đổi này.';

  @override
  String get syncDiscard => 'Bỏ';

  @override
  String get syncSchema =>
      'Tạm dừng đồng bộ vì schema ứng dụng và máy chủ khác nhau.';

  @override
  String get syncDuplicate =>
      'Có thể đã có giao dịch tương tự. Bản này vẫn được giữ.';

  @override
  String get syncDelete => 'Xóa';

  @override
  String get syncRestore => 'Khôi phục';

  @override
  String get syncChange => 'Thay đổi';

  @override
  String syncItem(String action, String date) {
    return '$action · $date';
  }

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
  String get settingsFeedback => 'Gửi phản hồi';

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
  String get onboardingSkip => 'Bỏ qua';

  @override
  String get onboardingNext => 'Tiếp';

  @override
  String get onboardingBack => 'Quay lại';

  @override
  String get onboardingFinish => 'Xong';

  @override
  String get onboardingWelcomeTitle => 'Chào mừng đến Freeva';

  @override
  String get onboardingWelcomeBody =>
      'Vài bước ngắn để bạn tự ghi chép tiền mà không cần hỗ trợ thêm.';

  @override
  String get onboardingWalletTitle => 'Tạo một ví';

  @override
  String get onboardingWalletBody =>
      'Thêm ví tiền mặt, ngân hàng, ví điện tử hoặc thẻ. Mỗi số tiền giữ nguyên loại tiền của ví.';

  @override
  String get onboardingTransactionTitle => 'Ghi giao dịch đầu tiên';

  @override
  String get onboardingTransactionBody =>
      'Từ trang chủ, ghi thu, chi, hoặc chuyển khoản giữa hai ví.';

  @override
  String get faqTitle => 'Câu hỏi thường gặp';

  @override
  String get faqWalletQ => 'Làm sao để thêm ví?';

  @override
  String get faqWalletA =>
      'Mở Ví từ trang chủ, rồi tạo ví tiền mặt, ngân hàng, ví điện tử hoặc thẻ.';

  @override
  String get faqTransactionQ => 'Làm sao để ghi giao dịch?';

  @override
  String get faqTransactionA =>
      'Mở Giao dịch hoặc chọn Ghi giao dịch ở trang chủ. Chọn thu, chi, hoặc chuyển khoản cân bằng hai vế.';

  @override
  String get faqProfileQ => 'Làm sao để đổi ngôn ngữ, tiền tệ hoặc múi giờ?';

  @override
  String get faqProfileA =>
      'Mở Cài đặt, rồi Ngôn ngữ, tiền tệ và múi giờ. Ngôn ngữ đổi sau khi hồ sơ được lưu.';

  @override
  String get faqLockQ => 'Ứng dụng khóa như thế nào?';

  @override
  String get faqLockA =>
      'Freeva khóa khi bạn rời ứng dụng. Mở khóa bằng PIN sáu số. Có thể bật sinh trắc trong Cài đặt sau khi đã có PIN.';

  @override
  String get faqThemeQ => 'Làm sao để đổi sáng và tối?';

  @override
  String get faqThemeA =>
      'Mở Cài đặt và chọn Sáng, Tối hoặc Theo hệ thống. Sáng là mặc định và được giữ trên thiết bị này.';

  @override
  String get feedbackTitle => 'Phản hồi';

  @override
  String get feedbackIdea => 'Góp ý';

  @override
  String get feedbackProblem => 'Lỗi';

  @override
  String get feedbackMessage => 'Nội dung';

  @override
  String get feedbackCopy => 'Sao chép phản hồi';

  @override
  String get feedbackCopied =>
      'Đã sao chép. Chưa có địa chỉ liên hệ, nên Freeva không gửi nội dung này.';

  @override
  String get feedbackInvalid => 'Hãy nhập nội dung, tối đa 2000 ký tự.';

  @override
  String get feedbackHelp =>
      'Freeva sao chép nội dung trên thiết bị này. Nội dung không được tải lên và không được ghi vào log.';

  @override
  String get legalDraft =>
      'Bản nháp cho PRD-P0-002. Đây không phải tư vấn pháp lý và chưa có hiệu lực. Pháp nhân vận hành và kênh liên hệ chưa được chốt.';

  @override
  String get tosTitle => 'Điều khoản dịch vụ';

  @override
  String get tosBody =>
      'Freeva để bạn ghi ví và giao dịch do bạn nhập. Bạn giữ dữ liệu tài chính của mình. Đơn vị vận hành chưa được chốt. Xuất và xóa tài khoản là việc phát hành riêng. Bản tóm tắt này không thay điều khoản đã được luật sư rà.';

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
  String homeCreditUsed(String used, String limit) {
    return 'Đã dùng $used / Hạn mức $limit';
  }

  @override
  String homeCreditUsedNoLimit(String used) {
    return 'Đã dùng $used';
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
  String homeOfflineTitle(String time) {
    return 'Đang ngoại tuyến · Số liệu lúc $time';
  }

  @override
  String get homeOfflineBody => 'Vẫn ghi chi được.';

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
  String get creditOptionalHint => 'Hạn mức và ngày có thể để trống.';

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
  String reportBarGeneral(String name) {
    return '$name (chung)';
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
  String get meCurrency => 'Tiền tệ mặc định';

  @override
  String get meBudget => 'Ngân sách tháng';

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
  String get meTerms => 'Điều khoản dịch vụ';

  @override
  String get mePrivacy => 'Chính sách bảo mật';

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
}
