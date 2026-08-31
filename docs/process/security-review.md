# Security review

Trước phát hành phase:

1. Cập nhật threat model cho bề mặt mới.
2. Checklist: authn/z, secrets, logs, export/delete, rate limit.
3. Dependency audit (`pnpm audit`, Flutter pub outdated).
4. Không pentest nội bộ bằng payload exploit trong repo (dùng tool chuyên biệt, ngoài git).
