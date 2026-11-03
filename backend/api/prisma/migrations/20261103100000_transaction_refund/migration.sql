-- BE-P3-008: refunds. A refund is a one-leg positive row pointing at the expense it returns money for.
-- Additive; deploy before the API.

ALTER TYPE "TransactionType" ADD VALUE 'refund';

ALTER TABLE "Transaction" ADD COLUMN "refundOfId" UUID;

ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_refundOfId_fkey"
  FOREIGN KEY ("refundOfId") REFERENCES "Transaction"("id") ON DELETE NO ACTION ON UPDATE CASCADE;

CREATE INDEX "Transaction_refundOfId_idx" ON "Transaction"("refundOfId");
