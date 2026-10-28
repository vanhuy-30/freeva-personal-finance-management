# Git

- Trunk-based: `main` luôn deployable. Feature branch ngắn `feat/{TASK-ID}-slug`.
- Conventional commits có task ID: `feat(MOB-P1-004): add wallet list`.
- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `sec`.
- Không `--force` lên `main`. Không commit `.env`.
- PR nhỏ, một task chính.
- PR body: task ID + chức năng + lý do; mục **Tồn đọng / follow-up** bắt buộc (ghi gap hoặc **Không có**). Template: [.github/PULL_REQUEST_TEMPLATE.md](../../.github/PULL_REQUEST_TEMPLATE.md).
