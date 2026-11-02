-- BE-P3-E01: savings goals. Money changes go through GoalEntry (transfer or audit).

CREATE TYPE "GoalKind" AS ENUM ('emergency', 'home', 'car', 'travel', 'education', 'wedding', 'retirement', 'custom');
CREATE TYPE "GoalEntryKind" AS ENUM ('contribute', 'withdraw');

CREATE TABLE "Goal" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "kind" "GoalKind" NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "currencyCode" CHAR(3) NOT NULL,
    "targetMinor" BIGINT NOT NULL,
    "currentMinor" BIGINT NOT NULL DEFAULT 0,
    "targetDate" DATE,
    "accountId" UUID NOT NULL,
    "monthlyContributionMinor" BIGINT,
    "icon" VARCHAR(30) NOT NULL,
    "colorToken" VARCHAR(40),
    "archivedAt" TIMESTAMPTZ,
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,
    CONSTRAINT "Goal_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Goal_target_check" CHECK ("targetMinor" > 0),
    CONSTRAINT "Goal_current_check" CHECK ("currentMinor" >= 0),
    CONSTRAINT "Goal_monthly_check" CHECK ("monthlyContributionMinor" IS NULL OR "monthlyContributionMinor" >= 0)
);

CREATE TABLE "GoalEntry" (
    "id" UUID NOT NULL,
    "goalId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "kind" "GoalEntryKind" NOT NULL,
    "amountMinor" BIGINT NOT NULL,
    "transactionClientId" UUID,
    "occurredOn" DATE NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "GoalEntry_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "GoalEntry_amount_check" CHECK ("amountMinor" > 0)
);

CREATE UNIQUE INDEX "Goal_userId_clientId_key" ON "Goal"("userId", "clientId");
CREATE INDEX "Goal_userId_archivedAt_idx" ON "Goal"("userId", "archivedAt");
CREATE UNIQUE INDEX "GoalEntry_userId_clientId_key" ON "GoalEntry"("userId", "clientId");
CREATE INDEX "GoalEntry_goalId_createdAt_idx" ON "GoalEntry"("goalId", "createdAt");

ALTER TABLE "Goal" ADD CONSTRAINT "Goal_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Goal" ADD CONSTRAINT "Goal_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "FinancialAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Goal" ADD CONSTRAINT "Goal_currencyCode_fkey" FOREIGN KEY ("currencyCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "GoalEntry" ADD CONSTRAINT "GoalEntry_goalId_fkey" FOREIGN KEY ("goalId") REFERENCES "Goal"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GoalEntry" ADD CONSTRAINT "GoalEntry_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
