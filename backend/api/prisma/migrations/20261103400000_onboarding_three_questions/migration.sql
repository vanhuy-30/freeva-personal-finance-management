-- BE-P3-012: onboarding keeps three questions. Income replaces the typed budget; habit and cadence are dropped.
ALTER TABLE "User" DROP CONSTRAINT "User_onboardingBudgetMinor_positive";
ALTER TABLE "User" DROP COLUMN "trackingHabit", DROP COLUMN "reviewCadence", DROP COLUMN "onboardingBudgetMinor";
ALTER TABLE "User" ADD COLUMN "monthlyIncomeMinor" BIGINT;
ALTER TABLE "User" ADD CONSTRAINT "User_monthlyIncomeMinor_positive" CHECK ("monthlyIncomeMinor" IS NULL OR "monthlyIncomeMinor" > 0);

-- Goals: emergency folds into save; debt and understand are removed; at most two remain.
UPDATE "User" SET "onboardingGoals" = COALESCE((
  SELECT (ARRAY_AGG(g ORDER BY o))[1:2]
  FROM (
    SELECT g, MIN(o) AS o FROM (
      SELECT CASE WHEN x = 'emergency' THEN 'save' ELSE x END AS g, o
      FROM UNNEST("User"."onboardingGoals") WITH ORDINALITY AS t(x, o)
    ) m WHERE g IN ('track', 'save', 'budget') GROUP BY g
  ) d
), ARRAY[]::TEXT[])
WHERE cardinality("onboardingGoals") > 0;
