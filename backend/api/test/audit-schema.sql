\set ON_ERROR_STOP on
-- Run only against a disposable test database after migrate deploy.
-- All fixture data and test helpers are rolled back, even on failure.
BEGIN;

CREATE FUNCTION pg_temp.expect_error(statement text, expected_state text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE statement;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = expected_state THEN RETURN; END IF;
    RAISE;
  END;
  RAISE EXCEPTION 'Expected SQLSTATE %, but statement succeeded', expected_state;
END;
$$;

INSERT INTO "Currency" ("code", "minorDigits", "name") VALUES ('TST', 0, 'Test');
INSERT INTO "User" ("id", "email", "defaultCurrencyCode", "updatedAt")
VALUES ('00000000-0000-4000-8000-000000000001', 'audit-fixture@example.invalid', 'TST', now());

INSERT INTO "AuditEvent" ("id", "actorType", "actorId", "action", "targetType", "targetId", "outcome") VALUES
('00000000-0000-4000-8000-000000000011', 'user', '00000000-0000-4000-8000-000000000001', 'user.export', 'user', '00000000-0000-4000-8000-000000000001', 'success'),
('00000000-0000-4000-8000-000000000012', 'staff', '00000000-0000-4000-8000-000000000002', 'staff.user_lookup', 'user', '00000000-0000-4000-8000-000000000001', 'denied'),
('00000000-0000-4000-8000-000000000013', 'system', NULL, 'system.job_1', 'job', NULL, 'failure');

-- Table clone carries actual CHECK/NOT NULL/type constraints and indexes.
CREATE TEMP TABLE audit_candidate (LIKE "AuditEvent" INCLUDING ALL);
INSERT INTO audit_candidate SELECT * FROM "AuditEvent" WHERE "id" = '00000000-0000-4000-8000-000000000011';
SELECT pg_temp.expect_error('UPDATE audit_candidate SET "actorId" = NULL', '23514');
SELECT pg_temp.expect_error('UPDATE audit_candidate SET "actorType" = ''staff'', "actorId" = NULL', '23514');
SELECT pg_temp.expect_error('UPDATE audit_candidate SET "actorType" = ''system''', '23514');
SELECT pg_temp.expect_error('UPDATE audit_candidate SET "actorType" = ''unknown''', '22P02');
SELECT pg_temp.expect_error('UPDATE audit_candidate SET "outcome" = ''unknown''', '22P02');
SELECT pg_temp.expect_error('UPDATE audit_candidate SET "outcome" = NULL', '23502');
SELECT pg_temp.expect_error('UPDATE audit_candidate SET "actorId" = ''invalid-uuid''', '22P02');
SELECT pg_temp.expect_error('UPDATE audit_candidate SET "action" = repeat(''a'', 101)', '22001');
SELECT pg_temp.expect_error('UPDATE audit_candidate SET "targetType" = repeat(''a'', 51)', '22001');
SELECT pg_temp.expect_error('INSERT INTO "AuditEvent" SELECT * FROM audit_candidate', '23505');

DO $$
DECLARE
  invalid_code text;
  column_name text;
BEGIN
  FOREACH column_name IN ARRAY ARRAY['action', 'targetType'] LOOP
    FOREACH invalid_code IN ARRAY ARRAY['', 'Upper', '1start', '_start', '.start', 'two words', 'a-b', 'a@b', E'a\nb', E'a\n', 'é'] LOOP
      PERFORM pg_temp.expect_error(format('UPDATE audit_candidate SET %I = %L', column_name, invalid_code), '23514');
    END LOOP;
  END LOOP;
  IF EXISTS (SELECT 1 FROM "AuditEvent" WHERE "id" IN (
      '00000000-0000-4000-8000-000000000011', '00000000-0000-4000-8000-000000000012', '00000000-0000-4000-8000-000000000013'
    ) AND ("occurredAt" <> transaction_timestamp() OR "createdAt" <> transaction_timestamp())) THEN
    RAISE EXCEPTION 'Timestamp defaults differ from transaction time';
  END IF;
  IF (SELECT count(*) FROM pg_indexes WHERE schemaname = current_schema() AND tablename = 'AuditEvent'
      AND indexname IN ('AuditEvent_actorType_actorId_occurredAt_idx', 'AuditEvent_targetType_targetId_occurredAt_idx', 'AuditEvent_occurredAt_idx')) <> 3 THEN
    RAISE EXCEPTION 'Missing audit indexes';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = '"AuditEvent"'::regclass AND contype = 'f') THEN
    RAISE EXCEPTION 'Audit must not have foreign keys';
  END IF;
END;
$$;

-- User is both actor and target. Deletion must not remove historical events.
DELETE FROM "User" WHERE "id" = '00000000-0000-4000-8000-000000000001';
DO $$
BEGIN
  IF (SELECT count(*) FROM "AuditEvent" WHERE "targetId" = '00000000-0000-4000-8000-000000000001') <> 2 THEN
    RAISE EXCEPTION 'Audit lost after deleting target/actor';
  END IF;
END;
$$;
ROLLBACK;
\echo Audit schema checks passed (fixtures rolled back).
