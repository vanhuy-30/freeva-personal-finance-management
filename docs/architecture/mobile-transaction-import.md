# Nhập giao dịch trên app — MOB-P3-011

API: [transaction-import.md](transaction-import.md) (`POST /transactions/import/preview`, `POST /transactions/import`, `POST /transactions/import/{id}/undo`). Thiết kế: nhóm O màn 4–8, boards `ImportSource`, `ImportColumns`, `ImportMap`, `ImportPreview`, `ImportDone` ([O-profile-data.md](../brand/patterns/O-profile-data.md)).

## Chức năng

Cá nhân → DỮ LIỆU → "Nhập từ app khác" mở `/me/import`. Một route, năm bước; Back đi lùi từng bước.

1. **Nguồn dữ liệu:** Money Lover, Sổ thu chi MISA, Freeva, Nơi khác. "Chọn file CSV" mở bộ chọn file của hệ điều hành.
2. **Chọn cột** (chỉ Nơi khác): mỗi trường (Ngày\*, Số tiền\*, Thu hay chi, Danh mục, Ví, Ghi chú) chọn một cột trong file hoặc "Không dùng", cộng kiểu ngày và kiểu số. Cột được đoán sẵn theo tên header (không dấu, không phân biệt hoa thường).
3. **Ghép ví và danh mục:** chỉ hiện khi server báo còn tên chưa khớp. Tên chưa ghép là ô viền đứt "Chọn". Nếu file không có cột ví thì có một dòng "Mọi dòng trong file" để chọn ví chung.
4. **Xem trước:** ba ô Sẵn sàng · Trùng · Lỗi, chip lọc, từng dòng kèm tag ("Trùng", "Thiếu ngày", …). Công tắc "Vẫn nhập khoản trùng" (mặc định tắt). Nút "Nhập N giao dịch".
5. **Đã nhập xong:** số giao dịch đã nhập, số bị bỏ qua, "Xem giao dịch", "Hoàn tác lần nhập".

## Cách làm

- **Server là nơi đọc file.** App chỉ gửi `text` (UTF-8, giữ nguyên BOM) cùng mapping/`walletMap`/`categoryMap`; số tiền, ngày, trùng, lỗi từng dòng đều do API trả về. App không tự phân tích số tiền. `CsvPeek` chỉ đọc header, số dòng và dòng đầu để hiển thị bước chọn cột.
- **Chặn sớm:** file không đọc được (không phải UTF-8), rỗng, quá 2 000 dòng (`importMaxRows`) hoặc quá 1 000 000 ký tự (`importMaxChars`) thì báo ngay ở bước 1, không gọi API.
- **Gọi preview hai lần là bình thường:** lần đầu để biết tên nào chưa khớp, lần sau (sau khi ghép) để ra bản xem trước cuối. Tên đã thấy vẫn nằm trong danh sách ghép dù server đã thôi báo.
- **Ghi một lô, thử lại an toàn:** `batchClientId` sinh một lần cho mỗi file được chọn; "Nhập" lỗi mạng rồi bấm lại gửi cùng `batchClientId`, server trả lô đã lưu, không nhân đôi. Chọn file khác thì có id mới.
- **Hoàn tác:** gọi `undo`; xong báo "Đã hoàn tác N giao dịch" và về Hồ sơ. Khoản đã sửa hoặc dính hoàn tiền/trả góp được server giữ lại (dòng ghi chú trên màn xong).
- Chỉ online. Lỗi → toast "Chưa nhập được"; phiên hết hạn → về đăng nhập (`AuthViewModel.sessionExpired`).
- File picker nằm sau interface `ImportFilePicker` (`file_picker` ở `data/`), nên view model test không cần nền tảng. Dependency mới: `file_picker`.

## Code

`features/transaction_import/`: `domain/` (`import_models`, `csv_peek`, `import_repository`, `import_use_cases`, `import_file_picker`), `data/` (`import_repository_impl`, `platform_import_file_picker`), `presentation/viewmodels/import_view_model.dart`, `presentation/pages/import_page.dart`, `presentation/widgets/import_{source,columns,map,preview,done}_view.dart`, `import_pick_sheet.dart`. Route `/me/import` trong `app_router.dart`.

Test: `test/features/transaction_import/import_test.dart` (CSV, parse API, view model), `import_golden_test.dart` (sáng/tối, có lỗi file, 320 pt ở 1.3×, chỉ macOS).

## Chưa có

Excel (`.xlsx`); header Money Lover/MISA chưa kiểm với file thật (theo `BE-P3-011`); chưa chạy trên thiết bị thật/staging.
