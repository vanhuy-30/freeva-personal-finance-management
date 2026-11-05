-- BE-P2-012: first monthly budget typed at onboarding, kept on the user in minor units of the default currency
-- at that time. Changing the profile currency later does not convert it.
ALTER TABLE "User" ADD COLUMN "onboardingBudgetMinor" BIGINT;
ALTER TABLE "User" ADD CONSTRAINT "User_onboardingBudgetMinor_positive" CHECK ("onboardingBudgetMinor" IS NULL OR "onboardingBudgetMinor" > 0);
