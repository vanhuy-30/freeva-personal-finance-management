# Xuất dữ liệu trên app — MOB-P3-010

API: [transactions-csv-export.md](transactions-csv-export.md) (`GET /transactions/export.csv`) và [account-privacy.md](account-privacy.md) (`GET /account/export`). Thiết kế: nhóm O màn 3, board `DataExport` ([O-profile-data.md](../brand/patterns/O-profile-data.md)).

## Chức năng

Cá nhân → Hồ sơ → "Xuất dữ liệu" mở `/me/export`. User chọn:

- **Bảng giao dịch (CSV)**: chip thời gian (Tháng này, 3 tháng, Năm nay, Tất cả, Tuỳ chọn), ví (chọn nhiều), dòng "01/11 – 30/11 · 248 giao dịch" rồi "Xuất file" mở share sheet. Mở bằng Excel đúng tiếng Việt.
- **Bản sao đầy đủ (JSON)**: không lọc, dùng luồng `ProfileViewModel.exportData` có sẵn (bản sao lưu, không để đọc).

## Cách làm

- Số giao dịch xem trước lấy từ `GET /transactions?pageSize=1` (`total`) cùng bộ lọc, nên không đổi backend. Quá 50 000 dòng (`csvExportMaxRows`) hoặc 0 dòng thì tắt nút và nói rõ.
- File CSV tải bằng **bytes** (`AuthApi.requestBytes`) để giữ BOM UTF-8; không đi qua `String`. Chia sẻ qua `AccountFileSharer.shareBytes` (mime `text/csv`), file tạm xoá ngay sau khi chia sẻ. Tên `freeva-transactions-YYYYMMDD.csv`.
- Khoảng ngày theo ngày bắt đầu tháng của hồ sơ (`exportRange`): "3 tháng" là tháng này và hai tháng trước, "Năm nay" từ 1/1 tới hôm nay.
- Chỉ online. Lỗi → toast "Chưa xuất được"; phiên hết hạn → về đăng nhập.

## Code

`profile/domain/export_period.dart`, `transactions_csv_export_use_case.dart`, `presentation/viewmodels/data_export_view_model.dart`, `presentation/pages/data_export_page.dart`; `SelectableCard` thêm `subtitle`. Test: `test/features/profile/data_export_test.dart` + golden sáng/tối, 320 pt ở chữ 1.3×, "quá nhiều", "bản sao đầy đủ".
