import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/gallery/gallery_sections.dart';
import 'package:mobile/core/widgets/gallery/gallery_sections_data.dart';

import 'widget_test_app.dart';

// Goldens are rendered on macOS; text rasterises differently on Linux CI, so
// they only run on macOS. Update: flutter test --update-goldens test/core/widgets
final _skip = Platform.isMacOS ? null : 'goldens are generated on macOS';

void main() {
  setUpAll(loadTestFonts);

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('core widgets $mode', skip: _skip != null, (tester) async {
      tester.view.physicalSize = const Size(390, 2420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testApp(
          dark: dark,
          const SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GalleryButtons(),
                GalleryInputs(),
                GallerySelection(),
                GalleryCards(),
                GalleryLists(),
                GalleryNav(),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(SingleChildScrollView),
        matchesGoldenFile('goldens/core_widgets_$mode.png'),
      );
    });
  }
}
