-- DS-P2-004: answers from the first-run questions (goals, how the person tracks money, how often they review).
ALTER TABLE "User" ADD COLUMN "onboardingGoals" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN "trackingHabit" VARCHAR(12),
ADD COLUMN "reviewCadence" VARCHAR(10);
