-- BE-P2-E01: recurring transaction rules and occurrence ledger.

CREATE TYPE "RecurringUnit" AS ENUM ('day', 'week', 'month', 'year');

CREATE TABLE "RecurringRule" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "type" "TransactionType" NOT NULL,
    "unit" "RecurringUnit" NOT NULL,
    "interval" INTEGER NOT NULL,
    "amountMinor" BIGINT NOT NULL,
    "currencyCode" CHAR(3) NOT NULL,
    "accountId" UUID NOT NULL,
    "categoryId" UUID,
    "counterAccountId" UUID,
    "counterAmountMinor" BIGINT,
    "counterCurrencyCode" CHAR(3),
    "fxRate" DECIMAL(18,8),
    "startDate" DATE NOT NULL,
    "endDate" DATE,
    "nextExecutionDate" DATE NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "RecurringRule_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "RecurringOccurrence" (
    "id" UUID NOT NULL,
    "ruleId" UUID NOT NULL,
    "occurredOn" DATE NOT NULL,
    "transactionClientId" UUID NOT NULL,
    "counterClientId" UUID,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RecurringOccurrence_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "Transaction" ADD COLUMN "recurringRuleId" UUID;

CREATE UNIQUE INDEX "RecurringRule_userId_clientId_key" ON "RecurringRule"("userId", "clientId");
CREATE INDEX "RecurringRule_userId_active_nextExecutionDate_idx" ON "RecurringRule"("userId", "active", "nextExecutionDate");
CREATE UNIQUE INDEX "RecurringOccurrence_ruleId_occurredOn_key" ON "RecurringOccurrence"("ruleId", "occurredOn");
CREATE INDEX "RecurringOccurrence_ruleId_idx" ON "RecurringOccurrence"("ruleId");
CREATE INDEX "Transaction_recurringRuleId_idx" ON "Transaction"("recurringRuleId");

ALTER TABLE "RecurringRule" ADD CONSTRAINT "RecurringRule_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "RecurringRule" ADD CONSTRAINT "RecurringRule_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "FinancialAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "RecurringRule" ADD CONSTRAINT "RecurringRule_counterAccountId_fkey" FOREIGN KEY ("counterAccountId") REFERENCES "FinancialAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "RecurringRule" ADD CONSTRAINT "RecurringRule_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "RecurringRule" ADD CONSTRAINT "RecurringRule_currencyCode_fkey" FOREIGN KEY ("currencyCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "RecurringRule" ADD CONSTRAINT "RecurringRule_counterCurrencyCode_fkey" FOREIGN KEY ("counterCurrencyCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "RecurringOccurrence" ADD CONSTRAINT "RecurringOccurrence_ruleId_fkey" FOREIGN KEY ("ruleId") REFERENCES "RecurringRule"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_recurringRuleId_fkey" FOREIGN KEY ("recurringRuleId") REFERENCES "RecurringRule"("id") ON DELETE SET NULL ON UPDATE CASCADE;
