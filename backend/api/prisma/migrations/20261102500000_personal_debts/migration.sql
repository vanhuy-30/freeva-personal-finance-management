-- BE-P3-007: lend / borrow. Money moves through one-leg `debt` transactions (not income or expense).
-- Additive. ALTER TYPE ADD VALUE runs in its own migration statement; deploy before the API.

ALTER TYPE "TransactionType" ADD VALUE 'debt';

CREATE TYPE "PersonalDebtDirection" AS ENUM ('lent', 'borrowed');

CREATE TABLE "PersonalDebt" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "direction" "PersonalDebtDirection" NOT NULL,
    "counterparty" VARCHAR(80) NOT NULL,
    "currencyCode" CHAR(3) NOT NULL,
    "principalMinor" BIGINT NOT NULL,
    "outstandingMinor" BIGINT NOT NULL,
    "accountId" UUID NOT NULL,
    "transactionClientId" UUID NOT NULL,
    "occurredOn" DATE NOT NULL,
    "dueDate" DATE,
    "note" VARCHAR(500),
    "archivedAt" TIMESTAMPTZ,
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,
    CONSTRAINT "PersonalDebt_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "PersonalDebt_principal_check" CHECK ("principalMinor" > 0),
    CONSTRAINT "PersonalDebt_outstanding_check" CHECK ("outstandingMinor" >= 0 AND "outstandingMinor" <= "principalMinor")
);

CREATE TABLE "PersonalDebtPayment" (
    "id" UUID NOT NULL,
    "debtId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "accountId" UUID NOT NULL,
    "amountMinor" BIGINT NOT NULL,
    "transactionClientId" UUID NOT NULL,
    "paidOn" DATE NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PersonalDebtPayment_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "PersonalDebtPayment_amount_check" CHECK ("amountMinor" > 0)
);

CREATE UNIQUE INDEX "PersonalDebt_userId_clientId_key" ON "PersonalDebt"("userId", "clientId");
CREATE INDEX "PersonalDebt_userId_archivedAt_idx" ON "PersonalDebt"("userId", "archivedAt");
CREATE UNIQUE INDEX "PersonalDebtPayment_userId_clientId_key" ON "PersonalDebtPayment"("userId", "clientId");
CREATE INDEX "PersonalDebtPayment_debtId_paidOn_idx" ON "PersonalDebtPayment"("debtId", "paidOn");

ALTER TABLE "PersonalDebt" ADD CONSTRAINT "PersonalDebt_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PersonalDebt" ADD CONSTRAINT "PersonalDebt_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "FinancialAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "PersonalDebt" ADD CONSTRAINT "PersonalDebt_currencyCode_fkey" FOREIGN KEY ("currencyCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "PersonalDebtPayment" ADD CONSTRAINT "PersonalDebtPayment_debtId_fkey" FOREIGN KEY ("debtId") REFERENCES "PersonalDebt"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PersonalDebtPayment" ADD CONSTRAINT "PersonalDebtPayment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PersonalDebtPayment" ADD CONSTRAINT "PersonalDebtPayment_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "FinancialAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
