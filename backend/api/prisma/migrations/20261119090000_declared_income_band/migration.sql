-- BE-P6-002: onboarding asks for an income band, not an exact amount. Declared income (what the user states)
-- stays separate from actual income (averaged from transactions). A legacy exact amount becomes the band [x, x].
-- Additive enum values first; deploy before the API.
ALTER TYPE "GoalKind" ADD VALUE 'children' BEFORE 'custom';
ALTER TYPE "GoalKind" ADD VALUE 'business' BEFORE 'custom';
ALTER TYPE "GoalKind" ADD VALUE 'health' BEFORE 'custom';

ALTER TABLE "User" ADD COLUMN "declaredIncomeMinMinor" BIGINT, ADD COLUMN "declaredIncomeMaxMinor" BIGINT;

UPDATE "User" SET "declaredIncomeMinMinor" = "monthlyIncomeMinor", "declaredIncomeMaxMinor" = "monthlyIncomeMinor"
WHERE "monthlyIncomeMinor" IS NOT NULL;

ALTER TABLE "User" DROP CONSTRAINT "User_monthlyIncomeMinor_positive";
ALTER TABLE "User" DROP COLUMN "monthlyIncomeMinor";

-- Both null, or min >= 0 with max >= min; an open top band (max null) needs min > 0.
ALTER TABLE "User" ADD CONSTRAINT "User_declaredIncome_band" CHECK (
  ("declaredIncomeMinMinor" IS NULL AND "declaredIncomeMaxMinor" IS NULL)
  OR ("declaredIncomeMinMinor" IS NOT NULL AND "declaredIncomeMinMinor" >= 0 AND (
    ("declaredIncomeMaxMinor" IS NULL AND "declaredIncomeMinMinor" > 0)
    OR ("declaredIncomeMaxMinor" IS NOT NULL AND "declaredIncomeMaxMinor" >= "declaredIncomeMinMinor")
  ))
);

-- `onboarding.incomeSuggestionsVnd` is replaced by `onboarding.incomeBandsVnd`; reads already skip unknown keys,
-- this only drops the orphan row. The change log keeps its history.
DELETE FROM "AppConfigValue" WHERE "key" = 'onboarding.incomeSuggestionsVnd';
