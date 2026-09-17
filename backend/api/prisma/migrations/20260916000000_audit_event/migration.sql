-- BE-P0-004: schema only; event writing and retention are separate work.
CREATE TYPE "AuditActorType" AS ENUM ('user', 'staff', 'system');
CREATE TYPE "AuditOutcome" AS ENUM ('success', 'failure', 'denied');

CREATE TABLE "AuditEvent" (
    "id" UUID NOT NULL,
    "actorType" "AuditActorType" NOT NULL,
    "actorId" UUID,
    "action" VARCHAR(100) NOT NULL,
    "targetType" VARCHAR(50) NOT NULL,
    "targetId" UUID,
    "outcome" "AuditOutcome" NOT NULL,
    "occurredAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditEvent_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "AuditEvent_actor_check" CHECK (
        ("actorType" IN ('user', 'staff') AND "actorId" IS NOT NULL)
        OR ("actorType" = 'system' AND "actorId" IS NULL)
    ),
    CONSTRAINT "AuditEvent_action_check" CHECK (
        "action" ~ '^[a-z][a-z0-9._]*$'
    ),
    CONSTRAINT "AuditEvent_targetType_check" CHECK (
        "targetType" ~ '^[a-z][a-z0-9._]*$'
    )
);

CREATE INDEX "AuditEvent_actorType_actorId_occurredAt_idx"
    ON "AuditEvent"("actorType", "actorId", "occurredAt");
CREATE INDEX "AuditEvent_targetType_targetId_occurredAt_idx"
    ON "AuditEvent"("targetType", "targetId", "occurredAt");
CREATE INDEX "AuditEvent_occurredAt_idx" ON "AuditEvent"("occurredAt");
