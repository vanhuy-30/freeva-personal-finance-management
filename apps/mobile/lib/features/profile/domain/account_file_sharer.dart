/// Hands an exported file to the OS (share sheet / save to Files).
abstract class AccountFileSharer {
  /// Returns false when the user dismissed the sheet without sharing.
  Future<bool> share(String fileName, String content);

  /// Same for raw [bytes] (a CSV keeps its UTF-8 BOM so Excel reads it).
  Future<bool> shareBytes(String fileName, List<int> bytes, String mimeType);
}

/// `{stem}-YYYYMMDD.{extension}` from the UTC date of [now].
String exportFileName(String stem, String extension, DateTime now) {
  final d = now.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '$stem-${d.year}${two(d.month)}${two(d.day)}.$extension';
}
