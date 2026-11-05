import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

import '../domain/import_file_picker.dart';

@LazySingleton(as: ImportFilePicker)
class PlatformImportFilePicker implements ImportFilePicker {
  @override
  Future<PickedImportFile?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
    );
    if (file == null) return null;
    return PickedImportFile(file.name, await file.readAsBytes());
  }
}
