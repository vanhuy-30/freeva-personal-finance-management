-- CreateEnum
CREATE TYPE "CategoryKind" AS ENUM ('expense', 'income', 'both');

-- AlterTable
ALTER TABLE "User" ADD COLUMN "categoriesSupplementedAt" TIMESTAMPTZ;

-- AlterTable
ALTER TABLE "Category" ADD COLUMN "kind" "CategoryKind" NOT NULL DEFAULT 'both';
