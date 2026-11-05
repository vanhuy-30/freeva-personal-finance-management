/// Largest file the API accepts: 2 000 data rows and 1 000 000 characters.
const importMaxRows = 2000;
const importMaxChars = 1000000;

/// What the app needs to know about a CSV before the server reads it: the
/// header (to pick columns), how many data rows, and the first one as a
/// sample. Parsing here is only for display; the server owns the real parse.
class CsvPeek {
  const CsvPeek({
    required this.headers,
    required this.rowCount,
    required this.firstRow,
  });
  final List<String> headers;
  final int rowCount;
  final List<String> firstRow;

  bool get isEmpty => headers.isEmpty || rowCount == 0;
  bool get tooManyRows => rowCount > importMaxRows;

  /// Reads RFC 4180 text with a comma or semicolon separator. A UTF-8 BOM
  /// is ignored; blank lines are skipped.
  static CsvPeek parse(String text) {
    final body = text.startsWith('\uFEFF') ? text.substring(1) : text;
    final first = body
        .split(RegExp(r'\r\n|\r|\n'))
        .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');
    final separator =
        ';'.allMatches(first).length > ','.allMatches(first).length ? ';' : ',';
    final rows = _rows(body, separator);
    if (rows.isEmpty) {
      return const CsvPeek(headers: [], rowCount: 0, firstRow: []);
    }
    return CsvPeek(
      headers: rows.first.map((cell) => cell.trim()).toList(),
      rowCount: rows.length - 1,
      firstRow: rows.length > 1 ? rows[1] : const [],
    );
  }

  static List<List<String>> _rows(String text, String separator) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    var touched = false;
    void endCell() {
      row.add(cell.toString());
      cell.clear();
    }

    void endRow() {
      endCell();
      if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
      touched = false;
    }

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(ch);
        }
        continue;
      }
      if (ch == '"') {
        quoted = true;
        touched = true;
      } else if (ch == separator) {
        endCell();
        touched = true;
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        endRow();
      } else {
        cell.write(ch);
        touched = true;
      }
    }
    if (touched || cell.isNotEmpty) endRow();
    return rows;
  }
}
