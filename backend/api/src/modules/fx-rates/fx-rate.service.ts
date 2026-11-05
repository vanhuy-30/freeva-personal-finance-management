import { HttpException, Inject, Injectable } from '@nestjs/common';
import { convertWithBook, parseRate, type RateBook } from '../../core/money/convert';
import { FX_RATE_REPOSITORY, type FxRate, type FxRateRepository } from './domain/fx-rate.repository';

function error(status: number, code: string) {
  return new HttpException({ error: { code, message: 'Rate request could not be completed' } }, status);
}

export interface DisplayConverted { currencyCode: string; amountMinor: string; rate: string; quotedAt: string }

@Injectable()
export class FxRateService {
  constructor(@Inject(FX_RATE_REPOSITORY) private readonly repository: FxRateRepository) {}

  async list(userId: string) {
    return { items: await this.repository.list(userId) };
  }

  async put(userId: string, fromCode: string, toCode: string, input: { rate: string; quotedAt?: string }): Promise<FxRate> {
    if (fromCode === toCode || parseRate(input.rate) === null) throw error(400, 'VALIDATION_ERROR');
    const quotedAt = input.quotedAt ? new Date(input.quotedAt) : new Date();
    if (Number.isNaN(quotedAt.getTime()) || quotedAt.getTime() > Date.now() + 5 * 60_000) throw error(400, 'VALIDATION_ERROR');
    const codes = new Set((await this.repository.currencies()).map(currency => currency.code));
    if (!codes.has(fromCode) || !codes.has(toCode)) throw error(400, 'VALIDATION_ERROR');
    const [whole, fraction = ''] = input.rate.split('.');
    const rate = `${BigInt(whole)}.${fraction.padEnd(8, '0')}`;
    return this.repository.upsert(userId, { fromCode, toCode, rate, quotedAt: quotedAt.toISOString() });
  }

  async remove(userId: string, fromCode: string, toCode: string) {
    if (!(await this.repository.remove(userId, fromCode, toCode))) throw error(404, 'FX_RATE_NOT_FOUND');
  }

  /**
   * Detail screens show the original amount plus this number in the profile currency. Null for the
   * profile currency itself and whenever the result would need a missing rate or a fractional unit.
   */
  async toProfileCurrency(userId: string): Promise<(amount: bigint, currency: string) => DisplayConverted | null> {
    const [target, book] = await Promise.all([this.repository.defaultCurrency(userId), this.book(userId)]);
    return (amount, currency) => {
      if (!target || currency === target) return null;
      const result = convertWithBook(amount, currency, target, book);
      if (!result || result.rate === null || result.quotedAt === null) return null;
      return { currencyCode: target, amountMinor: result.amountMinor.toString(), rate: result.rate, quotedAt: result.quotedAt };
    };
  }

  /** Rates and currency digits for one request. Reads only; never changes the ledger. */
  async book(userId: string): Promise<RateBook> {
    const [rates, currencies] = await Promise.all([this.repository.list(userId), this.repository.currencies()]);
    const byPair = new Map(rates.map(item => [`${item.fromCode}>${item.toCode}`, { rate: item.rate, quotedAt: item.quotedAt }]));
    const digits = new Map(currencies.map(currency => [currency.code, currency.minorDigits]));
    return { rate: (from, to) => byPair.get(`${from}>${to}`) ?? null, digits: code => digits.get(code) ?? null };
  }
}
