BEGIN;

-- Fail explicitly on legacy normalization collisions; never merge financial identities.
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM "User" GROUP BY lower(btrim("email")) HAVING count(*) > 1) THEN
    RAISE EXCEPTION 'Email normalization collision: resolve legacy identities before migrating';
  END IF;
END $$;
UPDATE "User" SET "email" = lower(btrim("email"));
ALTER TABLE "User" ADD CONSTRAINT "User_email_normalized_check" CHECK ("email" = lower(btrim("email")));
-- Required by the existing User.defaultCurrency FK for new registrations.
INSERT INTO "Currency" ("code", "minorDigits", "name") VALUES ('VND', 0, 'Vietnamese dong') ON CONFLICT ("code") DO NOTHING;

-- CreateEnum
CREATE TYPE "AuthTokenPurpose" AS ENUM ('verify_email', 'reset_password');

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "emailVerifiedAt" TIMESTAMPTZ,
ADD COLUMN     "passwordHash" TEXT;

-- CreateTable
CREATE TABLE "AuthToken" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "purpose" "AuthTokenPurpose" NOT NULL,
    "tokenHash" CHAR(64) NOT NULL,
    "expiresAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "AuthToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuthSession" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "tokenHash" CHAR(64) NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "AuthSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuthRateLimit" (
    "key" CHAR(64) NOT NULL,
    "count" INTEGER NOT NULL,
    "expiresAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "AuthRateLimit_pkey" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "AuthMailJob" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "purpose" "AuthTokenPurpose" NOT NULL,
    "encryptedToken" TEXT NOT NULL,
    "expiresAt" TIMESTAMPTZ NOT NULL,
    "availableAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuthMailJob_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "AuthToken_tokenHash_key" ON "AuthToken"("tokenHash");

-- CreateIndex
CREATE INDEX "AuthToken_expiresAt_idx" ON "AuthToken"("expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "AuthToken_userId_purpose_key" ON "AuthToken"("userId", "purpose");

-- CreateIndex
CREATE UNIQUE INDEX "AuthSession_tokenHash_key" ON "AuthSession"("tokenHash");

-- CreateIndex
CREATE INDEX "AuthSession_userId_createdAt_idx" ON "AuthSession"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "AuthSession_expiresAt_idx" ON "AuthSession"("expiresAt");

-- CreateIndex
CREATE INDEX "AuthRateLimit_expiresAt_idx" ON "AuthRateLimit"("expiresAt");

-- CreateIndex
CREATE INDEX "AuthMailJob_availableAt_idx" ON "AuthMailJob"("availableAt");

-- CreateIndex
CREATE UNIQUE INDEX "AuthMailJob_userId_purpose_key" ON "AuthMailJob"("userId", "purpose");

-- AddForeignKey
ALTER TABLE "AuthToken" ADD CONSTRAINT "AuthToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuthSession" ADD CONSTRAINT "AuthSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuthMailJob" ADD CONSTRAINT "AuthMailJob_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;


COMMIT;
