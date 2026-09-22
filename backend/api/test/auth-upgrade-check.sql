\set ON_ERROR_STOP on
DO $$ BEGIN
  IF (SELECT to_jsonb(u) - 'email' - 'passwordHash' - 'emailVerifiedAt' FROM "User" u)
    IS DISTINCT FROM (SELECT value - 'email' FROM auth_upgrade_user_snapshot) THEN
    RAISE EXCEPTION 'Legacy user fields changed';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM "User" WHERE "email" = 'legacy@example.test' AND "passwordHash" IS NULL AND "emailVerifiedAt" IS NULL) THEN
    RAISE EXCEPTION 'Unsafe legacy auth state';
  END IF;
  IF (SELECT to_jsonb(a) FROM "FinancialAccount" a) IS DISTINCT FROM (SELECT value FROM auth_upgrade_account_snapshot) THEN
    RAISE EXCEPTION 'Financial data changed';
  END IF;
  IF (SELECT to_jsonb(c) FROM "Currency" c) IS DISTINCT FROM (SELECT value FROM auth_upgrade_currency_snapshot) THEN
    RAISE EXCEPTION 'Existing currency catalog changed';
  END IF;
END $$;
