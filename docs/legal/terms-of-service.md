# Điều khoản dịch vụ (bản nháp)

> **Bản nháp nội bộ** — task `PRD-P0-002`. Phiên bản: 2026-09-01.
>
> Đây **không** phải tư vấn pháp lý, **không** phải điều khoản có hiệu lực với người dùng cuối. Cần luật sư rà trước khi đưa lên store, website, hoặc màn hình in-app. Pháp nhân và email liên hệ chưa chốt — [DECISIONS-OPEN](../project-state/DECISIONS-OPEN.md) (#2, #10). Region dữ liệu production: **Việt Nam** (#5).
>
> Chính sách bảo mật (nháp): [privacy-policy.md](privacy-policy.md). Data map nội bộ: [privacy-compliance.md](../architecture/privacy-compliance.md).

## 1. Chấp nhận điều khoản

Khi đăng ký hoặc dùng Freeva, bạn đồng ý với Điều khoản này và Chính sách bảo mật. Nếu không đồng ý, đừng tạo tài khoản và đừng dùng dịch vụ.

Bản này là copy làm việc trong repo. Cho đến khi có bản đã review luật sư và công bố, không dùng làm cam kết với người dùng hay cửa hàng ứng dụng.

## 2. Dịch vụ

Freeva là ứng dụng **sổ thu chi cá nhân**: tạo tài khoản người dùng, tạo ví, ghi giao dịch (thu, chi, chuyển khoản), xem số dư và báo cáo cơ bản. Tầm nhìn sản phẩm: [vision.md](../product/vision.md).

Freeva **không** phải:

- Ngân hàng, tổ chức tín dụng, hay ví điện tử được cấp phép trung gian thanh toán.
- Sàn giao dịch, robo-advisor, hay dịch vụ tư vấn đầu tư.
- Dịch vụ chuyển tiền hộ, thanh toán hộ, hoặc giữ tiền của bạn.

Số liệu trên app phản ánh những gì **bạn ghi**. Chúng tôi không đối soát với ngân hàng ở MVP (kết nối ngân hàng chỉ Phase 6, khi có đối tác và DPA — không cam kết trong bản này).

## 3. Điều kiện sử dụng

- Bạn phải **đủ 16 tuổi** (ngưỡng dữ liệu trẻ em theo tinh thần Nghị định 13/2023/NĐ-CP). Đây là giả định pháp lý làm việc, **không** phải cổng sản phẩm theo nghề hay độ tuổi marketing — [personas.md](../product/personas.md).
- Freeva hướng tới người tự quản lý tiền cá nhân. Không chặn đăng ký theo nghề.
- Một tài khoản người dùng (email/session) khác **ví** (tiền mặt, ngân hàng, ví điện tử, thẻ) — [glossary.md](../product/glossary.md).
- Nhân viên web admin (**staff**) không phải user app; không dùng tài khoản staff để ghi chi cá nhân trên hệ thống user.

## 4. Tài khoản

Đăng ký / đăng nhập email, xác thực email, đặt lại mật khẩu là phạm vi Phase 1 ([module 01](../product/modules/01-auth.md)). Bản nháp này mô tả dịch vụ **dự kiến** khi phát hành, không khẳng định các API đó đã có.

Bạn chịu trách nhiệm:

- Giữ bí mật mật khẩu và thiết bị đã đăng nhập.
- Không cho người khác dùng tài khoản của bạn.
- Thông tin đăng ký (email) là của bạn hoặc bạn được phép dùng.

Chúng tôi có thể giới hạn đăng nhập sai, thu hồi phiên, và yêu cầu khóa app (PIN / sinh trắc học) trên thiết bị — chi tiết kỹ thuật: [security.md](../architecture/security.md).

## 5. Dữ liệu bạn nhập

Bạn chịu trách nhiệm độ chính xác của số dư ban đầu, giao dịch, danh mục, và thông tin hồ sơ. Sai số liệu trên app không phải lỗi “ngân hàng ghi sai” trừ khi có tích hợp đối tác (chưa có).

Tiền được lưu bằng đơn vị nhỏ nhất (VND = đồng nguyên), không dùng số thực nhị phân. Chuyển khoản là hai bút toán cân bằng. Đây là quy tắc sản phẩm, không phải cam kết kế toán hay thuế.

## 6. Hành vi bị cấm

Không được:

- Phá hoại, quét (scrape) trái phép, hay lạm dụng API vượt mức hợp lý.
- Cố truy cập tài khoản hoặc dữ liệu của người khác.
- Đưa mã độc, spam, hoặc nội dung bất hợp pháp vào trường ghi chú / hỗ trợ.
- Dùng Freeva để gian lận, rửa tiền, hoặc hoạt động bị pháp luật cấm.
- Giả danh nhân viên Freeva.

Vi phạm có thể dẫn tới tạm khóa hoặc xóa tài khoản.

## 7. Phí và gói dịch vụ

Vòng lặp cốt lõi (ghi thu chi, xuất dữ liệu, xóa tài khoản) **không** bị paywall chặn — [vision.md](../product/vision.md).

Gói Premium / mua in-app (IAP) chỉ nằm trong Phase 7, **chưa** có sản phẩm hay mức giá. Bản này không cam kết IAP, đối tác thanh toán, hay timeline thu phí.

Hạ cấp gói (khi có) không xóa dữ liệu ghi chép của bạn.

## 8. Sở hữu trí tuệ

Ứng dụng, thương hiệu Freeva, và tài liệu sản phẩm thuộc đơn vị vận hành (pháp nhân TBD). Bạn giữ quyền đối với dữ liệu tài chính **bạn** nhập. Cấp cho chúng tôi quyền xử lý dữ liệu đó chỉ để cung cấp dịch vụ, đúng [privacy-policy.md](privacy-policy.md).

## 9. Tuyên bố miễn trừ

Freeva cung cấp công cụ ghi chép. Chúng tôi **không** bảo đảm:

- Số dư khớp sao kê ngân hàng nếu bạn nhập tay.
- Tư vấn tài chính, thuế, hay đầu tư.
- Dịch vụ không gián đoạn 100% (đồng bộ, bảo trì, sự cố hạ tầng).

Trong phạm vi pháp luật cho phép, trách nhiệm của chúng tôi giới hạn ở thiệt hại trực tiếp có thể chứng minh, không gồm lợi nhuận bị mất hay thiệt hại gián tiếp. Mức cụ thể do luật sư chốt trước khi công bố.

## 10. Chấm dứt và xóa tài khoản

Bạn có thể ngừng dùng dịch vụ bất kỳ lúc nào. Quyền xóa tài khoản và xuất dữ liệu sẽ có **trước phát hành** store (`BE-P1-010`) — chưa ship ở Phase 0.

Chúng tôi có thể tạm khóa hoặc chấm dứt tài khoản nếu vi phạm Điều khoản, theo yêu cầu pháp luật, hoặc khi ngừng vận hành dịch vụ (sẽ thông báo qua email đã đăng ký khi có quy trình đó).

Sau khi xóa, dữ liệu tài khoản/tài chính được xử lý theo retention trong [privacy-compliance.md](../architecture/privacy-compliance.md) (đề xuất: xóa TK + 30 ngày đối với dữ liệu tài khoản).

## 11. Thay đổi điều khoản

Khi có bản công bố, thay đổi trọng yếu sẽ được thông báo trong app hoặc email. Tiếp tục dùng sau ngày hiệu lực nghĩa là chấp nhận bản mới — cơ chế thông báo cụ thể do luật sư và sản phẩm chốt.

Cập nhật bản nháp trong repo không tự tạo nghĩa vụ với người dùng.

## 12. Luật điều chỉnh

Thị trường đầu: Việt Nam. Luật điều chỉnh dự kiến: pháp luật Việt Nam. Tòa án / trọng tài cụ thể do luật sư chốt khi có pháp nhân.

## 13. Liên hệ

- Hỗ trợ sản phẩm / quyền riêng tư: **TBD** (chưa có email công khai).
- Báo cáo lỗ hổng bảo mật: `security@` **TBD** — [DECISIONS-OPEN](../project-state/DECISIONS-OPEN.md) #10.

Không gửi mật khẩu, OTP, hay số dư trong email hỗ trợ nếu kênh chưa được hướng dẫn.
