-- BE-P3-006: daily expense-log reminder. Additive; deploy before the API.

ALTER TYPE "NotificationKind" ADD VALUE 'daily_log';

ALTER TABLE "NotificationPreference"
  ADD COLUMN "dailyLogEnabled" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "dailyLogTime" VARCHAR(5) NOT NULL DEFAULT '20:00';
