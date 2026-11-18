-- BE-P6-001: sessions per device. Additive; existing sessions keep null device fields.

ALTER TABLE "AuthSession"
    ADD COLUMN "deviceId" UUID,
    ADD COLUMN "deviceName" VARCHAR(80),
    ADD COLUMN "platform" VARCHAR(16),
    ADD COLUMN "osVersion" VARCHAR(32),
    ADD COLUMN "lastUsedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX "AuthSession_userId_deviceId_idx" ON "AuthSession"("userId", "deviceId");
