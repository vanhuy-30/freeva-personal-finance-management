-- BE-P5-E08: server feature flags and config edited from web admin. Additive; no rows means
-- every flag is off and every config key uses its code default.

CREATE TABLE "FeatureFlag" (
    "key" VARCHAR(64) NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "userIds" UUID[] NOT NULL DEFAULT ARRAY[]::UUID[],
    "percentage" SMALLINT NOT NULL DEFAULT 0,
    "version" INTEGER NOT NULL DEFAULT 1,
    "updatedAt" TIMESTAMPTZ NOT NULL,
    "updatedBy" UUID NOT NULL,
    CONSTRAINT "FeatureFlag_pkey" PRIMARY KEY ("key"),
    CONSTRAINT "FeatureFlag_percentage_check" CHECK ("percentage" >= 0 AND "percentage" <= 100),
    CONSTRAINT "FeatureFlag_version_check" CHECK ("version" >= 1)
);

CREATE TABLE "AppConfigValue" (
    "key" VARCHAR(64) NOT NULL,
    "value" JSONB NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "updatedAt" TIMESTAMPTZ NOT NULL,
    "updatedBy" UUID NOT NULL,
    CONSTRAINT "AppConfigValue_pkey" PRIMARY KEY ("key"),
    CONSTRAINT "AppConfigValue_version_check" CHECK ("version" >= 1)
);

CREATE TABLE "AppConfigChange" (
    "id" UUID NOT NULL,
    "kind" VARCHAR(10) NOT NULL,
    "key" VARCHAR(64) NOT NULL,
    "before" JSONB,
    "after" JSONB,
    "actorId" UUID NOT NULL,
    "occurredAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AppConfigChange_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "AppConfigChange_kind_check" CHECK ("kind" IN ('flag', 'value'))
);

CREATE INDEX "AppConfigChange_key_occurredAt_idx" ON "AppConfigChange"("key", "occurredAt");

CREATE TABLE "AppConfigMeta" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "version" INTEGER NOT NULL DEFAULT 1,
    "updatedAt" TIMESTAMPTZ NOT NULL,
    CONSTRAINT "AppConfigMeta_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "AppConfigMeta_single_row_check" CHECK ("id" = 1)
);

INSERT INTO "AppConfigMeta" ("id", "version", "updatedAt")
VALUES (1, 1, CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;
