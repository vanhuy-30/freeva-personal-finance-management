-- BE-P2-015: FCM push. Tokens live and die with their login session; inbox rows track whether a push was claimed.
CREATE TYPE "PushPlatform" AS ENUM ('ios', 'android');

CREATE TABLE "PushToken" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "sessionId" UUID NOT NULL,
  "token" VARCHAR(4096) NOT NULL,
  "platform" "PushPlatform" NOT NULL,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMPTZ NOT NULL,
  CONSTRAINT "PushToken_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "PushToken_sessionId_key" ON "PushToken"("sessionId");
CREATE UNIQUE INDEX "PushToken_token_key" ON "PushToken"("token");
CREATE INDEX "PushToken_userId_idx" ON "PushToken"("userId");
ALTER TABLE "PushToken" ADD CONSTRAINT "PushToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PushToken" ADD CONSTRAINT "PushToken_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "AuthSession"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "InAppNotification" ADD COLUMN "pushedAt" TIMESTAMPTZ;
-- Rows that exist before push shipped must never be pushed.
UPDATE "InAppNotification" SET "pushedAt" = CURRENT_TIMESTAMP;
CREATE INDEX "InAppNotification_pushedAt_createdAt_idx" ON "InAppNotification"("pushedAt", "createdAt");
