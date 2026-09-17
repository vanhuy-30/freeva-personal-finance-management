\set ON_ERROR_STOP on
-- Disposable database only: seed BEFORE applying the audit migration.
INSERT INTO "Currency" ("code", "minorDigits", "name") VALUES ('VND', 0, 'Vietnam Dong');
INSERT INTO "User" ("id", "email", "defaultCurrencyCode", "updatedAt")
VALUES ('00000000-0000-4000-8000-000000000101', 'upgrade-fixture@example.invalid', 'VND', now());
INSERT INTO "FinancialAccount" ("id", "userId", "clientId", "name", "type", "currencyCode", "initialBalanceMinor", "updatedAt")
VALUES ('00000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000103', 'Fixture', 'cash', 'VND', 9007199254740993, now());
INSERT INTO "Transaction" ("id", "userId", "clientId", "type", "amountMinor", "currencyCode", "occurredOn", "accountId", "updatedAt")
VALUES ('00000000-0000-4000-8000-000000000104', '00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000105', 'expense', -12345, 'VND', '2026-09-16', '00000000-0000-4000-8000-000000000102', now());

-- Keep full snapshots to compare after deploy, including timestamps and BigInt.
CREATE TABLE audit_upgrade_user_snapshot AS TABLE "User";
CREATE TABLE audit_upgrade_account_snapshot AS TABLE "FinancialAccount";
CREATE TABLE audit_upgrade_transaction_snapshot AS TABLE "Transaction";
CREATE TABLE audit_upgrade_currency_snapshot AS TABLE "Currency";
