-- DS-P2-006: the default "Hóa đơn" root shows the electricity icon (canvas).
-- Only untouched system rows: same name, still the old icon.
UPDATE "Category"
SET "iconToken" = 'electricity', "updatedAt" = NOW()
WHERE "isSystem" = true
  AND "name" = 'Hóa đơn'
  AND "parentId" IS NULL
  AND "iconToken" = 'bills';
