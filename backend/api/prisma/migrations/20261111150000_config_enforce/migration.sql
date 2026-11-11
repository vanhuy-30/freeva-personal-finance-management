-- BE-P5-001: currency display symbol for the app (no hardcoded ₫), and the daily log reminder
-- default moves to 21:00 (board). Additive; existing preference rows keep their saved time.

ALTER TABLE "Currency" ADD COLUMN "symbol" VARCHAR(8);
UPDATE "Currency" SET "symbol" = '₫' WHERE "code" = 'VND' AND "symbol" IS NULL;

ALTER TABLE "NotificationPreference" ALTER COLUMN "dailyLogTime" SET DEFAULT '21:00';
