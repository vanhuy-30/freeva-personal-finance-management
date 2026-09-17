\set ON_ERROR_STOP on
DO $$
DECLARE
  pair text[];
  changed boolean;
BEGIN
  FOREACH pair SLICE 1 IN ARRAY ARRAY[
    ['User', 'audit_upgrade_user_snapshot'],
    ['FinancialAccount', 'audit_upgrade_account_snapshot'],
    ['Transaction', 'audit_upgrade_transaction_snapshot'],
    ['Currency', 'audit_upgrade_currency_snapshot']
  ] LOOP
    EXECUTE format('SELECT EXISTS ((TABLE %I EXCEPT ALL TABLE %I) UNION ALL (TABLE %I EXCEPT ALL TABLE %I))', pair[1], pair[2], pair[2], pair[1]) INTO changed;
    IF changed THEN RAISE EXCEPTION 'Existing data changed: %', pair[1]; END IF;
  END LOOP;
END;
$$;
\echo Upgrade preserved all fixture data.
