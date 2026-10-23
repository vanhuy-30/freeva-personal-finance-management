import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';

class PickOption {
  const PickOption(this.id, this.label, {this.indent = false});
  final String id;
  final String label;

  /// Child category under its parent.
  final bool indent;
}

/// Multi-select list (categories or tags) for the filter sheet. Returns the
/// chosen ids, or null when dismissed.
Future<Set<String>?> showFilterPickSheet(
  BuildContext context, {
  required String title,
  required List<PickOption> options,
  required Set<String> selected,
}) => showFreevaSheet<Set<String>>(
  context: context,
  title: title,
  builder: (_) => _PickBody(options: options, initial: selected),
);

class _PickBody extends StatefulWidget {
  const _PickBody({required this.options, required this.initial});
  final List<PickOption> options;
  final Set<String> initial;

  @override
  State<_PickBody> createState() => _PickBodyState();
}

class _PickBodyState extends State<_PickBody> {
  late final Set<String> chosen = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in widget.options)
                CheckboxListTile(
                  value: chosen.contains(option.id),
                  contentPadding: EdgeInsets.only(left: option.indent ? 28 : 0),
                  controlAffinity: ListTileControlAffinity.trailing,
                  activeColor: c.actionPrimary,
                  title: Text(
                    option.label,
                    style: FreevaTypography.body.copyWith(color: c.textPrimary),
                  ),
                  onChanged: (on) => setState(
                    () => on == true
                        ? chosen.add(option.id)
                        : chosen.remove(option.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        FreevaButton(
          label: S.of(context).txFilterDone,
          variant: FreevaButtonVariant.ink,
          expand: true,
          onPressed: () => Navigator.of(context).pop(chosen),
        ),
      ],
    );
  }
}
