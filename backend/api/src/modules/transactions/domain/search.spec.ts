import { VIETNAMESE_FOLD_FROM, VIETNAMESE_FOLD_TO, foldVietnamese, parseTransactionSearch, resolvedMinor } from './search';

const UPPER = 'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ';
const LOWER = 'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ';
const FOLDED = 'a'.repeat(17) + 'e'.repeat(11) + 'i'.repeat(5) + 'o'.repeat(17) + 'u'.repeat(11) + 'y'.repeat(5) + 'd';

describe('BE-P1-008 Vietnamese search fold and amount', () => {
  it('folds case and Vietnamese diacritics with a balanced table', () => {
    expect([...VIETNAMESE_FOLD_FROM]).toHaveLength([...VIETNAMESE_FOLD_TO].length);
    expect(new Set(VIETNAMESE_FOLD_FROM).size).toBe([...VIETNAMESE_FOLD_FROM].length);
    expect(foldVietnamese(UPPER)).toBe(FOLDED);
    expect(foldVietnamese(LOWER)).toBe(FOLDED);
    expect(foldVietnamese('Cà phê SỮA')).toBe('ca phe sua');
    expect(foldVietnamese('Đồng')).toBe('dong');
    expect(foldVietnamese('Ăn')).toBe('an');
    expect(foldVietnamese('CA PHE')).toBe('ca phe');
  });

  it('escapes LIKE wildcards and ignores blank input', () => {
    expect(parseTransactionSearch(undefined)).toBeNull();
    expect(parseTransactionSearch('   ')).toBeNull();
    expect(parseTransactionSearch('  cà phê  ')).toEqual({ like: '%ca phe%', amount: null });
    expect(parseTransactionSearch(' %_\\ ')).toEqual({ like: '%\\%\\_\\\\%', amount: null });
  });

  it('parses exact minor amounts, thousand groups and major units', () => {
    expect(parseTransactionSearch('150000')?.amount).toEqual({ kind: 'minor', minor: 150000n });
    expect(parseTransactionSearch('150.000')?.amount).toEqual({ kind: 'minor', minor: 150000n });
    expect(parseTransactionSearch('150,000')?.amount).toEqual({ kind: 'minor', minor: 150000n });
    expect(parseTransactionSearch('1.500')?.amount).toEqual({ kind: 'minor', minor: 1500n });
    expect(parseTransactionSearch('12.501')?.amount).toEqual({ kind: 'minor', minor: 12501n });
    expect(parseTransactionSearch('12.50')?.amount).toEqual({ kind: 'major', whole: 12n, fraction: 50n, fractionDigits: 2 });
    expect(parseTransactionSearch('12,5')?.amount).toEqual({ kind: 'major', whole: 12n, fraction: 5n, fractionDigits: 1 });
    expect(parseTransactionSearch('12.05')?.amount).toEqual({ kind: 'major', whole: 12n, fraction: 5n, fractionDigits: 2 });
    expect(parseTransactionSearch('12.5001')?.amount).toEqual({ kind: 'major', whole: 12n, fraction: 5001n, fractionDigits: 4 });
    expect(parseTransactionSearch('cafe 50')?.amount).toBeNull();
    expect(parseTransactionSearch('1234.500')?.amount).toBeNull();
    expect(parseTransactionSearch('9'.repeat(19))?.amount).toBeNull();
  });

  it('scales major units by currency minor digits without rounding', () => {
    const cents = parseTransactionSearch('12.50')!.amount!;
    const short = parseTransactionSearch('12,5')!.amount!;
    const padded = parseTransactionSearch('12.05')!.amount!;
    const extra = parseTransactionSearch('12.5001')!.amount!;
    expect(resolvedMinor(cents, 2)).toBe(1250n);
    expect(resolvedMinor(cents, 0)).toBeNull();
    expect(resolvedMinor(short, 2)).toBe(1250n);
    expect(resolvedMinor(short, 0)).toBeNull();
    expect(resolvedMinor(padded, 2)).toBe(1205n);
    expect(resolvedMinor(extra, 2)).toBeNull();
    expect(resolvedMinor(extra, 4)).toBe(125001n);
    expect(resolvedMinor({ kind: 'minor', minor: 150000n }, 0)).toBe(150000n);
  });
});
