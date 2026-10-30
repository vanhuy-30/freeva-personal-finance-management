/// Hands an exported file to the OS (share sheet / save to Files).
abstract class AccountFileSharer {
  /// Returns false when the user dismissed the sheet without sharing.
  Future<bool> share(String fileName, String content);
}
