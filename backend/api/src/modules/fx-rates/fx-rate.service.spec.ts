import { FxRateService } from './fx-rate.service';
import type { FxRate, FxRateRepository } from './domain/fx-rate.repository';

const quotedAt = '2026-10-30T02:00:00.000Z';
function service(rates: FxRate[], defaultCurrency: string | null = 'VND') {
  const repository: FxRateRepository = {
    list: async () => rates,
    currencies: async () => [{ code: 'VND', minorDigits: 0 }, { code: 'USD', minorDigits: 2 }, { code: 'JPY', minorDigits: 0 }],
    defaultCurrency: async () => defaultCurrency,
    upsert: async (_userId, rate) => rate,
    remove: async () => true,
  };
  return new FxRateService(repository);
}

describe('BE-P2-013 detail conversion into the profile currency', () => {
  const usd: FxRate = { fromCode: 'USD', toCode: 'VND', rate: '25000.00000000', quotedAt };
  const jpy: FxRate = { fromCode: 'JPY', toCode: 'VND', rate: '170.50000000', quotedAt };

  it('returns the number with its rate and quotedAt', async () => {
    const convert = await service([usd]).toProfileCurrency('u');
    expect(convert(1234n, 'USD')).toEqual({ currencyCode: 'VND', amountMinor: '308500', rate: '25000.00000000', quotedAt });
    expect(convert(-1234n, 'USD')?.amountMinor).toBe('-308500');
  });

  it.each([
    ['same currency', 'VND', 5n],
    ['no rate for the pair', 'JPY', 5n],
  ])('returns null for %s', async (_name, currency, amount) => {
    const convert = await service([usd]).toProfileCurrency('u');
    expect(convert(amount, currency)).toBeNull();
  });

  it('returns null for a fractional result and never rounds', async () => {
    const convert = await service([jpy]).toProfileCurrency('u');
    expect(convert(1000n, 'JPY')?.amountMinor).toBe('170500');
    expect(convert(3n, 'JPY')).toBeNull();
  });

  it('returns null when the profile has no currency', async () => {
    expect((await service([usd], null).toProfileCurrency('u'))(100n, 'USD')).toBeNull();
  });

  it('saves rates in 8 decimals and rejects zero, same pair and unknown currency', async () => {
    const rates = service([]);
    await expect(rates.put('u', 'USD', 'VND', { rate: '25000.5', quotedAt })).resolves.toEqual({ fromCode: 'USD', toCode: 'VND', rate: '25000.50000000', quotedAt });
    for (const [from, to, rate] of [['USD', 'VND', '0'], ['USD', 'USD', '1'], ['USD', 'XXX', '1'], ['USD', 'VND', '1e3']]) {
      await expect(rates.put('u', from, to, { rate })).rejects.toMatchObject({ status: 400 });
    }
  });
});
