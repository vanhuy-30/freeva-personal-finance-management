-- DS-P2-003: one-shot specific icons for untouched default categories.
ALTER TABLE "User" ADD COLUMN "categoryIconsRefreshedAt" TIMESTAMPTZ;
