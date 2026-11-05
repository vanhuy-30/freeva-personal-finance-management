import 'dart:typed_data';

/// A file the user picked, unread beyond its bytes.
class PickedImportFile {
  const PickedImportFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// Opens the OS file picker for CSV files. Behind an interface so the view
/// model is tested without a platform.
abstract class ImportFilePicker {
  /// Null when the user backed out.
  Future<PickedImportFile?> pick();
}
