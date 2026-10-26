import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/text/vietnamese_fold.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_sheet.dart';
import '../../../../../core/widgets/freeva_card.dart';
import '../../../../../core/widgets/tag_chip.dart';
import '../../viewmodels/transaction_view_model.dart';
import '../search_box.dart';
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
      final locked = !on && full;
      // Board `.ck`: 52 high, 22 box radius 7 on the left, 15/500 label.
      return Semantics(
        checked: on,
        enabled: !locked,
        label: name,
        excludeSemantics: true,
        child: InkWell(
          onTap: locked
              ? null
              : () => setState(() => on ? chosen.remove(id) : chosen.add(id)),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: on ? c.actionPrimary : null,
                    borderRadius: BorderRadius.circular(7),
                    border: on
                        ? null
                        : Border.all(
                            color: c.borderStrong,
                            width: FreevaBorder.selected,
                          ),
                  ),
                  child: on
                      ? Icon(
                          LucideIcons.check,
                          size: FreevaSize.iconXs,
                          color: c.textOnAction,
                        )
                      : null,
                ),
                const SizedBox(width: FreevaSpace.s3),
                Expanded(
                  child: Text(
                    name,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: locked ? c.textDisabled : c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rows = <Widget>[
      if (query.isNotEmpty && !exact)
        TagCreateRow(
          label: s.txCreateTag(query),
          busy: creating,
          onTap: full || creating ? null : _create,
        ),
      for (final t in matches.where((t) => !chosen.contains(t.id)))
        row(t.id, t.name),
    ];
    String nameOf(String id) =>
        tags.where((t) => t.id == id).map((t) => t.name).firstOrNull ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Board: 16 under the handle (the sheet gives 14), row 40.
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      s.transactionTags,
                      style: FreevaTypography.titleL.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(chosen),
                  style: TextButton.styleFrom(
                    foregroundColor: c.textLink,
                    minimumSize: const Size(FreevaSize.touch, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: FreevaSpace.s1,
                    ),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: Text(s.txFilterDone),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s4),
        SearchBox(
          hint: s.txFindOrCreateTag,
          iconSize: FreevaSize.iconSm,
          onChanged: (v) => setState(() => query = v.trim()),
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
            padding: EdgeInsets.zero,
            children: [
              if (rows.isNotEmpty) ...[
                const SizedBox(height: FreevaSpace.s4),
                FreevaCard(
                  list: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: FreevaSpace.s4,
                  ),
                  child: Column(
                    children: [
                      for (final (i, r) in rows.indexed) ...[
                        if (i > 0) Divider(height: 1, color: c.listDivider),
                        r,
                      ],
                    ],
                  ),
                ),
              ],
              if (chosen.isNotEmpty) ...[
                const SizedBox(height: FreevaSpace.s4),
                Text(
                  s.txSelected,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: FreevaSpace.s2),
                // Board: read-only violet chips (32); tap one to unpick it.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in chosen)
                      Semantics(
                        button: true,
                        label: s.txChipRemove(nameOf(id)),
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => setState(() => chosen.remove(id)),
                          child: TagChip(nameOf(id), size: TagChipSize.sheet),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
