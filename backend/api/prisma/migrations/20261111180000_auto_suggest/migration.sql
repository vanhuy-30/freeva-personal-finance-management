-- PRD-P5-E01: user switch for automatic suggestions and the merchant → category list it learns.
-- Additive: existing users default to on; the new table starts empty (BE-P5-E03 fills it).

ALTER TABLE "User" ADD COLUMN "autoSuggestEnabled" BOOLEAN NOT NULL DEFAULT true;

CREATE TABLE "CategorySuggestionMapping" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "merchantKey" VARCHAR(200) NOT NULL,
    "merchant" VARCHAR(200) NOT NULL,
    "categoryId" UUID NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "CategorySuggestionMapping_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "CategorySuggestionMapping_userId_merchantKey_key" ON "CategorySuggestionMapping"("userId", "merchantKey");
CREATE INDEX "CategorySuggestionMapping_userId_updatedAt_idx" ON "CategorySuggestionMapping"("userId", "updatedAt");
CREATE INDEX "CategorySuggestionMapping_categoryId_idx" ON "CategorySuggestionMapping"("categoryId");

ALTER TABLE "CategorySuggestionMapping" ADD CONSTRAINT "CategorySuggestionMapping_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CategorySuggestionMapping" ADD CONSTRAINT "CategorySuggestionMapping_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE CASCADE ON UPDATE CASCADE;
