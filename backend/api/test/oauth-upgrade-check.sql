-- BE-P1-003: exact snapshots include credentials, timestamps and financial BigInt.
DO $$ BEGIN
  IF EXISTS ((TABLE "User" EXCEPT TABLE oauth_upgrade_users) UNION ALL (TABLE oauth_upgrade_users EXCEPT TABLE "User"))
    OR EXISTS ((TABLE "AuthSession" EXCEPT TABLE oauth_upgrade_sessions) UNION ALL (TABLE oauth_upgrade_sessions EXCEPT TABLE "AuthSession"))
    OR EXISTS ((TABLE "FinancialAccount" EXCEPT TABLE oauth_upgrade_accounts) UNION ALL (TABLE oauth_upgrade_accounts EXCEPT TABLE "FinancialAccount")) THEN
    RAISE EXCEPTION 'OAuth migration changed existing data';
  END IF;
  IF EXISTS (SELECT 1 FROM "OAuthIdentity") OR EXISTS (SELECT 1 FROM "OAuthChallenge") THEN
    RAISE EXCEPTION 'OAuth migration should not seed identities or challenges';
  END IF;
END $$;
