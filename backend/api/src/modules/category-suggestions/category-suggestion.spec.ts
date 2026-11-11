import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import type { AppConfigService } from '../app-config/app-config.service';
import { AutoSuggestPolicy } from './auto-suggest.policy';
import { CategorySuggestionController } from './category-suggestion.controller';
import { MappingIdDto } from './category-suggestion.dto';
import { merchantKey, type CategorySuggestionRepository } from './domain/category-suggestion';

const uuid = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const request = { session: { userId: 'u1' } } as never;

function repo(overrides: Partial<CategorySuggestionRepository> = {}): CategorySuggestionRepository {
  return {
    autoSuggestEnabled: jest.fn().mockResolvedValue(true),
    listMappings: jest.fn().mockResolvedValue([]),
    deleteMapping: jest.fn().mockResolvedValue(true),
    deleteAllMappings: jest.fn().mockResolvedValue(0),
    ...overrides,
  };
}
const flags = (on: boolean) => ({ isEnabled: jest.fn().mockResolvedValue(on) }) as unknown as AppConfigService;

describe('PRD-P5-E01 auto-suggest switch and learned merchants', () => {
  it('normalises merchant keys', () => {
    expect(merchantKey('  Highlands   Coffee ')).toBe('highlands coffee');
    expect(merchantKey('PHỞ THÌN')).toBe('phở thìn');
  });

  it('allows suggestions only when the flag is on and the user switch is on', async () => {
    await expect(new AutoSuggestPolicy(flags(true), repo()).allows('insights', 'u1')).resolves.toBe(true);
    await expect(new AutoSuggestPolicy(flags(false), repo()).allows('insights', 'u1')).resolves.toBe(false);
    const off = repo({ autoSuggestEnabled: jest.fn().mockResolvedValue(false) });
    await expect(new AutoSuggestPolicy(flags(true), off).allows('forecast', 'u1')).resolves.toBe(false);
    const gone = repo({ autoSuggestEnabled: jest.fn().mockResolvedValue(null) });
    await expect(new AutoSuggestPolicy(flags(true), gone).allows('category_suggest', 'u1')).resolves.toBe(false);
  });

  it('does not read the user when the flag is off', async () => {
    const r = repo();
    await new AutoSuggestPolicy(flags(false), r).allows('insights', 'u1');
    expect(r.autoSuggestEnabled).not.toHaveBeenCalled();
  });

  it('lists mappings with ISO dates and a total', async () => {
    const at = new Date('2026-11-10T08:00:00Z');
    const r = repo({ listMappings: jest.fn().mockResolvedValue([
      { id: uuid, merchant: 'Highlands Coffee', updatedAt: at, category: { id: uuid, name: 'Cà phê', iconToken: 'coffee', colorToken: null } },
    ]) });
    await expect(new CategorySuggestionController(r).list(request)).resolves.toEqual({
      items: [{ id: uuid, merchant: 'Highlands Coffee', updatedAt: '2026-11-10T08:00:00.000Z', category: { id: uuid, name: 'Cà phê', iconToken: 'coffee', colorToken: null } }],
      total: 1,
    });
  });

  it('returns 404 code for a mapping that is not the user’s and deletes all', async () => {
    const r = repo({ deleteMapping: jest.fn().mockResolvedValue(false) });
    const controller = new CategorySuggestionController(r);
    await expect(controller.deleteOne(request, { id: uuid })).rejects.toThrow('MAPPING_NOT_FOUND');
    await controller.deleteAll(request);
    expect(r.deleteAllMappings).toHaveBeenCalledWith('u1');
  });

  it('lower-cases and validates mapping ids', async () => {
    const dto = plainToInstance(MappingIdDto, { id: uuid.toUpperCase() });
    expect(await validate(dto)).toHaveLength(0);
    expect(dto.id).toBe(uuid);
    expect((await validate(plainToInstance(MappingIdDto, { id: 'x' }))).length).toBeGreaterThan(0);
  });
});
