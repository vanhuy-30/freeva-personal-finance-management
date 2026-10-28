import {
  budgetStatus,
  categorySpent,
  crossedThresholds,
  descendantIds,
  normalizeAlertThresholds,
  percentBps,
  progress,
  totalSpent,
  type CategoryRef,
  type ExpenseRow,
} from './budget';

const VND = 'VND';
const USD = 'USD';
const food = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const lunch = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const rent = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

const categories: CategoryRef[] = [
  { id: food, parentId: null, kind: 'expense', archivedAt: null },
  { id: lunch, parentId: food, kind: 'expense', archivedAt: null },
  { id: rent, parentId: null, kind: 'expense', archivedAt: null },
];

function row(partial: Partial<ExpenseRow> & Pick<ExpenseRow, 'type' | 'amountMinor'>): ExpenseRow {
  return {
    currencyCode: VND,
    categoryId: food,
    deletedAt: null,
    ...partial,
  };
}

describe('BE-P2-E02 budget spend and status', () => {
  const limit = 10_000_000n;
  const rows: ExpenseRow[] = [
    row({ type: 'expense', amountMinor: -3_000_000n, categoryId: food }),
    row({ type: 'income', amountMinor: 5_000_000n, categoryId: null }),
    row({ type: 'transfer', amountMinor: -1_000_000n, categoryId: null }),
    row({ type: 'expense', amountMinor: -500_000n, categoryId: food, deletedAt: new Date('2026-10-01T00:00:00Z') }),
    row({ type: 'expense', amountMinor: -200n, currencyCode: USD, categoryId: food }),
  ];

  it('counts only non-deleted expenses in the budget currency', () => {
    expect(totalSpent(rows, VND)).toBe(3_000_000n);
  });

  it.each([
    { spent: 6_999_999n, status: 'healthy' },
    { spent: 7_000_000n, status: 'warning' },
    { spent: 9_000_000n, status: 'warning' },
    { spent: 9_000_001n, status: 'critical' },
    { spent: 10_000_000n, status: 'critical' },
    { spent: 10_000_001n, status: 'over' },
  ] as const)('status at $spent / 10000000 is $status', ({ spent, status }) => {
    expect(budgetStatus(spent, limit)).toBe(status);
  });

  it('reports percent as integer basis points', () => {
    expect(percentBps(7_000_000n, limit)).toBe(7000);
    expect(percentBps(0n, limit)).toBe(0);
  });

  it('lists crossed alert thresholds without floating point', () => {
    expect(crossedThresholds(7_000_000n, limit, [70, 80, 90, 100])).toEqual([70]);
    expect(crossedThresholds(10_000_000n, limit, [70, 80, 90, 100])).toEqual([70, 80, 90, 100]);
    expect(crossedThresholds(6_999_999n, limit, [70, 80, 90, 100])).toEqual([]);
  });

  it('builds progress remaining and status together', () => {
    expect(progress(3_000_000n, limit)).toEqual({
      limitMinor: limit,
      spentMinor: 3_000_000n,
      remainingMinor: 7_000_000n,
      percentBps: 3000,
      status: 'healthy',
    });
  });
});

describe('BE-P2-E02 category lines and thresholds', () => {
  it('sums a parent line with its descendants', () => {
    const rows: ExpenseRow[] = [
      { type: 'expense', amountMinor: -100n, currencyCode: VND, categoryId: food, deletedAt: null },
      { type: 'expense', amountMinor: -50n, currencyCode: VND, categoryId: lunch, deletedAt: null },
      { type: 'expense', amountMinor: -20n, currencyCode: VND, categoryId: rent, deletedAt: null },
      { type: 'expense', amountMinor: -5n, currencyCode: VND, categoryId: null, deletedAt: null },
    ];
    const children = descendantIds(food, categories);
    expect(children).toEqual(new Set([lunch]));
    expect(categorySpent(rows, VND, food, children)).toBe(150n);
    expect(categorySpent(rows, VND, lunch, descendantIds(lunch, categories))).toBe(50n);
    expect(totalSpent(rows, VND)).toBe(175n);
  });

  it('rejects invalid alert threshold lists', () => {
    expect(() => normalizeAlertThresholds([])).toThrow();
    expect(() => normalizeAlertThresholds([70, 70])).toThrow();
    expect(() => normalizeAlertThresholds([90, 80])).toThrow();
    expect(() => normalizeAlertThresholds([0, 100])).toThrow();
    expect(() => normalizeAlertThresholds([70, 80, 90, 100, 101])).toThrow();
    expect(normalizeAlertThresholds(undefined)).toEqual([70, 80, 90, 100]);
    expect(normalizeAlertThresholds([80, 100])).toEqual([80, 100]);
  });
});
