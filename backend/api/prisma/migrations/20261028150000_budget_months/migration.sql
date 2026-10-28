-- BE-P2-E02: per fiscal-month budget overrides.

CREATE TABLE "BudgetMonth" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "periodFrom" DATE NOT NULL,
    "periodTo" DATE NOT NULL,
    "currencyCode" CHAR(3) NOT NULL,
    "limitMinor" BIGINT NOT NULL,
    "alertThresholds" INTEGER[] NOT NULL DEFAULT ARRAY[]::INTEGER[],
    "version" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "BudgetMonth_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "BudgetMonthCategory" (
    "id" UUID NOT NULL,
    "monthId" UUID NOT NULL,
    "categoryId" UUID NOT NULL,
    "limitMinor" BIGINT NOT NULL,

    CONSTRAINT "BudgetMonthCategory_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "BudgetMonth_userId_periodFrom_key" ON "BudgetMonth"("userId", "periodFrom");
CREATE INDEX "BudgetMonth_userId_idx" ON "BudgetMonth"("userId");
CREATE UNIQUE INDEX "BudgetMonthCategory_monthId_categoryId_key" ON "BudgetMonthCategory"("monthId", "categoryId");
CREATE INDEX "BudgetMonthCategory_monthId_idx" ON "BudgetMonthCategory"("monthId");

ALTER TABLE "BudgetMonth" ADD CONSTRAINT "BudgetMonth_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BudgetMonth" ADD CONSTRAINT "BudgetMonth_currencyCode_fkey" FOREIGN KEY ("currencyCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "BudgetMonthCategory" ADD CONSTRAINT "BudgetMonthCategory_monthId_fkey" FOREIGN KEY ("monthId") REFERENCES "BudgetMonth"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BudgetMonthCategory" ADD CONSTRAINT "BudgetMonthCategory_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
