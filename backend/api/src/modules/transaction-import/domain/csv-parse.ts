export class CsvParseError extends Error {
  constructor(readonly code: 'UNTERMINATED_QUOTE') { super(code); }
}

/** RFC 4180 reader: quoted cells, doubled quotes, CR/LF/CRLF, embedded newlines. Strips a leading BOM; blank lines are skipped. */
export function parseCsv(text: string, delimiter = ','): string[][] {
  const source = text.charCodeAt(0) === 0xfeff ? text.slice(1) : text;
  const rows: string[][] = [];
  let row: string[] = [];
  let cell = '';
  let quoted = false;
  let started = false;
  const endCell = () => { row.push(cell); cell = ''; started = true; };
  const endRow = () => {
    endCell();
    if (row.some(value => value !== '')) rows.push(row);
    row = [];
    started = false;
  };
  for (let index = 0; index < source.length; index++) {
    const char = source[index];
    if (quoted) {
      if (char !== '"') cell += char;
      else if (source[index + 1] === '"') { cell += '"'; index++; }
      else quoted = false;
    } else if (char === '"' && cell === '') {
      quoted = true;
      started = true;
    } else if (char === delimiter) endCell();
    else if (char === '\r') { if (source[index + 1] === '\n') index++; endRow(); }
    else if (char === '\n') endRow();
    else { cell += char; started = true; }
  }
  if (quoted) throw new CsvParseError('UNTERMINATED_QUOTE');
  if (started || cell !== '') endRow();
  return rows;
}

/** Picks `;` over `,` when the header line has more of them (Excel in vi/eu locales exports semicolons). */
export function detectDelimiter(text: string): ',' | ';' {
  const header = (text.charCodeAt(0) === 0xfeff ? text.slice(1) : text).split(/\r\n|\r|\n/, 1)[0] ?? '';
  return (header.match(/;/g) ?? []).length > (header.match(/,/g) ?? []).length ? ';' : ',';
}
