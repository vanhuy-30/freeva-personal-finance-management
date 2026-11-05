# Trả góp thẻ trên app — MOB-P3-009

Đổi một khoản chi trên ví thẻ tín dụng thành lịch trả góp, xem lịch, kết thúc sớm; chi tiết thẻ cộng phần trả góp vào số phải trả. Contract: [card-installments.md](card-installments.md). Thiết kế: [patterns/M-wallet-refund-installment.md](../brand/patterns/M-wallet-refund-installment.md) màn 2, 5, 6, 7, board `TxDetail3`, `InstAdd`, `InstDetail`, `WCredit3`.

## Hành vi

- **Chi tiết khoản chi:** card hành động có hai hàng như board: "Ghi hoàn tiền" (khi còn hoàn được) và "Chuyển thành trả góp · Chia nhiều kỳ trên thẻ" (icon tím). Hàng trả góp hiện khi giao dịch là khoản chi chưa xoá, trên ví `credit` chưa ẩn, `installmentPlanId` null và user ghi được. Sau khi đóng trang tạo, danh sách giao dịch tải lại để hàng không hiện lần hai.
- **"Trả góp" (InstAdd)**, mở toàn màn: thẻ khoản mua, chip Số kỳ 3/6/9/12/Khác (Khác mở ô nhập 2–60), "Mỗi kỳ" (sửa bằng ô nhập; xoá trống thì về chia đều), "Kỳ đầu" (mặc định ngày đến hạn của sao kê chứa khoản mua, theo ngày chốt và ngày đến hạn của thẻ; không có ngày đến hạn thì cùng ngày tháng sau). Mọi số kỳ, số mỗi kỳ và ngày các kỳ lấy từ `POST /card-installments/preview` (gọi lại mỗi lần đổi input, bỏ kết quả cũ). Hiện 3 kỳ đầu + "… thêm N kỳ, xong dd/MM/yyyy". Preview 400 → chữ đỏ "Số này chưa chia vừa N kỳ…", 409 → "Khoản này không chuyển trả góp được nữa", kỳ đầu trước ngày mua → báo ngay không gọi API; nút tắt khi có lỗi. "Tạo lịch trả góp" gửi đúng input của preview, `clientId` giữ suốt trang, xong thì thay bằng trang lịch. Chỉ online.
- **Lịch trả góp (InstDetail)**, route `/installments/:id`: tên = nơi mua, không có thì danh mục (như dòng giao dịch). "Còn phải trả" = tổng kỳ `upcoming` của API / tổng giá, thanh tím, "Đã trả {kỳ đã qua}/{số kỳ} kỳ · {ví}". Mọi kỳ: kỳ đã qua chữ mờ có dấu tích xanh, kỳ `upcoming` đầu có "Kỳ tới". "Kết thúc trả góp" ở đáy màn → popup xác nhận → `close(version)`; kế hoạch đã đóng ẩn nút và có tag "Đã kết thúc".
- **Chi tiết thẻ (WCredit3):** khi thẻ có kế hoạch đang chạy và có ngày đến hạn, thẻ "Phải trả kỳ này · dd/MM" thay thẻ thông tin thẻ: số = dư nợ − phần trả góp các kỳ sau hạn này (`due?from=hạn+1&to=2099-12-31`), vì dư nợ đã gồm đủ giá mua; không âm. Tag "Còn N ngày". "Gồm {trả góp kỳ này} trả góp · tối thiểu {số trả tối thiểu của thẻ}" với phần trả góp = `due?from=hạn kỳ trước+1&to=hạn này`. Nhóm "TRẢ GÓP": mỗi kế hoạch "Kỳ i/n · dd/MM · số" từ `nextDueOn`/`nextAmountMinor`/`remainingCount`, chạm mở lịch. Thẻ không có kế hoạch giữ như cũ.

## Layer

`features/installments`: domain `CardInstallment`, `InstallmentPeriod`, `InstallmentPreview`, `InstallmentDraft`, `InstallmentDue`, `CardPeriodDue`, `suggestedFirstDue`, `previousDueDate`; `CardInstallmentRepository` (+ impl qua `AuthorizedApi`) và use cases (chặn số kỳ ngoài 2–60). `InstallmentViewModel` (singleton): kế hoạch đang chạy và số phải trả theo thẻ, chi tiết, preview, tạo, đóng. `TxLeg.installmentPlanId` đọc từ API. Tiền là `BigInt`; app chỉ cộng/trừ số của API.

## Khác biệt có chủ ý so với board

- Icon khoản mua và dòng TRẢ GÓP lấy theo danh mục của khoản chi (board vẽ điện thoại).
- Màn hẹp hoặc chữ lớn: hai ô "Mỗi kỳ" / "Kỳ đầu" xếp chồng, ngày và "Kỳ tới" xuống dòng thay vì cắt số.
- Popup xác nhận "Kết thúc trả góp?" (board chưa vẽ).

## Test

`test/features/installments/installment_test.dart` (đọc kế hoạch, request preview/create/close/due/list, chặn số kỳ, `installmentPlanId`, điều kiện hiện hàng, ngày kỳ đầu, phải trả kỳ này), `installment_golden_test.dart` (golden sáng/tối cho tạo, lịch, chi tiết thẻ; 1.3× trang tạo; kế hoạch đã đóng; chi tiết khoản chi hai hàng; đổi số kỳ gọi lại preview và tạo đúng input; kết thúc cần xác nhận). Đối chiếu board ↔ golden: `apps/mobile/tool/design_compare` nhóm `M`.
