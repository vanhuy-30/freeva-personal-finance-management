\set ON_ERROR_STOP on
-- Run on the three-migration baseline in an isolated database.
INSERT INTO "Currency" ("code", "minorDigits", "name") VALUES ('VND', 0, 'Vietnam Dong');
INSERT INTO "User" ("id", "email", "defaultCurrencyCode", "updatedAt")
VALUES ('00000000-0000-4000-8000-000000000101', ' Legacy@Example.Test ', 'VND', now());
INSERT INTO "FinancialAccount" ("id", "userId", "clientId", "name", "type", "currencyCode", "initialBalanceMinor", "updatedAt")
VALUES ('00000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000103', 'Fixture', 'cash', 'VND', 9007199254740993, now());
CREATE TABLE auth_upgrade_user_snapshot AS SELECT to_jsonb(u) AS value FROM "User" u;
CREATE TABLE auth_upgrade_account_snapshot AS SELECT to_jsonb(a) AS value FROM "FinancialAccount" a;
CREATE TABLE auth_upgrade_currency_snapshot AS SELECT to_jsonb(c) AS value FROM "Currency" c;
