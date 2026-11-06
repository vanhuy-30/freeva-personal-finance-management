-- BE-P4-E03 (ADR 014): a buy may be something the user already owned (no wallet leg), and every trade can carry a note.
-- Additive: existing rows keep their wallet and leg.

ALTER TABLE "InvestmentTrade" ALTER COLUMN "accountId" DROP NOT NULL;
ALTER TABLE "InvestmentTrade" ALTER COLUMN "transactionClientId" DROP NOT NULL;
ALTER TABLE "InvestmentTrade" ADD COLUMN "note" VARCHAR(500);
ALTER TABLE "InvestmentTrade" ADD CONSTRAINT "InvestmentTrade_wallet_check"
    CHECK (("accountId" IS NULL) = ("transactionClientId" IS NULL) AND ("side" = 'buy' OR "accountId" IS NOT NULL));
