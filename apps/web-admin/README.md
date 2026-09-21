# @freeva/web-admin

Next.js App Router, port **3001**. Theme từ `@freeva/design-tokens`.

Local: `cp .env.example .env.local` rồi `pnpm --filter @freeva/web-admin dev`.

Staging: Vercel — [docs/infrastructure/staging.md](../../docs/infrastructure/staging.md), `vercel.json`.

Brand asset (`WA-P1-001`): `src/app/icon.png` là bản sao nguyên vẹn của
[`docs/brand/freeva-app-icon.png`](../../docs/brand/freeva-app-icon.png) và
được Next.js phục vụ làm favicon; metadata icon trong `src/app/layout.tsx` trỏ
đến `/icon.png`. Logo ở header là bản sao nguyên vẹn của
[`docs/brand/freeva-logo-lockup.png`](../../docs/brand/freeva-logo-lockup.png)
trong `public/brand/`. Khi thay asset gốc, copy lại hai file này để giữ đồng bộ.
