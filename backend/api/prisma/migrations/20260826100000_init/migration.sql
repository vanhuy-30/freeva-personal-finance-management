-- CreateTable
CREATE TABLE "SchemaMeta" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "version" INTEGER NOT NULL DEFAULT 1,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SchemaMeta_pkey" PRIMARY KEY ("id")
);
