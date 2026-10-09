INSERT INTO "SchemaMeta" ("id", "version", "updatedAt")
VALUES (1, 1, CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;
