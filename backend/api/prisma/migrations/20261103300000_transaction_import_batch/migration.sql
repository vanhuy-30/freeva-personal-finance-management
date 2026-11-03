-- BE-P3-011: CSV import batches so a whole import can be undone. Additive; existing rows keep a NULL batch.

CREATE TABLE "ImportBatch" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "preset" VARCHAR(20) NOT NULL,
    "rowCount" INTEGER NOT NULL,
    "createdCount" INTEGER NOT NULL,
    "duplicateCount" INTEGER NOT NULL,
    "invalidCount" INTEGER NOT NULL,
    "undoneAt" TIMESTAMPTZ,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ImportBatch_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "ImportBatch_counts_check" CHECK ("rowCount" >= 0 AND "createdCount" >= 0 AND "duplicateCount" >= 0 AND "invalidCount" >= 0)
);

CREATE UNIQUE INDEX "ImportBatch_userId_clientId_key" ON "ImportBatch"("userId", "clientId");
CREATE INDEX "ImportBatch_userId_createdAt_idx" ON "ImportBatch"("userId", "createdAt");

ALTER TABLE "ImportBatch" ADD CONSTRAINT "ImportBatch_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Transaction" ADD COLUMN "importBatchId" UUID;
CREATE INDEX "Transaction_importBatchId_idx" ON "Transaction"("importBatchId");
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_importBatchId_fkey" FOREIGN KEY ("importBatchId") REFERENCES "ImportBatch"("id") ON DELETE SET NULL ON UPDATE CASCADE;
