-- BE-P3-E02 follow-up: the principal part of a loan payment lowers a debt, it is not spending.
-- Turn the principal legs already written as `expense` into one-leg `debt` rows (outside income/expense,
-- budgets and savings rate; still in the wallet balance, export and ledger). The interest leg stays an expense.
-- Rows that carry a refund or a card instalment plan are left alone. version bumps so devices refetch.

UPDATE "Transaction" t
SET "type" = 'debt',
    "categoryId" = NULL,
    "merchant" = NULL,
    "version" = t."version" + 1,
    "updatedAt" = NOW()
FROM "LoanPayment" p
WHERE p."principalTransactionClientId" IS NOT NULL
  AND t."userId" = p."userId"
  AND t."clientId" = p."principalTransactionClientId"
  AND t."type" = 'expense'
  AND NOT EXISTS (SELECT 1 FROM "Transaction" r WHERE r."refundOfId" = t."id")
  AND NOT EXISTS (SELECT 1 FROM "CardInstallmentPlan" c WHERE c."transactionId" = t."id");
