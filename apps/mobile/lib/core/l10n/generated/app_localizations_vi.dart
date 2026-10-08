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
  String get homePlaceholder =>
      'Vòng lặp cốt lõi: ví → giao dịch → số dư. Feature nghiệp vụ nằm ở lib/features.';

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
  String get authPasswordHelp =>
      'Từ 12 đến 128 ký tự; giữ nguyên khoảng trắng.';

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
  String get walletCreditLimit => 'Hạn mức tín dụng (không bắt buộc)';

  @override
  String get walletCloseDay => 'Ngày chốt thẻ (1–28, không bắt buộc)';

  @override
  String get walletDueDay => 'Ngày thanh toán (1–28, không bắt buộc)';

  @override
  String get walletMoneyHint =>
      'Nhập số tiền theo đơn vị tiền tệ đã chọn, không dùng dấu phân cách hàng nghìn. Ví dụ: VND 10000; USD 10,50.';

  @override
  String get walletEditHint =>
      'Khi ví có giao dịch, không thể đổi loại ví hoặc tiền tệ. Sửa số dư ban đầu chỉ dùng để đính chính.';

  @override
  String get walletShowHidden => 'Xem ví đã ẩn';

  @override
  String get walletHide => 'Ẩn ví';

  @override
  String get walletRestore => 'Khôi phục ví';

  @override
  String get walletHideExplanation =>
      'Ẩn ví là lưu trữ ví khỏi danh sách đang dùng. Số dư và lịch sử vẫn được giữ lại; có thể khôi phục sau.';

  @override
  String get walletMoveUp => 'Di chuyển lên';

  @override
  String get walletMoveDown => 'Di chuyển xuống';

  @override
  String get walletEmpty => 'Chưa có ví. Thêm ví đầu tiên để bắt đầu.';

  @override
  String get walletHiddenEmpty => 'Không có ví đã ẩn.';

  @override
  String walletBalance(String amount, String currency) {
    return 'Số dư: $amount $currency';
  }

  @override
  String get walletInvalid =>
      'Kiểm tra tên, số tiền và ngày 1–28. Loại ví hoặc tiền tệ có thể đã bị khóa do có giao dịch.';

  @override
  String get walletConflict =>
      'Ví đã thay đổi ở nơi khác. Quay lại danh sách và tải lại trước khi sửa tiếp.';

  @override
  String get walletError => 'Không thể tải hoặc lưu ví. Vui lòng thử lại.';

  @override
  String get walletReloadRequired =>
      'Thao tác có thể đã được lưu một phần. Tải lại danh sách để lấy trạng thái mới nhất.';
}
