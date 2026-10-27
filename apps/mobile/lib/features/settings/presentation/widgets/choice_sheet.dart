import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_sheet.dart';

/// One option of [showChoiceSheet].
class Choice<T> {
  const Choice(this.value, this.label);

  final T value;
  final String label;
}

/// Sheet with a list of options, the current one ticked; picking returns it
/// at once. [searchHint] adds a filter box for long lists (time zones).
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<Choice<T>> options,
  required T selected,
  String? searchHint,
}) => showFreevaSheet<T>(
  context: context,
  title: title,
  builder: (context) =>
      _Choices<T>(options: options, selected: selected, searchHint: searchHint),
);

class _Choices<T> extends StatefulWidget {
  const _Choices({
    required this.options,
    required this.selected,
    required this.searchHint,
  });

  final List<Choice<T>> options;
  final T selected;
  final String? searchHint;

  @override
  State<_Choices<T>> createState() => _ChoicesState<T>();
}

class _ChoicesState<T> extends State<_Choices<T>> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shown = [
      for (final option in widget.options)
        if (option.label.toLowerCase().contains(query.toLowerCase())) option,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.searchHint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: FreevaSpace.s2),
            child: TextField(
              onChanged: (value) => setState(() => query = value.trim()),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(LucideIcons.search, size: 18),
              ),
            ),
          ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in shown)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.label),
                  selected: option.value == widget.selected,
                  trailing: option.value == widget.selected
                      ? Icon(LucideIcons.check, color: c.actionPrimary)
                      : null,
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
