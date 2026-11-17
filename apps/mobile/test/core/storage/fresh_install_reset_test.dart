import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/fresh_install_reset.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('freeva'));
  tearDown(() => dir.delete(recursive: true));

  test(
    'MOB-P6-001: first launch of an install clears the vaults once',
    () async {
      var clears = 0;
      Future<bool> launch() => clearVaultsOnFreshInstall(
        supportDir: () async => dir,
        clearVaults: () async => clears++,
      );
      expect(await launch(), isTrue);
      expect(await launch(), isFalse);
      expect(clears, 1);
      expect(File('${dir.path}/$freshInstallMarker').existsSync(), isTrue);
    },
  );

  test('a failed clear writes no marker, so the next launch retries', () async {
    await expectLater(
      clearVaultsOnFreshInstall(
        supportDir: () async => dir,
        clearVaults: () async => throw StateError('keychain locked'),
      ),
      throwsStateError,
    );
    expect(File('${dir.path}/$freshInstallMarker').existsSync(), isFalse);
    expect(
      await clearVaultsOnFreshInstall(
        supportDir: () async => dir,
        clearVaults: () async {},
      ),
      isTrue,
    );
  });
}
