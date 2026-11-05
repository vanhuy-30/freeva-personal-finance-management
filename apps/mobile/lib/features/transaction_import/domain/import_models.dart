/// File source the user picked (board `ImportSource`). `other` is the API's
/// `custom` preset: the user maps the columns.
enum ImportSource {
  moneyLover('money_lover'),
  misa('misa'),
  freeva('freeva'),
  other('custom');

  const ImportSource(this.apiName);
  final String apiName;
}

/// Date style of a custom file (`dateFormat`).
enum ImportDateFormat {
  dmy('dmy'),
  mdy('mdy'),
  iso('iso');

  const ImportDateFormat(this.apiName);
  final String apiName;
}

/// Number style of a custom file (`numberFormat`).
enum ImportNumberFormat {
  dotThousands('dot_thousands'),
  commaThousands('comma_thousands'),
  plain('plain');

  const ImportNumberFormat(this.apiName);
  final String apiName;
}

/// Freeva field a file column can feed (`ImportMapping` keys the screen
/// offers; date and amount are required).
enum ImportField {
  date('date', required: true),
  amount('amount', required: true),
  type('type'),
  category('category'),
  wallet('wallet'),
  notes('notes');

  const ImportField(this.apiName, {this.required = false});
  final String apiName;
  final bool required;
}

enum ImportRowStatus {
  ready,
  duplicate,
  invalid,
  created,
  skippedDuplicate;

  static ImportRowStatus parse(String value) => switch (value) {
    'ready' => ready,
    'duplicate' => duplicate,
    'created' => created,
    'skipped_duplicate' => skippedDuplicate,
    _ => invalid,
  };
}

/// Why one row cannot be imported, in the API's words.
enum ImportRowError {
  dateInvalid,
  amountInvalid,
  typeUnsupported,
  walletUnmapped,
  walletAmbiguous,
  categoryUnmapped,
  categoryAmbiguous,
  categoryKindMismatch,
  currencyMismatch,
  transferUnpaired,
  transferSameWallet,
  other;

  static ImportRowError parse(String code) => switch (code) {
    'DATE_INVALID' => dateInvalid,
    'AMOUNT_INVALID' => amountInvalid,
    'TYPE_UNSUPPORTED' => typeUnsupported,
    'WALLET_UNMAPPED' => walletUnmapped,
    'WALLET_AMBIGUOUS' => walletAmbiguous,
    'CATEGORY_UNMAPPED' => categoryUnmapped,
    'CATEGORY_AMBIGUOUS' => categoryAmbiguous,
    'CATEGORY_KIND_MISMATCH' => categoryKindMismatch,
    'CURRENCY_MISMATCH' => currencyMismatch,
    'TRANSFER_UNPAIRED' => transferUnpaired,
    'TRANSFER_SAME_WALLET' => transferSameWallet,
    _ => other,
  };
}

/// Everything the API needs to plan or write an import. Money never appears
/// here: the server reads amounts from the file text.
class ImportRequest {
  const ImportRequest({
    required this.text,
    required this.source,
    this.dateFormat,
    this.numberFormat,
    this.mapping = const {},
    this.walletMap = const {},
    this.categoryMap = const {},
    this.defaultAccountId,
  });
  final String text;
  final ImportSource source;
  final ImportDateFormat? dateFormat;
  final ImportNumberFormat? numberFormat;

  /// Freeva field to the file's header name (custom files only).
  final Map<ImportField, String> mapping;

  /// File wallet name to Freeva wallet id.
  final Map<String, String> walletMap;

  /// File category name to Freeva category id.
  final Map<String, String> categoryMap;
  final String? defaultAccountId;
}

/// One planned or written line. [rows] are the 1-based data rows of the file
/// (two for a transfer).
class ImportRow {
  const ImportRow({
    required this.rows,
    required this.status,
    required this.errors,
    this.type,
    this.occurredOn,
    this.amountMinor,
    this.currencyCode,
    this.merchant,
    this.notes,
    this.accountId,
    this.categoryId,
  });
  final List<int> rows;
  final ImportRowStatus status;
  final List<ImportRowError> errors;

  /// `income`, `expense` or `transfer`; null when the row could not be read.
  final String? type;
  final String? occurredOn;

  /// Absolute amount in minor units.
  final BigInt? amountMinor;
  final String? currencyCode;
  final String? merchant;
  final String? notes;
  final String? accountId;
  final String? categoryId;
}

class ImportSummary {
  const ImportSummary({
    required this.rowCount,
    required this.ready,
    required this.duplicate,
    required this.invalid,
  });
  final int rowCount;
  final int ready;
  final int duplicate;
  final int invalid;
}

class ImportPreview {
  const ImportPreview({
    required this.summary,
    required this.unmappedWallets,
    required this.unmappedCategories,
    required this.rows,
    required this.columns,
  });
  final ImportSummary summary;
  final List<String> unmappedWallets;
  final List<String> unmappedCategories;
  final List<ImportRow> rows;

  /// Freeva field name to the header the server matched.
  final Map<String, String> columns;
  int get unmappedCount => unmappedWallets.length + unmappedCategories.length;
}

class ImportBatch {
  const ImportBatch({
    required this.id,
    required this.createdCount,
    required this.duplicateCount,
    required this.invalidCount,
    required this.remainingCount,
    required this.undone,
  });
  final String id;
  final int createdCount;
  final int duplicateCount;
  final int invalidCount;
  final int remainingCount;
  final bool undone;
}

/// Result of writing the batch. [rows] is null when the same batch had
/// already been saved (a retry).
class ImportResult {
  const ImportResult({required this.batch, required this.rows});
  final ImportBatch batch;
  final List<ImportRow>? rows;
}

class ImportUndo {
  const ImportUndo({required this.batch, required this.undoneCount});
  final ImportBatch batch;
  final int undoneCount;
}
