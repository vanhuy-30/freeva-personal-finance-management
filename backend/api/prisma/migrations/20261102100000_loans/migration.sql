-- BE-P3-E02: loans and debts. Money changes go through LoanPayment (expense transactions) or audit.

CREATE TYPE "LoanKind" AS ENUM ('card', 'personal', 'mortgage', 'other');
CREATE TYPE "LoanFrequency" AS ENUM ('weekly', 'monthly', 'quarterly', 'yearly');

CREATE TABLE "Loan" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "kind" "LoanKind" NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "currencyCode" CHAR(3) NOT NULL,
    "principalMinor" BIGINT NOT NULL,
    "outstandingMinor" BIGINT NOT NULL,
    "interestRateBps" INTEGER NOT NULL DEFAULT 0,
    "installmentMinor" BIGINT,
    "frequency" "LoanFrequency" NOT NULL DEFAULT 'monthly',
    "startDate" DATE NOT NULL,
    "endDate" DATE,
    "nextDueDate" DATE,
    "accountId" UUID,
    "archivedAt" TIMESTAMPTZ,
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,
    CONSTRAINT "Loan_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Loan_principal_check" CHECK ("principalMinor" > 0),
    CONSTRAINT "Loan_outstanding_check" CHECK ("outstandingMinor" >= 0),
    CONSTRAINT "Loan_rate_check" CHECK ("interestRateBps" >= 0 AND "interestRateBps" <= 100000),
    CONSTRAINT "Loan_installment_check" CHECK ("installmentMinor" IS NULL OR "installmentMinor" >= 0)
);

CREATE TABLE "LoanPayment" (
    "id" UUID NOT NULL,
    "loanId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "principalMinor" BIGINT NOT NULL,
    "interestMinor" BIGINT NOT NULL,
    "principalTransactionClientId" UUID,
    "interestTransactionClientId" UUID,
    "paidOn" DATE NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "LoanPayment_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "LoanPayment_amount_check" CHECK ("principalMinor" >= 0 AND "interestMinor" >= 0 AND "principalMinor" + "interestMinor" > 0)
);

CREATE UNIQUE INDEX "Loan_userId_clientId_key" ON "Loan"("userId", "clientId");
CREATE INDEX "Loan_userId_archivedAt_idx" ON "Loan"("userId", "archivedAt");
CREATE UNIQUE INDEX "LoanPayment_userId_clientId_key" ON "LoanPayment"("userId", "clientId");
CREATE INDEX "LoanPayment_loanId_paidOn_idx" ON "LoanPayment"("loanId", "paidOn");

ALTER TABLE "Loan" ADD CONSTRAINT "Loan_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Loan" ADD CONSTRAINT "Loan_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "FinancialAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Loan" ADD CONSTRAINT "Loan_currencyCode_fkey" FOREIGN KEY ("currencyCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "LoanPayment" ADD CONSTRAINT "LoanPayment_loanId_fkey" FOREIGN KEY ("loanId") REFERENCES "Loan"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "LoanPayment" ADD CONSTRAINT "LoanPayment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
