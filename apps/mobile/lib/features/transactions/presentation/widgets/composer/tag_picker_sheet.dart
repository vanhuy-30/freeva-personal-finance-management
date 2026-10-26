import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/text/vietnamese_fold.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_sheet.dart';
import '../../../../../core/widgets/settings_group.dart';
import '../../viewmodels/transaction_view_model.dart';
import 'tag_create_row.dart';

/// "Nhãn" (C2.4): find or create, checkbox list, "Đã chọn". At 20 tags the
/// remaining rows lock and "Tối đa 20 nhãn" shows under the field.
Future<List<String>?> showTagPicker(
  BuildContext context, {
  required TransactionViewModel model,
  required List<String> selected,
}) => showFreevaSheet<List<String>>(
  context: context,
  builder: (_) => _Body(model: model, initial: selected),
);

class _Body extends StatefulWidget {
  const _Body({required this.model, required this.initial});
  final TransactionViewModel model;
  final List<String> initial;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  static const limit = 20;
  late final List<String> chosen = List.of(widget.initial);
  String query = '';
  bool creating = false;

  Future<void> _create() async {
    setState(() => creating = true);
    final tag = await widget.model.createTag(
      query,
      clientId: widget.model.newClientId(),
    );
    if (!mounted) return;
    setState(() {
      creating = false;
      if (tag != null) {
        chosen.add(tag.id);
        query = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final full = chosen.length >= limit;
    final folded = foldVietnamese(query);
    final tags = widget.model.tags;
    final matches = [
      for (final t in tags)
        if (folded.isEmpty || foldVietnamese(t.name).contains(folded)) t,
    ];
    final exact = tags.any((t) => foldVietnamese(t.name) == folded);
    Widget row(String id, String name) {
      final on = chosen.contains(id);
      return CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: on,
        activeColor: c.actionPrimary,
        title: Text(
          name,
          style: FreevaTypography.body.copyWith(color: c.textPrimary),
        ),
        onChanged: !on && full
            ? null
            : (v) => setState(
                () => v == true ? chosen.add(id) : chosen.remove(id),
              ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.transactionTags,
                style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(chosen),
              child: Text(s.txFilterDone),
            ),
          ],
        ),
        TextField(
          onChanged: (v) => setState(() => query = v.trim()),
          decoration: InputDecoration(
            hintText: s.txFindOrCreateTag,
            prefixIcon: const Icon(
              LucideIcons.search,
              size: FreevaSize.iconInline,
            ),
          ),
        ),
        if (full)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              s.transactionTagLimit,
              style: FreevaTypography.label.copyWith(color: c.textSecondary),
            ),
          ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (query.isNotEmpty && !exact)
                TagCreateRow(
                  label: s.txCreateTag(query),
                  busy: creating,
                  onTap: full || creating ? null : _create,
                ),
              for (final t in matches.where((t) => !chosen.contains(t.id)))
                row(t.id, t.name),
              if (chosen.isNotEmpty) ...[
                SectionHeader(s.txSelected),
                for (final id in chosen)
                  row(
                    id,
                    tags
                            .where((t) => t.id == id)
                            .map((t) => t.name)
                            .firstOrNull ??
                        '',
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
