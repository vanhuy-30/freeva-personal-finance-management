import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/account_file_sharer.dart';

@LazySingleton(as: AccountFileSharer)
class ShareAccountFileSharer implements AccountFileSharer {
  @override
  Future<bool> share(String fileName, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content, flush: true);
    try {
      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'application/json')]),
      );
      return result.status != ShareResultStatus.dismissed;
    } finally {
      // The export holds personal data: do not leave it in the cache.
      if (await file.exists()) await file.delete();
    }
  }
}
