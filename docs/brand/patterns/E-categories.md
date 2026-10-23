# Nhóm E — Danh mục

Trạng thái: **chốt thiết kế 2026-10-21**, chưa code. Task: `DS-P2-003` (màn Danh mục).
Canvas: trang **05 · Patterns**, hàng E
(<https://claude.ai/artifact/SmyaVvz57doJiAM6Kn678T>, riêng tư). Spec chung:
[design-system.md](../design-system.md).

## Nguyên tắc riêng cho nhóm này

- Vào từ nút nhanh "Danh mục" (Tổng quan) hoặc Cá nhân → Quản lý; không có bottom nav.
- **Hai cấp:** danh mục chính và danh mục con. Không lồng sâu hơn.
- Danh mục có sẵn và danh mục tự tạo trông như nhau, sửa/ẩn/xoá như nhau. Không gắn nhãn phân biệt.
- Ẩn được và khôi phục được. Xoá là vĩnh viễn, luôn hỏi lại bằng popup và chuyển giao dịch sang danh mục khác.
- Màu đỏ không có trong bảng màu danh mục (dành cho lỗi).

## Các màn

| # | Màn | Nội dung | Ghi chú |
|---|---|---|---|
| 1 | Danh mục | Quay lại · "Danh mục" · nút +. Segmented **Chi · Thu**. Danh mục chính: icon hai tông, tên, dòng phụ "N danh mục con" nếu có. Bên phải: nút tròn mở/thu (có con) hoặc ">" mờ (không có con). Danh mục con thụt lề 52, chấm màu 8. Dòng "Danh mục đã ẩn · 2" | Xem quy tắc mở/thu bên dưới |
| 2 | Thêm danh mục | Đóng · "Thêm danh mục". Ô icon xem trước 60 cạnh ô Tên. Lựa chọn **Danh mục chính · Danh mục con**; chọn con thì hiện ô "Thuộc" (có icon danh mục chính). Màu: 3 hàng × 7 (ô đầu "không màu"). Biểu tượng: 11 hay dùng + ô "…" mở tất cả. "Lưu danh mục" | Modal |
| 3 | Thuộc danh mục chính (sheet) | Danh sách danh mục chính, icon + radio | Chỉ danh mục chính đang dùng |
| 4 | Biểu tượng (sheet) | "Biểu tượng" · "Xong". Ô tìm ("xăng, thú cưng…"). 36 biểu tượng, 4 nhóm: Ăn uống · mua sắm / Đi lại · nhà cửa / Sức khỏe · gia đình · giải trí / Thu nhập · tài chính | Biểu tượng chọn: nền tint + viền màu đang chọn |
| 5 | Sửa danh mục | Như 2, biểu tượng là ô chọn mở sheet 4. Nút chữ "Ẩn" và "Xoá" (đỏ). "Lưu thay đổi" | Đổi chính ↔ con được nếu hợp lệ |
| 6 | Xoá (popup) | Icon thùng rác nền `status.dangerBg`. "Xoá “Ăn vặt”?" · "Không khôi phục được. 12 giao dịch sẽ chuyển sang:" ô chọn danh mục. "Huỷ" · "Xoá" (`action.danger`) | Không có giao dịch thì bỏ dòng chuyển và ô chọn |
| 7 | Danh mục đã ẩn | "Giao dịch cũ vẫn giữ danh mục này." Dòng danh mục màu nhạt, nút "Khôi phục"; danh mục chính ghi kèm số danh mục con | |

## Quy tắc mở/thu danh mục con

- Chỉ danh mục chính **có** danh mục con mới có nút mở/thu (tròn 36, mũi tên xuống). Mở: nền `tint.blue`, mũi tên lên, hiện danh mục con.
- Chạm tên/icon luôn mở màn Sửa; chạm nút tròn chỉ mở/thu.
- Mặc định **thu hết**. App nhớ trạng thái mở/thu theo thiết bị.
- Vừa tạo danh mục con thì danh mục chính của nó tự mở.
- `aria-expanded` cho trình đọc màn hình.

## Màu và biểu tượng

**20 màu** (3 hàng × 7, ô đầu là không màu). 7 màu hàng 3 cách mọi màu khác ΔE2000 ≥ 16; hồng, nâu cách đỏ lỗi ≥ 17. Hai cặp có sẵn từ trước khá gần nhau: Xanh trời / Xanh trời nhạt (7,6) và Vàng / Vàng nhạt (10,5).

| Hàng | Màu |
|---|---|
| 1 | Không màu · Xanh dương `#5680E9` · Xanh dương đậm `#3352AA` · Xanh trời `#5AB9EA` · Xanh biển đậm `#2A7FAE` · Tím `#8860D0` · Tím đậm `#5B3A96` |
| 2 | Xanh lá `#2F9E76` · Vàng `#D4A017` · Xanh dương nhạt `#99B2F2` · Xanh trời nhạt `#84CEEB` · Tím nhạt `#B59BE2` · Xanh lá nhạt `#7FD8B4` · Vàng nhạt `#E9C46A` |
| 3 | Hồng `#E46A97` · Cam `#F08A4B` · Nâu `#9A6A4F` · Xanh chanh `#9BBF2E` · Ô liu `#4A5A1F` · Mận `#8E3B6E` · Xám `#6B7288` |

Màu chỉ dùng cho chấm, nền ô icon (bậc nhạt) và biểu tượng; không làm màu chữ. Ô icon hai tông lấy nền nhạt và nét đậm cùng hue.

**36 biểu tượng** (Lucide): ăn uống, cà phê, đi chợ, mua sắm, quần áo, quà tặng · ô tô/xe máy, xe buýt, xăng, du lịch, nhà, sửa chữa, điện, nước, internet, điện thoại · sức khỏe, thuốc, thể thao, gia đình, thú cưng, làm đẹp, học tập, sách, âm nhạc, phim, trò chơi · lương, thưởng, đầu tư, công việc, tiết kiệm, thuế/phí, bảo hiểm, gói định kỳ, khác.

## Thành phần mới (bổ sung vào design system)

- **Dòng danh mục chính có nút mở/thu:** vùng chạm tên tách khỏi nút tròn 36.
- **Lựa chọn loại + ô "Thuộc":** segmented 2 lựa chọn, ô chọn có icon đầu hiện khi chọn "Danh mục con".
- **Bảng màu dạng lưới:** ô tròn 34, 7 cột; đang chọn = vòng trắng 3 + vòng màu 2 + dấu tích.
- **Lưới biểu tượng:** ô 44 bo 14, 6 cột; sheet có tìm kiếm và tiêu đề nhóm.
- **Popup xoá có chuyển dữ liệu:** icon nguy hiểm, một câu hậu quả, ô chọn đích, nút nguy hiểm.

## Phụ thuộc khi làm code

| Việc | Ghi chú |
|---|---|
| Màu mới | Xong (E1): 14 key `color.category.*` (6 màu còn lại đã có trong `color.brand` / `color.semantic`), bảng 20 màu theo thứ tự lưới ở `/options`. |
| Biểu tượng mới | Xong (E1): 21 token mới + 15 token cũ = 36 icon picker; token cũ mang nghĩa mới: `entertainment` = phim, `bills` = thuế/phí, `other_income` = tiết kiệm, `other_expense` = khác. "Đi lại" đổi từ xe buýt sang ô tô. |
| Tab Chi · Thu | Xong (E1): danh mục mới lấy tab đang mở, con lấy theo cha; "both" hiện ở cả hai tab (chốt 2026-10-23). |
| Màu danh mục ngoài màn Danh mục | Chốt 2026-10-23: chỉ dùng ở các màn nhóm E; dòng giao dịch, sheet chọn, Tổng quan giữ ô icon trung tính như thiết kế B/C. |
| Hai cấp | Xong (E1): backend chặn khi tạo/đổi cha; dữ liệu cũ lồng sâu hiện dưới danh mục chính trên cùng. |
| Chặn ẩn/xoá | Danh mục chính còn danh mục con đang dùng: nút Ẩn/Xoá mờ, dòng "Còn N danh mục con". |
| Số giao dịch khi xoá | Cần API trả số giao dịch (kể cả đã xoá mềm) để hiện "12 giao dịch sẽ chuyển sang". |
| Copy l10n | Thay chuỗi `category*` dài (`categoryHideExplanation`, `categoryDeleteBody`, `categoryInvalid`…) bằng chữ ngắn ở trên. |
