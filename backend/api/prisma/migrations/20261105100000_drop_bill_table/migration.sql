-- Bills became `remind` recurring rules in 20261102200000_recurring_remind_mode, which copied every
-- row across. The old table has no readers or writers left. The enum stays: RecurringRule.amountKind uses it.
DROP TABLE "Bill";
