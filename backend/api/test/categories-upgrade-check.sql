DO $$
BEGIN
  IF (SELECT to_jsonb(u) - 'categoriesInitializedAt' FROM "User" u WHERE id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee') IS DISTINCT FROM
     (SELECT value FROM category_upgrade_snapshot WHERE kind = 'user') THEN RAISE EXCEPTION 'User changed'; END IF;
  IF (SELECT "categoriesInitializedAt" FROM "User" WHERE id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee') IS NOT NULL THEN RAISE EXCEPTION 'Unexpected initialization'; END IF;
  IF (SELECT to_jsonb(c) FROM "Category" c WHERE id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc') IS DISTINCT FROM
     (SELECT value FROM category_upgrade_snapshot WHERE kind = 'category') THEN RAISE EXCEPTION 'Category changed'; END IF;
  IF (SELECT to_jsonb(a) FROM "FinancialAccount" a WHERE id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') IS DISTINCT FROM
     (SELECT value FROM category_upgrade_snapshot WHERE kind = 'account') THEN RAISE EXCEPTION 'Account changed'; END IF;
  IF (SELECT to_jsonb(t) FROM "Transaction" t WHERE id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb') IS DISTINCT FROM
     (SELECT value FROM category_upgrade_snapshot WHERE kind = 'transaction') THEN RAISE EXCEPTION 'Transaction changed'; END IF;
END $$;
