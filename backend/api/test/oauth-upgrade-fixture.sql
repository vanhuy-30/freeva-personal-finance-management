-- BE-P1-003: run on a disposable database at the ADR 009 schema.
INSERT INTO "User" ("id", "email", "passwordHash", "defaultCurrencyCode", "updatedAt")
VALUES ('00000000-0000-4000-8000-000000000003', 'oauth-upgrade@example.test', 'fixture-hash', 'VND', now());
INSERT INTO "AuthSession" ("id", "userId", "tokenHash", "expiresAt")
VALUES ('00000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000003', repeat('a', 64), now() + interval '7 days');
INSERT INTO "FinancialAccount" ("id", "userId", "clientId", "name", "type", "currencyCode", "initialBalanceMinor", "updatedAt")
VALUES ('00000000-0000-4000-8000-000000000005', '00000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000006', 'Fixture', 'cash', 'VND', 9007199254740993, now());
CREATE TABLE oauth_upgrade_users AS TABLE "User";
CREATE TABLE oauth_upgrade_sessions AS TABLE "AuthSession";
CREATE TABLE oauth_upgrade_accounts AS TABLE "FinancialAccount";
