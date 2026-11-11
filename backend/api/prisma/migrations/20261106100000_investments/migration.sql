-- BE-P4-E01 (ADR 014): investment positions. Money moves through one-leg `investment` transactions (not income or expense).
-- Additive. ALTER TYPE ADD VALUE runs first; deploy before the API.

ALTER TYPE "TransactionType" ADD VALUE 'investment';

CREATE TYPE "InvestmentKind" AS ENUM ('gold', 'stock', 'fund', 'savings_deposit', 'real_estate', 'crypto');
CREATE TYPE "InvestmentTradeSide" AS ENUM ('buy', 'sell');

CREATE TABLE "Investment" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "kind" "InvestmentKind" NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "currencyCode" CHAR(3) NOT NULL,
    "unit" VARCHAR(16) NOT NULL,
    "quantity" DECIMAL(28,8) NOT NULL,
    "costBasisMinor" BIGINT NOT NULL,
    "interestRateBps" INTEGER,
    "startDate" DATE,
    "maturityDate" DATE,
    "note" VARCHAR(500),
    "archivedAt" TIMESTAMPTZ,
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,
    CONSTRAINT "Investment_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Investment_quantity_check" CHECK ("quantity" >= 0),
    CONSTRAINT "Investment_cost_check" CHECK ("costBasisMinor" >= 0)
);

CREATE TABLE "InvestmentTrade" (
    "id" UUID NOT NULL,
    "investmentId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "side" "InvestmentTradeSide" NOT NULL,
    "quantity" DECIMAL(28,8) NOT NULL,
    "amountMinor" BIGINT NOT NULL,
    "realizedMinor" BIGINT,
    "accountId" UUID NOT NULL,
    "transactionClientId" UUID NOT NULL,
    "tradedOn" DATE NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "InvestmentTrade_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "InvestmentTrade_quantity_check" CHECK ("quantity" > 0),
    CONSTRAINT "InvestmentTrade_amount_check" CHECK ("amountMinor" > 0)
);

CREATE TABLE "InvestmentPrice" (
    "id" UUID NOT NULL,
    "investmentId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "priceMinor" BIGINT NOT NULL,
    "source" VARCHAR(16) NOT NULL DEFAULT 'manual',
    "quotedAt" TIMESTAMPTZ NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "InvestmentPrice_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "InvestmentPrice_price_check" CHECK ("priceMinor" >= 0)
);

CREATE UNIQUE INDEX "Investment_userId_clientId_key" ON "Investment"("userId", "clientId");
CREATE INDEX "Investment_userId_archivedAt_idx" ON "Investment"("userId", "archivedAt");
CREATE UNIQUE INDEX "InvestmentTrade_userId_clientId_key" ON "InvestmentTrade"("userId", "clientId");
CREATE INDEX "InvestmentTrade_investmentId_tradedOn_idx" ON "InvestmentTrade"("investmentId", "tradedOn");
CREATE UNIQUE INDEX "InvestmentPrice_userId_clientId_key" ON "InvestmentPrice"("userId", "clientId");
CREATE INDEX "InvestmentPrice_investmentId_quotedAt_idx" ON "InvestmentPrice"("investmentId", "quotedAt");

ALTER TABLE "Investment" ADD CONSTRAINT "Investment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Investment" ADD CONSTRAINT "Investment_currencyCode_fkey" FOREIGN KEY ("currencyCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "InvestmentTrade" ADD CONSTRAINT "InvestmentTrade_investmentId_fkey" FOREIGN KEY ("investmentId") REFERENCES "Investment"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "InvestmentTrade" ADD CONSTRAINT "InvestmentTrade_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "InvestmentTrade" ADD CONSTRAINT "InvestmentTrade_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "FinancialAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "InvestmentPrice" ADD CONSTRAINT "InvestmentPrice_investmentId_fkey" FOREIGN KEY ("investmentId") REFERENCES "Investment"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "InvestmentPrice" ADD CONSTRAINT "InvestmentPrice_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
