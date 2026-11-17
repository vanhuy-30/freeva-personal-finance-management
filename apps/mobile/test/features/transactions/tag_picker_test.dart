import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/tags/domain/tag.dart';
import 'package:mobile/features/transactions/presentation/widgets/composer/tag_picker_sheet.dart';

import '../../support/server_config_fixture.dart';
import 'c1_stub.dart';

class _NoTags extends StubTransactionViewModel {
  _NoTags() {
    tags = [];
  }
  final created = <String>[];
  @override
  Future<Tag?> createTag(String name, {required String clientId}) async {
    created.add(name);
    final tag = Tag(id: 't-$name', clientId: clientId, name: name, version: 1);
    tags = [...tags, tag];
    return tag;
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
    registerTestServerConfig();
  });

  testWidgets('MOB-P6-001: with no tags yet, "Tạo nhãn" is there and asks '
      'for the name', (tester) async {
    final model = _NoTags();
    List<String>? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => picked = await showTagPicker(
                context,
                model: model,
                selected: const [],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo nhãn'), findsOneWidget);
    await tester.tap(find.text('Tạo nhãn'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      '  Du lịch  ',
    );
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Xong')),
    );
    await tester.pumpAndSettle();
    expect(model.created, ['Du lịch']);
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(picked, ['t-Du lịch']);
  });
}
