CREATE TYPE "OAuthProvider" AS ENUM ('google', 'apple');
CREATE TABLE "OAuthIdentity" (
  "id" UUID NOT NULL,
  "provider" "OAuthProvider" NOT NULL,
  "subject" VARCHAR(255) NOT NULL,
  "userId" UUID NOT NULL,
  CONSTRAINT "OAuthIdentity_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "OAuthIdentity_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "OAuthIdentity_provider_subject_key" ON "OAuthIdentity"("provider", "subject");
CREATE UNIQUE INDEX "OAuthIdentity_userId_provider_key" ON "OAuthIdentity"("userId", "provider");
CREATE TABLE "OAuthChallenge" (
  "tokenHash" CHAR(64) NOT NULL,
  "provider" "OAuthProvider" NOT NULL,
  "expiresAt" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "OAuthChallenge_pkey" PRIMARY KEY ("tokenHash")
);
CREATE INDEX "OAuthChallenge_expiresAt_idx" ON "OAuthChallenge"("expiresAt");
