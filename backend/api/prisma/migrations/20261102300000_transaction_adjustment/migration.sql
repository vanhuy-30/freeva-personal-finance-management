-- BE-P3-005: wallet reconciliation. An adjustment is a one-leg row that moves the wallet balance
-- but is not income or expense. Additive; deploy before the API.

ALTER TYPE "TransactionType" ADD VALUE 'adjustment';
