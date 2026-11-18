import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // MOB-P6-001: a page asked getIt for an abstract view model that was only
  // registered under its implementation, and crashed when opened.
  test('every getIt<...ViewModel> a page asks for is registered', () {
    final config = File('lib/core/di/injection.config.dart').readAsStringSync();
    final asked = <String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final text = file.readAsStringSync();
      for (final m in RegExp(r'getIt<(\w+ViewModel)>').allMatches(text)) {
        asked.add(m.group(1)!);
      }
    }
    expect(asked, isNotEmpty);
    final missing = [
      for (final type in asked)
        if (!RegExp('<(_i\\d+\\.)?$type[,>]').hasMatch(config)) type,
    ];
    expect(missing, isEmpty, reason: 'not registered as that type: $missing');
  });
}
