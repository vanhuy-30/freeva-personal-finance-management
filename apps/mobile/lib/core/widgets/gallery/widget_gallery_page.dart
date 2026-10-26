import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/theme_context.dart';
import '../freeva_top_bar.dart';
import 'gallery_sections.dart';
import 'gallery_sections_data.dart';

/// Debug-only catalogue of core widgets (route `/debug/gallery`, registered
/// only in debug builds). Sample copy here is fixture text, not product copy.
class WidgetGalleryPage extends StatefulWidget {
  const WidgetGalleryPage({super.key});

  @override
  State<WidgetGalleryPage> createState() => _WidgetGalleryPageState();
}

class _WidgetGalleryPageState extends State<WidgetGalleryPage> {
  var _dark = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _dark ? AppTheme.dark : AppTheme.light,
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: context.colors.bgCanvas,
          appBar: FreevaTopBar(
            title: 'Gallery',
            action: Switch(
              value: _dark,
              onChanged: (value) => setState(() => _dark = value),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              context.screenMargin,
              8,
              context.screenMargin,
              48,
            ),
            children: const [
              GalleryButtons(),
              GalleryInputs(),
              GallerySelection(),
              GalleryCards(),
              GalleryLists(),
              GalleryFeedback(),
              GalleryNav(),
            ],
          ),
        ),
      ),
    );
  }
}
