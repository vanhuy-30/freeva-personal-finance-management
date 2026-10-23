-- DS-P2-004: when a person agreed to the Terms and Privacy policy at email sign-up, and which version.
ALTER TABLE "User" ADD COLUMN "termsAcceptedAt" TIMESTAMPTZ,
ADD COLUMN "termsVersion" VARCHAR(20);
