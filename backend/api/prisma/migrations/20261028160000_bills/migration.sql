-- BE-P2-E03: bills (payment obligations linked optionally to a recurring rule / paid transaction).

CREATE TYPE "BillAmountKind" AS ENUM ('fixed', 'estimated');

CREATE TABLE "Bill" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "dueOn" DATE NOT NULL,
    "amountMinor" BIGINT NOT NULL,
    "amountKind" "BillAmountKind" NOT NULL,
    "currencyCode" CHAR(3) NOT NULL,
    "recurringRuleId" UUID,
    "paidTransactionId" UUID,
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Bill_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "Bill_userId_clientId_key" ON "Bill"("userId", "clientId");
CREATE UNIQUE INDEX "Bill_paidTransactionId_key" ON "Bill"("paidTransactionId");
CREATE INDEX "Bill_userId_dueOn_idx" ON "Bill"("userId", "dueOn");
CREATE INDEX "Bill_recurringRuleId_idx" ON "Bill"("recurringRuleId");

ALTER TABLE "Bill" ADD CONSTRAINT "Bill_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Bill" ADD CONSTRAINT "Bill_currencyCode_fkey" FOREIGN KEY ("currencyCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Bill" ADD CONSTRAINT "Bill_recurringRuleId_fkey" FOREIGN KEY ("recurringRuleId") REFERENCES "RecurringRule"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Bill" ADD CONSTRAINT "Bill_paidTransactionId_fkey" FOREIGN KEY ("paidTransactionId") REFERENCES "Transaction"("id") ON DELETE SET NULL ON UPDATE CASCADE;
