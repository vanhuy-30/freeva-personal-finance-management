-- BE-P2-E07: minimum payment on credit cards; unlock card notification preference.

ALTER TABLE "FinancialAccount"
  ADD COLUMN "minimumPaymentMinor" BIGINT;

ALTER TABLE "NotificationPreference"
  ALTER COLUMN "cardEnabled" SET DEFAULT true;

UPDATE "NotificationPreference"
  SET "cardEnabled" = true
  WHERE "cardEnabled" = false;
