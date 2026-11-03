-- BE-P3-009: schedule-only installment plan over one credit-card expense. Additive; moves no money.

CREATE TYPE "CardInstallmentStatus" AS ENUM ('active', 'closed');

CREATE TABLE "CardInstallmentPlan" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "transactionId" UUID NOT NULL,
    "accountId" UUID NOT NULL,
    "currencyCode" CHAR(3) NOT NULL,
    "totalMinor" BIGINT NOT NULL,
    "installmentMinor" BIGINT NOT NULL,
    "installmentCount" INTEGER NOT NULL,
    "firstDueOn" DATE NOT NULL,
    "status" "CardInstallmentStatus" NOT NULL DEFAULT 'active',
    "closedAt" TIMESTAMPTZ,
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,
    CONSTRAINT "CardInstallmentPlan_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "CardInstallmentPlan_total_check" CHECK ("totalMinor" > 0),
    CONSTRAINT "CardInstallmentPlan_installment_check" CHECK ("installmentMinor" > 0),
    CONSTRAINT "CardInstallmentPlan_count_check" CHECK ("installmentCount" BETWEEN 2 AND 60)
);

CREATE UNIQUE INDEX "CardInstallmentPlan_transactionId_key" ON "CardInstallmentPlan"("transactionId");
CREATE UNIQUE INDEX "CardInstallmentPlan_userId_clientId_key" ON "CardInstallmentPlan"("userId", "clientId");
CREATE INDEX "CardInstallmentPlan_userId_accountId_status_idx" ON "CardInstallmentPlan"("userId", "accountId", "status");

ALTER TABLE "CardInstallmentPlan" ADD CONSTRAINT "CardInstallmentPlan_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CardInstallmentPlan" ADD CONSTRAINT "CardInstallmentPlan_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "FinancialAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "CardInstallmentPlan" ADD CONSTRAINT "CardInstallmentPlan_currencyCode_fkey" FOREIGN KEY ("currencyCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "CardInstallmentPlan" ADD CONSTRAINT "CardInstallmentPlan_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "Transaction"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
