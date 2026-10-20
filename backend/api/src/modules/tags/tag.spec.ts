import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { assertTagVersion } from './domain/tag';
import { CreateTagDto, DeleteTagDto, TagQueryDto, UpdateTagDto } from './tag.dto';

const uuid = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const check = (dto: object) => validate(dto, { whitelist: true, forbidNonWhitelisted: true });

describe('BE-P1-012 tag domain and DTO', () => {
  it('trims name and lowercases clientId', async () => {
    const dto = plainToInstance(CreateTagDto, { clientId: uuid.toUpperCase(), name: '  Work  ' });
    expect(await check(dto)).toHaveLength(0);
    expect(dto).toMatchObject({ clientId: uuid, name: 'Work' });
  });
  it.each([{ name: ' ' }, { name: 'x'.repeat(101) }, { userId: uuid }, { version: 1 }])('rejects unsupported create %j', async patch => {
    expect((await check(plainToInstance(CreateTagDto, { clientId: uuid, name: 'Valid', ...patch }))).length).toBeGreaterThan(0);
  });
  it.each([{ version: null }, { version: 0 }, { version: 2147483647 }, { version: 1, name: null }, { version: 1, clientId: uuid }])(
    'rejects invalid patch %j',
    async patch => {
      expect((await check(plainToInstance(UpdateTagDto, patch))).length).toBeGreaterThan(0);
    },
  );
  it('accepts rename and delete query versions', async () => {
    expect(await check(plainToInstance(UpdateTagDto, { version: 1, name: 'Personal' }))).toHaveLength(0);
    expect(await check(plainToInstance(DeleteTagDto, { version: '2' }))).toHaveLength(0);
    expect(await check(plainToInstance(TagQueryDto, { page: 1, pageSize: 50 }))).toHaveLength(0);
    for (const patch of [{ page: 0 }, { pageSize: 101 }]) {
      expect((await check(plainToInstance(TagQueryDto, patch))).length).toBeGreaterThan(0);
    }
    expect(() => assertTagVersion(2, 1)).toThrow('TAG_CONFLICT');
    expect(() => assertTagVersion(2147483647, 2147483647)).toThrow('TAG_CONFLICT');
  });
});
