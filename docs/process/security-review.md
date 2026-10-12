# Security review

Trước phát hành phase:

1. Cập nhật [threat-model.md](../architecture/threat-model.md) cho bề mặt mới.
2. Checklist: authn/z, secrets, logs ([pii-log-checklist.md](../architecture/pii-log-checklist.md)), export/delete, rate limit.
3. Dependency audit (`pnpm audit`, Flutter pub outdated).
4. Không pentest nội bộ bằng payload exploit trong repo (dùng tool chuyên biệt, ngoài git).

Kết quả Phase 1: [security-test-phase1.md](../architecture/security-test-phase1.md) (`SEC-P1-001`).
