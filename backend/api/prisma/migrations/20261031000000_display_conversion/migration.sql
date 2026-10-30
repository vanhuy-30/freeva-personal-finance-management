-- BE-P2-013: display-only conversion. Display currency on the user, user-typed rates in their own table.
ALTER TABLE "User" ADD COLUMN "displayCurrencyCode" CHAR(3);
ALTER TABLE "User" ADD CONSTRAINT "User_displayCurrencyCode_fkey" FOREIGN KEY ("displayCurrencyCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE "UserFxRate" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "fromCode" CHAR(3) NOT NULL,
  "toCode" CHAR(3) NOT NULL,
  "rate" DECIMAL(18,8) NOT NULL,
  "quotedAt" TIMESTAMPTZ NOT NULL,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "UserFxRate_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "UserFxRate_rate_positive" CHECK ("rate" > 0),
  CONSTRAINT "UserFxRate_distinct_codes" CHECK ("fromCode" <> "toCode")
);
CREATE UNIQUE INDEX "UserFxRate_userId_fromCode_toCode_key" ON "UserFxRate"("userId", "fromCode", "toCode");
ALTER TABLE "UserFxRate" ADD CONSTRAINT "UserFxRate_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "UserFxRate" ADD CONSTRAINT "UserFxRate_fromCode_fkey" FOREIGN KEY ("fromCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "UserFxRate" ADD CONSTRAINT "UserFxRate_toCode_fkey" FOREIGN KEY ("toCode") REFERENCES "Currency"("code") ON DELETE RESTRICT ON UPDATE CASCADE;
