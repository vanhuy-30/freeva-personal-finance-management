-- DS-P2-003: feedback from the Góp ý screen. Text only, removed with the account.
CREATE TABLE "Feedback" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "kind" VARCHAR(10) NOT NULL,
    "topic" VARCHAR(20) NOT NULL,
    "message" VARCHAR(2000) NOT NULL,
    "allowReply" BOOLEAN NOT NULL,
    "appVersion" VARCHAR(30) NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Feedback_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Feedback_userId_createdAt_idx" ON "Feedback"("userId", "createdAt");

ALTER TABLE "Feedback" ADD CONSTRAINT "Feedback_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
