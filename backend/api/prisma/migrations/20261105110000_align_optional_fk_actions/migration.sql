-- The schema declares ON DELETE SET NULL on these optional references; the earlier migrations did not create them that way.
-- DropForeignKey
ALTER TABLE "Loan" DROP CONSTRAINT "Loan_accountId_fkey";

-- DropForeignKey
ALTER TABLE "RecurringRule" DROP CONSTRAINT "RecurringRule_accountId_fkey";

-- DropForeignKey
ALTER TABLE "RecurringRule" DROP CONSTRAINT "RecurringRule_categoryId_fkey";

-- DropForeignKey
ALTER TABLE "RecurringRule" DROP CONSTRAINT "RecurringRule_counterAccountId_fkey";

-- DropForeignKey
ALTER TABLE "RecurringRule" DROP CONSTRAINT "RecurringRule_counterCurrencyCode_fkey";

-- DropForeignKey
ALTER TABLE "User" DROP CONSTRAINT "User_displayCurrencyCode_fkey";

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_displayCurrencyCode_fkey" FOREIGN KEY ("displayCurrencyCode") REFERENCES "Currency"("code") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringRule" ADD CONSTRAINT "RecurringRule_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "FinancialAccount"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringRule" ADD CONSTRAINT "RecurringRule_counterAccountId_fkey" FOREIGN KEY ("counterAccountId") REFERENCES "FinancialAccount"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringRule" ADD CONSTRAINT "RecurringRule_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringRule" ADD CONSTRAINT "RecurringRule_counterCurrencyCode_fkey" FOREIGN KEY ("counterCurrencyCode") REFERENCES "Currency"("code") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Loan" ADD CONSTRAINT "Loan_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "FinancialAccount"("id") ON DELETE SET NULL ON UPDATE CASCADE;

