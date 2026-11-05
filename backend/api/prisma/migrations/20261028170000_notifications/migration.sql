-- BE-P2-E05: in-app notification preferences, quiet hours, and inbox.

CREATE TYPE "NotificationKind" AS ENUM (
  'budget',
  'goal',
  'debt',
  'card',
  'recurring',
  'month_review',
  'insight',
  'security'
);

CREATE TABLE "NotificationPreference" (
  "userId" UUID NOT NULL,
  "budgetEnabled" BOOLEAN NOT NULL DEFAULT true,
  "goalEnabled" BOOLEAN NOT NULL DEFAULT false,
  "debtEnabled" BOOLEAN NOT NULL DEFAULT false,
  "cardEnabled" BOOLEAN NOT NULL DEFAULT false,
  "recurringEnabled" BOOLEAN NOT NULL DEFAULT true,
  "monthReviewEnabled" BOOLEAN NOT NULL DEFAULT false,
  "insightEnabled" BOOLEAN NOT NULL DEFAULT false,
  "quietHoursEnabled" BOOLEAN NOT NULL DEFAULT false,
  "quietStart" VARCHAR(5) NOT NULL DEFAULT '22:00',
  "quietEnd" VARCHAR(5) NOT NULL DEFAULT '07:00',
  "version" INTEGER NOT NULL DEFAULT 1,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "NotificationPreference_pkey" PRIMARY KEY ("userId")
);

CREATE TABLE "InAppNotification" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "kind" "NotificationKind" NOT NULL,
  "dedupeKey" VARCHAR(160) NOT NULL,
  "titleKey" VARCHAR(64) NOT NULL,
  "bodyKey" VARCHAR(64) NOT NULL,
  "params" JSONB NOT NULL DEFAULT '{}',
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "readAt" TIMESTAMPTZ,
  CONSTRAINT "InAppNotification_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "InAppNotification_userId_dedupeKey_key" ON "InAppNotification"("userId", "dedupeKey");
CREATE INDEX "InAppNotification_userId_createdAt_idx" ON "InAppNotification"("userId", "createdAt");

ALTER TABLE "NotificationPreference"
  ADD CONSTRAINT "NotificationPreference_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "InAppNotification"
  ADD CONSTRAINT "InAppNotification_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
