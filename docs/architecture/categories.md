# Categories — BE-P1-006 / BE-P1-011

Module 5, contract public trong [OpenAPI](../../packages/api-contracts/openapi.yaml).
Danh mục dùng chung cho thu/chi, transfer không có danh mục. Domain và repository
interface không phụ thuộc Prisma; adapter infrastructure là nơi truy cập DB.

## API và bootstrap

Tất cả `/api/v1/categories` yêu cầu session user, giới hạn owner và trả
`Cache-Control: no-store`. Không nhận/trả userId, không log tên hay payload.

| Method / path | Hành vi |
|---|---|
| `POST /defaults` | 204; tạo hoặc bổ sung bộ VN một lần, lặp/concurrent an toàn |
| `GET /options` | `colorTokens`, `iconTokens` cho metadata |
| `GET /{id}/usage` | `{transactionCount}`: số giao dịch xoá sẽ chuyển, kể cả đã xoá mềm (`DS-P2-003`) |
| `GET /` | `{items,page,pageSize,total}`, danh sách phẳng có parentId |
| `GET /recent` | `{items}`; tối đa 10 danh mục active dùng gần đây |
| `GET /{id}` | Chi tiết active hoặc archived |
| `POST /` | Custom; 201 mới / 200 replay |
| `PATCH /{id}` | Sửa, di chuyển, ẩn/khôi phục; version bắt buộc |
| `DELETE /{id}?version=…&replacementCategoryId=…` | Chuyển giao dịch rồi xóa nguyên tử; 204 |

Mobile gọi **POST defaults → GET categories** trước lần dùng danh mục đầu tiên.
GET không khởi tạo dữ liệu. Migration `20260925000000_categories_init` thêm nullable
`User.categoriesInitializedAt`. Migration `20261020000000_category_kind` thêm
`Category.kind` (default `both`) và `User.categoriesSupplementedAt`. Tài khoản cũ
giữ dữ liệu; migration không tạo danh mục.

`POST /defaults`:

- Chưa `categoriesInitializedAt`: tạo 26 mục hệ thống (15 gốc cũ + 11 mục spec),
  gắn `kind`, đặt cả hai marker trong cùng transaction.
- Đã khởi tạo nhưng chưa `categoriesSupplementedAt`: gán `kind` chỉ cho mục hệ
  thống còn nguyên seed; thêm tên còn thiếu đúng một lần; đặt marker. Không ghi đè
  tên đã sửa, không nhân đôi tên đã có (kể cả custom).
- Đã bổ sung: no-op. Gọi lại sau khi sửa/ẩn/xóa mặc định không tái tạo.

`kind` ∈ `expense` | `income` | `both`. Từ `DS-P2-003` POST nhận `kind` (tab Chi /
Thu đang mở, mặc định `both`); danh mục con luôn lấy `kind` của cha, và lấy `kind`
của cha mới khi chuyển cha. PATCH không đổi `kind`. Phase 1 không từ chối giao dịch theo `kind`. Điện nước, Internet,
Điện thoại là con của Hóa đơn nếu mục đó còn active; nếu không thì là gốc.

Bộ VN gồm thêm: Cà phê, Điện nước, Internet, Điện thoại, Subscription, Bảo hiểm,
Thuế/phí, Freelance, Kinh doanh, Đầu tư, Hoàn tiền. Tên là dữ liệu tiếng Việt (trừ
Subscription), không tự dịch khi đổi locale. `isSystem` chỉ ghi nhận nguồn; người
dùng vẫn sửa/ẩn/xóa được. Mặc định có icon ngữ nghĩa, colorToken null.

Icon riêng (`DS-P2-003`): bộ bổ sung tạo mới dùng icon cụ thể (Cà phê `coffee`,
Internet `internet`…). Migration `20261023000000_category_icon_refresh` thêm
`User.categoryIconsRefreshedAt`; lần `POST /defaults` kế tiếp đổi icon một lần cho
mục hệ thống còn đúng tên và icon chung cũ (tăng version), mục người dùng đã đổi
tên/icon giữ nguyên.

## Metadata, cây và danh sách

Tên trim dài 1–100 ký tự, cho phép trùng. Parent cùng owner, không tự tham chiếu
hoặc chu trình. **Hai cấp** (`DS-P2-003`): khi tạo hoặc đổi cha, cha phải là danh
mục gốc (`400`), và danh mục đang có con không được nhận cha (`409`). Dữ liệu lồng
sâu hơn từ trước vẫn đọc và sửa tại chỗ được. Client không sửa clientId/isSystem/
groupId; quản lý nhóm và nhãn nằm ngoài task này.

`colorToken` là tên token trong `packages/design-tokens/tokens.json`, không hex.
`/options` trả **bảng 20 màu** theo thứ tự lưới (`CATEGORY_PALETTE`, gồm 14 key
`color.category.*` mới, không có đỏ lỗi) và **36 icon** theo 4 nhóm
(`CATEGORY_PICKER_ICONS`). Ghi mới chỉ nhận màu trong bảng; key catalog khác chỉ
được giữ nguyên trên dòng đang có. Mọi icon cũ vẫn hợp lệ.
Catalog được sinh bởi `node backend/api/scripts/generate-category-tokens.cjs`;
unit test kiểm tra catalog khớp source of truth. Đây là metadata cho icon/badge,
không phải quyền dùng mọi token làm màu chữ; UI vẫn tuân thủ brand contrast.
`iconToken` là khóa ngữ nghĩa do `/options` công bố, không phải mã glyph Flutter.
PATCH bỏ field giữ nguyên; null chỉ xóa parent/color/icon.

List mặc định `status=active&page=1&pageSize=50`, pageSize tối đa 100; status còn
`archived|all`. `parentId=root` chỉ gốc, UUID chỉ con trực tiếp, bỏ qua lấy mọi
cấp. Parent không tồn tại/khác owner trả 404. Sort createdAt tăng rồi id tăng;
count/items cùng snapshot, không đảm bảo snapshot xuyên nhiều request phân trang.

Recent dựa trên `MAX(Transaction.createdAt)` của giao dịch chưa xóa thuộc owner,
loại danh mục archived, mỗi danh mục một lần, sort thời điểm giảm rồi categoryId
tăng. Backdate occurredOn không làm mất ưu tiên giao dịch mới ghi; edit/restore
không thay createdAt. Không truy vấn N+1 hay tải toàn bộ giao dịch về Node.

## Ẩn, xóa và chống ghi đè

- Ẩn cha còn con active trả 409. Khôi phục/move danh mục active yêu cầu toàn bộ
  tổ tiên active. Danh mục ẩn giữ lịch sử; API giao dịch từ chối ghi/sửa/khôi phục
  với danh mục ẩn theo contract hiện có.
- Xóa cha còn bất kỳ con nào, kể cả archived, trả 409. Không cascade cây.
- Có giao dịch tham chiếu thì bắt buộc replacement khác nguồn, active, cùng
  owner. Chuyển cả giao dịch soft-delete; tăng từng version/updatedAt, giữ tiền,
  ví, ngày, notes, tags và deletedAt. Version hết miền trả 409, rollback toàn bộ.
- Xóa vật lý sau khi chuyển; không có restore category. Không sửa số dư ví vì
  classification không thay tiền. Version giao dịch cũ trở nên stale.
- UUID normalize lowercase. POST replay so sánh các field tạo với giá trị hiện
  tại, không tự restore archived. Khác payload hoặc dùng clientId của default
  trả 409. Idempotency chỉ tồn tại khi record còn tồn tại: sau hard-delete,
  client không được replay create cũ nếu không muốn tạo lại custom.

## Đồng thời và lỗi

Mọi category mutation và transaction create/update/delete cập nhật `User.updatedAt`
ngay đầu DB transaction Repeatable Read qua `touchFinancialOwner`. Đây là khóa
ghi theo owner, không đổi profile version. Writer đợi snapshot cũ phải retry sau
concurrent update; chỉ SELECT FOR UPDATE sẽ không đủ làm mới snapshot. Giữ các
khóa ví và cặp transfer hiện có. Retry tối đa ba lần sau serialization/deadlock;
category create còn retry unique collision. Các user khác nhau không dùng chung
khóa; writer cùng user được tuần tự hóa, phù hợp phạm vi Phase 1.

Writer tài chính/danh mục bổ sung trong tương lai phải dùng cùng khóa trước khi
đọc hoặc ghi reference. Raw SQL/admin ngoài protocol không có bảo đảm này.

400 `VALIDATION_ERROR`; 401 theo auth; 404 `CATEGORY_NOT_FOUND` cho cả missing và
foreign; 409 `CATEGORY_CONFLICT`; 503 `CATEGORIES_UNAVAILABLE`. Lỗi không phản
chiếu input, SQL hoặc exception. Category conflict gồm stale version, danh mục con còn
tham chiếu cây, trạng thái parent/target không hợp lệ và thiếu replacement.

## Kiểm chứng và rollout

Xem [test README](../../backend/api/test/README.md#categories--be-p1-006) để chạy
unit, PostgreSQL race/fault injection và upgrade fixture. Migration additive,
không backfill hoặc tạo danh mục lúc deploy. Triển khai migration trước API mới;
mobile bootstrap chỉ dùng sau khi backend đã có endpoint. Không deploy staging/
production trong task này. UI danh mục và luồng ghi nhanh thuộc task mobile.
