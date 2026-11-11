import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { appConfigReaderFor } from '../app-config/testing';
import type { AutoSuggestPolicy } from './auto-suggest.policy';
import { SuggestCategoryDto, SuggestionFeedbackDto } from './category-suggestion.dto';
import { CategorySuggestionService } from './category-suggestion.service';
import { repo } from './testing';
import { DEFAULT_COMMON_MERCHANTS, looseText, matchCommon, suggestCategory, type SuggestCategory, type SuggestInput } from './domain/suggest';

const cat = (id: string, iconToken: string, extra: Partial<SuggestCategory> = {}): SuggestCategory => ({
  id, name: id, iconToken, colorToken: null, kind: 'expense', isSystem: true, parentId: null, archivedAt: null, ...extra,
});
const food = cat('food', 'food');
const coffee = cat('coffee', 'coffee');
const transport = cat('transport', 'transport');
const salary = cat('salary', 'salary', { kind: 'income' });
const base: SuggestInput = {
  merchant: 'Highlands Coffee', note: null, kind: 'expense', rememberedCategoryId: null, history: [],
  categories: [food, coffee, transport, salary], commonMerchants: DEFAULT_COMMON_MERCHANTS, minConfidencePercent: 60,
};

describe('BE-P5-E03 suggestCategory', () => {
  it('prefers what the user remembered and reports how often it was used', () => {
    expect(suggestCategory({ ...base, rememberedCategoryId: 'food', history: ['food', 'coffee', 'food'] })).toEqual({
      category: { id: 'food', name: 'food', iconToken: 'food', colorToken: null }, source: 'remembered', matchCount: 2, confidencePercent: 67,
    });
  });

  it('skips a remembered category that is archived or of the other kind', () => {
    const archived = { ...base, categories: [{ ...food, archivedAt: new Date() }, coffee], rememberedCategoryId: 'food' };
    expect(suggestCategory(archived)?.source).toBe('common');
    expect(suggestCategory({ ...base, rememberedCategoryId: 'salary' })?.category.id).toBe('coffee');
  });

  it('uses history when the top category reaches the threshold', () => {
    const history = ['coffee', 'coffee', 'coffee', 'food', 'coffee'];
    expect(suggestCategory({ ...base, history })).toMatchObject({ source: 'history', matchCount: 4, confidencePercent: 80 });
  });

  it('says nothing when history is below the threshold or tied, even if the common list knows the shop', () => {
    expect(suggestCategory({ ...base, history: ['coffee', 'food', 'transport'] })).toBeNull();
    expect(suggestCategory({ ...base, history: ['coffee', 'food'] })).toBeNull();
    expect(suggestCategory({ ...base, history: ['coffee', 'coffee', 'food'], minConfidencePercent: 70 })).toBeNull();
  });

  it('ignores history rows whose category is gone or of the other kind', () => {
    expect(suggestCategory({ ...base, history: ['deleted', 'salary', 'food'] })).toMatchObject({ source: 'history', matchCount: 1, confidencePercent: 100 });
  });

  it('falls back to the common list by icon, then to a related icon', () => {
    expect(suggestCategory(base)).toMatchObject({ source: 'common', category: { id: 'coffee' }, matchCount: 0, confidencePercent: null });
    expect(suggestCategory({ ...base, categories: [food] })).toMatchObject({ source: 'common', category: { id: 'food' } });
    expect(suggestCategory({ ...base, merchant: 'WinMart Q7' })).toMatchObject({ category: { id: 'food' } });
  });

  it('picks the default top-level category when several share the icon', () => {
    const own = cat('own', 'transport', { isSystem: false, name: 'A' });
    const child = cat('child', 'transport', { parentId: 'transport' });
    expect(suggestCategory({ ...base, merchant: 'Grab', categories: [own, child, transport] })?.category.id).toBe('transport');
  });

  it('matches the common list on whole words, accents ignored, longest entry first', () => {
    expect(looseText('  Phở  Thìn – Lò Đúc ')).toBe('pho thin lo duc');
    expect(matchCommon(['GRAB*ShopeeFood 123'], DEFAULT_COMMON_MERCHANTS)).toBe('food');
    expect(matchCommon(['grab bike'], DEFAULT_COMMON_MERCHANTS)).toBe('transport');
    expect(matchCommon(['Grabber store'], DEFAULT_COMMON_MERCHANTS)).toBeNull();
    expect(matchCommon(['Phuc Long Nguyen Hue'], DEFAULT_COMMON_MERCHANTS)).toBe('coffee');
    expect(matchCommon(['anything'], ['broken entry', ': food'])).toBeNull();
  });

  it('uses the note when there is no merchant, and nothing when both are empty', () => {
    expect(suggestCategory({ ...base, merchant: null, note: 'đi grab về nhà' })?.category.id).toBe('transport');
    expect(suggestCategory({ ...base, merchant: '  ', note: null })).toBeNull();
  });
});

describe('BE-P5-E03 suggestion service', () => {
  const allow = (on: boolean) => ({ allows: jest.fn().mockResolvedValue(on) }) as unknown as AutoSuggestPolicy;
  const config = appConfigReaderFor();

  it('returns null without reading anything when suggestions are off', async () => {
    const r = repo();
    await expect(new CategorySuggestionService(r, allow(false), config).suggest('u1', { merchant: 'Grab', type: 'expense' })).resolves.toBeNull();
    expect(r.categories).not.toHaveBeenCalled();
  });

  it('reads the remembered merchant by key and the history by merchant', async () => {
    const r = repo({
      rememberedCategoryId: jest.fn().mockResolvedValue('coffee'),
      historyCategoryIds: jest.fn().mockResolvedValue(['coffee']),
      categories: jest.fn().mockResolvedValue([coffee]),
    });
    const result = await new CategorySuggestionService(r, allow(true), config).suggest('u1', { merchant: ' Highlands  Coffee ', note: 'x', type: 'expense' });
    expect(result).toMatchObject({ source: 'remembered', matchCount: 1 });
    expect(r.rememberedCategoryId).toHaveBeenCalledWith('u1', 'highlands coffee');
    expect(r.historyCategoryIds).toHaveBeenCalledWith('u1', { merchant: 'Highlands  Coffee', note: null }, 'expense', 50);
  });

  it('counts accepted and corrected, and remembers the chosen category', async () => {
    const r = repo({ categories: jest.fn().mockResolvedValue([food, coffee]) });
    const service = new CategorySuggestionService(r, allow(true), config);
    const now = new Date('2026-11-11T20:30:00Z');
    await service.feedback('u1', { merchant: 'Highlands', suggestedCategoryId: 'coffee', chosenCategoryId: 'coffee', source: 'common', surface: 'entry' }, now);
    await service.feedback('u1', { merchant: null, suggestedCategoryId: 'coffee', chosenCategoryId: 'food', source: 'history', surface: 'entry' }, now);
    expect(r.count).toHaveBeenNthCalledWith(1, new Date('2026-11-11T00:00:00Z'), 'entry', 'common', 'accepted');
    expect(r.count).toHaveBeenNthCalledWith(2, new Date('2026-11-11T00:00:00Z'), 'entry', 'history', 'corrected');
    expect(r.remember).toHaveBeenCalledTimes(1);
    expect(r.remember).toHaveBeenCalledWith('u1', 'Highlands', 'coffee');
  });

  it('rejects a chosen category that is not the user’s and ignores feedback when off', async () => {
    const r = repo({ categories: jest.fn().mockResolvedValue([food]) });
    const input = { merchant: 'Grab', suggestedCategoryId: 'food', chosenCategoryId: 'other', source: 'common' as const, surface: 'entry' as const };
    await expect(new CategorySuggestionService(r, allow(true), config).feedback('u1', input)).rejects.toThrow('CATEGORY_NOT_FOUND');
    await new CategorySuggestionService(r, allow(false), config).feedback('u1', input);
    expect(r.count).not.toHaveBeenCalled();
  });

  it('summarises stats with an accept rate', async () => {
    const r = repo({ stats: jest.fn().mockResolvedValue([
      { day: '2026-11-10', surface: 'entry', source: 'history', accepted: 3, corrected: 1 },
      { day: '2026-11-11', surface: 'import', source: 'common', accepted: 0, corrected: 2 },
    ]) });
    const result = await new CategorySuggestionService(r, allow(true), config).stats(new Date('2026-11-01T00:00:00Z'), new Date('2026-11-30T00:00:00Z'));
    expect(result).toMatchObject({ from: '2026-11-01', to: '2026-11-30', accepted: 3, corrected: 3, acceptRatePercent: 50 });
  });
});

describe('BE-P5-E03 DTOs', () => {
  const check = (dto: object) => validate(dto, { whitelist: true, forbidNonWhitelisted: true });
  it('accepts merchant or note with a type, rejects other types and long text', async () => {
    expect(await check(plainToInstance(SuggestCategoryDto, { merchant: ' Grab ', type: 'expense' }))).toHaveLength(0);
    expect(await check(plainToInstance(SuggestCategoryDto, { note: 'ăn trưa', merchant: null, type: 'income' }))).toHaveLength(0);
    expect((await check(plainToInstance(SuggestCategoryDto, { merchant: 'Grab', type: 'transfer' }))).length).toBeGreaterThan(0);
    expect((await check(plainToInstance(SuggestCategoryDto, { merchant: 'x'.repeat(201), type: 'expense' }))).length).toBeGreaterThan(0);
  });
  it('validates feedback ids, source and surface', async () => {
    const id = 'AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA';
    const ok = plainToInstance(SuggestionFeedbackDto, { suggestedCategoryId: id, chosenCategoryId: id, source: 'history', surface: 'entry' });
    expect(await check(ok)).toHaveLength(0);
    expect(ok.chosenCategoryId).toBe(id.toLowerCase());
    expect((await check(plainToInstance(SuggestionFeedbackDto, { suggestedCategoryId: id, chosenCategoryId: id, source: 'ai', surface: 'entry' }))).length).toBeGreaterThan(0);
  });
});
