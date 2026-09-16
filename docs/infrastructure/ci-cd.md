# CI/CD

GitHub Actions [ci.yml](../../.github/workflows/ci.yml):

- `web-admin`: lint + build
- `api`: test + build
- `mobile`: `flutter pub get` + generate DI (`build_runner`) + `flutter gen-l10n` + analyze + test

Workflow chạy trên pull request và push `main`, với ba job độc lập trên `ubuntu-latest`. API/admin dùng Node 22 và pnpm theo `packageManager` ở root, cài bằng `--frozen-lockfile`; mobile dùng Flutter channel `stable`.

## Kiểm chứng `INF-P0-002` — 2026-09-16

- [CI run 33521325189](https://github.com/vanhuy-30/freeva-personal-finance-management/actions/runs/33521325189): push `main` ngày 2026-09-01, commit `e72ac63fa15aa1e885158b4dfd2e369dfac3bdab`.
- GitHub API xác nhận cả ba job `api`, `web-admin`, `mobile` đều `success`, gồm checkout, cài dependency, generate và các bước test/lint/analyze/build tương ứng. SHA `main` trên GitHub trùng checkout local khi kiểm tra.
- Đủ DoD “workflow xanh trên main”; không cần sửa workflow. Đây là bằng chứng của run ngày 2026-09-01, không phải một run mới ngày kiểm chứng.
- `git fetch origin` qua SSH báo `Repository not found`; đối chiếu remote bằng GitHub API thành công. Không đổi remote hoặc credentials trong repo.

### Chạy lại local

Môi trường: Node `22.15.0`, pnpm `10.0.0`, Flutter `3.24.1`, Dart `3.5.1`. Flutter local khác cách chọn bản stable ở CI; kết quả local bổ sung cho bằng chứng GitHub phía trên.

- `pnpm install --frozen-lockfile`: pass.
- API: `pnpm --filter @freeva/api test` pass 2 suites / 7 tests; `pnpm --filter @freeva/api build` pass (gồm Prisma generate).
- Mobile: `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, `flutter gen-l10n`, `flutter analyze`, `flutter test` đều pass; 1 widget test, không có diff file generated hoặc lockfile.
- Admin: `pnpm --filter @freeva/web-admin lint` pass. Build local chưa pass: lần đầu không tải được Geist/Geist Mono từ Google Fonts; chạy lại với quyền mở rộng vẫn bị `Operation not permitted (os error 1)` khi Turbopack bind cổng cho xử lý CSS. Không đổi bundler hoặc bỏ bước build để né giới hạn môi trường. Bằng chứng build pass là job `web-admin` trên GitHub ở run nêu trên.

CD staging/prod chưa có — `INF-P0` còn lại / `INF-P1`.

Release app store: quy trình [../process/release.md](../process/release.md).
