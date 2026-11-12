import { appConfigReaderFor } from '../app-config/testing';
import type { AutoSuggestPolicy } from '../category-suggestions/auto-suggest.policy';
import type { BudgetService } from '../budgets/budget.service';
import { buildInsights, type InsightInput, type InsightTransaction } from './domain/insight';
import type { InsightRepository } from './domain/insight.repository';
import { InsightService } from './insight.service';

let seq = 0;
const tx = (occurredOn: string, amount: number, categoryId: string | null, extra: Partial<InsightTransaction> = {}): InsightTransaction => ({
  id: `t${(seq += 1)}`, type: 'expense', amountMinor: BigInt(amount), categoryId, merchant: null, occurredOn, ...extra,
});
const categories = [
  { id: 'food', name: 'Ăn uống', parentId: null, iconToken: 'food', colorToken: null },
  { id: 'coffee', name: 'Cà phê', parentId: 'food', iconToken: 'coffee', colorToken: null },
  { id: 'shop', name: 'Mua sắm', parentId: null, iconToken: 'shopping', colorToken: null },
];
const settings = { outlierMultiplier: 2, outlierMonths: 3, minMonths: 2, budgetRiskPercent: 80, minChangePercent: 15 };
const previous = [{ from: '2026-10-01', to: '2026-10-31' }, { from: '2026-09-01', to: '2026-09-30' }, { from: '2026-08-01', to: '2026-08-31' }];
const base: InsightInput = { today: '2026-11-10', current: { from: '2026-11-01', to: '2026-11-30' }, previous, transactions: [], categories, budget: [], settings };
const history = [tx('2026-08-05', 400_000, 'shop'), tx('2026-09-05', 400_000, 'shop'), tx('2026-10-15', 460_000, 'shop')];

describe('BE-P5-E04 buildInsights', () => {
  it('compares the same days of last month, rolls children into their parent, and orders by priority', () => {
    const items = buildInsights({
      ...base,
      transactions: [
        ...history,
        tx('2026-10-03', 1_000_000, 'food'), tx('2026-10-08', 600_000, 'coffee'), tx('2026-10-20', 9_000_000, 'food'),
        tx('2026-11-02', 1_500_000, 'food'), tx('2026-11-06', 660_000, 'coffee'), tx('2026-11-08', 1_250_000, 'shop', { merchant: 'Điện máy Xanh' }),
      ],
      budget: [{ categoryId: null, spentMinor: 3_410_000n, limitMinor: 15_000_000n }, { categoryId: 'shop', spentMinor: 1_800_000n, limitMinor: 2_000_000n }],
    });
    expect(items.map(item => item.kind)).toEqual(['budget_risk', 'outlier', 'category_change', 'spend_trend']);
    expect(items[0]).toMatchObject({ category: { id: 'shop' }, percent: 90, daysLeft: 20, spentMinor: 1_800_000n });
    expect(items[1]).toMatchObject({ merchant: 'Điện máy Xanh', amountMinor: 1_250_000n, usualMinor: 420_000n, times: 2 });
    expect(items[2]).toMatchObject({ category: { id: 'food', name: 'Ăn uống' }, currentMinor: 2_160_000n, previousMinor: 1_600_000n, changePercent: 35, direction: 'up' });
    // 10 days: 3.41tr now vs 1.6tr on 1–10/10 (the 20/10 dinner is outside the window).
    expect(items[3]).toMatchObject({ kind: 'spend_trend', currentMinor: 3_410_000n, previousMinor: 1_600_000n, days: 10, direction: 'up' });
  });

  it('says nothing about changes below the threshold or without a base last month', () => {
    const quiet = buildInsights({ ...base, transactions: [...history, tx('2026-10-02', 1_000_000, 'food'), tx('2026-11-02', 1_100_000, 'food')] });
    expect(quiet.map(i => i.kind)).not.toContain('category_change');
    const fresh = buildInsights({ ...base, transactions: [tx('2026-11-02', 500_000, 'food')] });
    expect(fresh).toEqual([]);
  });

  it('drops the percent when there are fewer months of data than required, and reports decreases', () => {
    const items = buildInsights({ ...base, transactions: [tx('2026-10-02', 2_000_000, 'food'), tx('2026-11-02', 1_000_000, 'food')] });
    expect(items).toEqual([
      expect.objectContaining({ kind: 'category_change', changePercent: null, direction: 'down' }),
      expect.objectContaining({ kind: 'spend_trend', changePercent: null, direction: 'down' }),
    ]);
  });

  it('needs enough months for an outlier, nets refunds, and ignores budget lines below the threshold or of deleted categories', () => {
    const items = buildInsights({
      ...base,
      transactions: [tx('2026-10-05', 100_000, 'shop'), tx('2026-11-03', 900_000, 'shop'), tx('2026-11-04', 300_000, 'shop', { type: 'refund' })],
      budget: [{ categoryId: 'gone', spentMinor: 99n, limitMinor: 100n }, { categoryId: null, spentMinor: 70n, limitMinor: 100n }],
    });
    expect(items.map(i => i.kind)).toEqual(['category_change', 'spend_trend']);
    expect(items[0]).toMatchObject({ currentMinor: 600_000n, previousMinor: 100_000n });
  });
});

describe('BE-P5-E04 InsightService', () => {
  const repo = (): InsightRepository => ({
    profile: jest.fn().mockResolvedValue({ timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay: 1, defaultCurrencyCode: 'VND' }),
    ledger: jest.fn().mockResolvedValue({ transactions: [], categories }),
  });
  const budgets = (budget: object | null) => ({ current: jest.fn().mockResolvedValue({ budget }) }) as unknown as BudgetService;
  const policy = (on: boolean) => ({ allows: jest.fn().mockResolvedValue(on) }) as unknown as AutoSuggestPolicy;
  const now = new Date('2026-11-10T03:00:00Z');

  it('returns nothing and reads no ledger when insights are off', async () => {
    const r = repo();
    await expect(new InsightService(r, policy(false), budgets(null), appConfigReaderFor()).list('u1', now)).resolves.toEqual({ currencyCode: 'VND', period: null, items: [] });
    expect(r.ledger).not.toHaveBeenCalled();
  });

  it('loads three months back in the profile currency and serialises money as strings', async () => {
    const r = repo();
    const budget = { currencyCode: 'VND', spentMinor: '950', limitMinor: '1000', categories: [] };
    const result = await new InsightService(r, policy(true), budgets(budget), appConfigReaderFor()).list('u1', now);
    expect(r.ledger).toHaveBeenCalledWith('u1', 'VND', '2026-08-01', '2026-11-10');
    expect(result).toEqual({
      currencyCode: 'VND', period: { from: '2026-11-01', to: '2026-11-30', today: '2026-11-10' },
      items: [{ kind: 'budget_risk', category: null, spentMinor: '950', limitMinor: '1000', percent: 95, daysLeft: 20 }],
    });
  });

  it('ignores a budget in another currency', async () => {
    const budget = { currencyCode: 'USD', spentMinor: '950', limitMinor: '1000', categories: [] };
    const result = await new InsightService(repo(), policy(true), budgets(budget), appConfigReaderFor()).list('u1', now);
    expect(result.items).toEqual([]);
  });
});
