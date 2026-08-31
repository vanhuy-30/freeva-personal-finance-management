# Risks

| ID | Rủi ro | Mức | Mitigation |
|---|---|---|---|
| R1 | Sai số dư / transfer | Cao | Integer money, test bảng chuẩn, QA-P0 |
| R2 | Trùng giao dịch khi sync | Cao | Idempotency, thiết kế Module 20 từ P0 |
| R3 | PDPD / store reject | Cao | Privacy docs, export/xóa trước phát hành |
| R4 | Scope creep Phase 5–7 sớm | Trung | Gate metrics, Won't MVP |
| R5 | Solo bus factor | Trung | Docs trong repo, ADR |
| R6 | Partner bank pháp lý | Cao | Chỉ Phase 6 khi có DPA |
| R7 | Float tiền tệ lọt code | Trung | Cursor rule + review |
