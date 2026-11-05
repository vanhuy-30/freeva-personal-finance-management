-- BE-P3-001: bills merge into recurring rules. A remind rule never posts on its own;
-- a user confirm writes a RecurringOccurrence. The Bill table is kept for rollback.

CREATE TYPE "RecurringMode" AS ENUM ('auto', 'remind');

ALTER TABLE "RecurringRule"
    ALTER COLUMN "accountId" DROP NOT NULL,
    ADD COLUMN "mode" "RecurringMode" NOT NULL DEFAULT 'auto',
    ADD COLUMN "name" VARCHAR(80),
    ADD COLUMN "amountKind" "BillAmountKind" NOT NULL DEFAULT 'fixed',
    ADD COLUMN "remindDaysBefore" INTEGER NOT NULL DEFAULT 3,
    ADD CONSTRAINT "RecurringRule_remind_days_check" CHECK ("remindDaysBefore" >= 0 AND "remindDaysBefore" <= 30),
    ADD CONSTRAINT "RecurringRule_mode_shape_check" CHECK (
        ("mode" = 'auto' AND "accountId" IS NOT NULL)
        OR ("mode" = 'remind' AND "type" = 'expense' AND "name" IS NOT NULL)
    );

-- Bills become one-off remind rules with the same id and clientId. Unpaid bills tied to an
-- auto rule are dropped (the rule already posts them); paid ones keep their transaction link.
INSERT INTO "RecurringRule" (
    "id", "userId", "clientId", "type", "unit", "interval", "amountMinor", "currencyCode",
    "startDate", "endDate", "nextExecutionDate", "active", "mode", "name", "amountKind",
    "version", "createdAt", "updatedAt"
)
SELECT
    b."id", b."userId", b."clientId", 'expense', 'month', 1, -b."amountMinor", b."currencyCode",
    b."dueOn", b."dueOn", b."dueOn", b."paidTransactionId" IS NULL, 'remind', b."name", b."amountKind",
    1, b."createdAt", CURRENT_TIMESTAMP
FROM "Bill" b
WHERE b."recurringRuleId" IS NULL OR b."paidTransactionId" IS NOT NULL;

INSERT INTO "RecurringOccurrence" ("id", "ruleId", "occurredOn", "transactionClientId", "createdAt")
SELECT gen_random_uuid(), b."id", b."dueOn", t."clientId", CURRENT_TIMESTAMP
FROM "Bill" b
JOIN "Transaction" t ON t."id" = b."paidTransactionId"
WHERE b."paidTransactionId" IS NOT NULL
  AND EXISTS (SELECT 1 FROM "RecurringRule" r WHERE r."id" = b."id");
