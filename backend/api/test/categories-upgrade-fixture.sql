-- Only run against an isolated pre-BE-P1-006 database.
INSERT INTO "User" (id, email, "defaultCurrencyCode", "updatedAt")
VALUES ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'categories-upgrade@example.test', 'VND', now());
INSERT INTO "Category" (id, "userId", "clientId", name, "archivedAt", "updatedAt")
VALUES ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'Legacy custom', now(), now());
INSERT INTO "FinancialAccount" (id, "userId", "clientId", name, type, "currencyCode", "initialBalanceMinor", "updatedAt")
VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Legacy wallet', 'cash', 'VND', 9007199254740993, now());
INSERT INTO "Transaction" (id, "userId", "clientId", "accountId", type, "amountMinor", "currencyCode", "occurredOn", "categoryId", "deletedAt", "updatedAt")
VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'expense', -9007199254740993, 'VND', '2026-09-25', 'cccccccc-cccc-4ccc-8ccc-cccccccccccc', now(), now());
CREATE TABLE category_upgrade_snapshot (kind text PRIMARY KEY, value jsonb NOT NULL);
INSERT INTO category_upgrade_snapshot SELECT 'user', to_jsonb(u) FROM "User" u WHERE id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
INSERT INTO category_upgrade_snapshot SELECT 'category', to_jsonb(c) FROM "Category" c WHERE id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
INSERT INTO category_upgrade_snapshot SELECT 'account', to_jsonb(a) FROM "FinancialAccount" a WHERE id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
INSERT INTO category_upgrade_snapshot SELECT 'transaction', to_jsonb(t) FROM "Transaction" t WHERE id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
