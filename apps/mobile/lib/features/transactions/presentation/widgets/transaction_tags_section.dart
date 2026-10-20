import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../tags/domain/tag.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';

class TransactionTagsSection extends StatelessWidget {
  const TransactionTagsSection({
    required this.type,
    required this.readOnly,
    required this.merchant,
    required this.selectedTagIds,
    required this.tags,
    required this.model,
    required this.onMerchantChanged,
    required this.onTagIdsChanged,
    super.key,
  });

  final TransactionType type;
  final bool readOnly;
  final TextEditingController merchant;
  final List<String> selectedTagIds;
  final List<Tag> tags;
  final TransactionViewModel model;
  final VoidCallback onMerchantChanged;
  final ValueChanged<List<String>> onTagIdsChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (type != TransactionType.transfer)
          TextField(
            controller: merchant,
            readOnly: readOnly,
            maxLength: 200,
            decoration: InputDecoration(labelText: s.transactionMerchant),
            onChanged: (_) => onMerchantChanged(),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            s.transactionTags,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              FilterChip(
                label: Text(tag.name),
                selected: selectedTagIds.contains(tag.id),
                onSelected: readOnly
                    ? null
                    : (selected) => _toggle(tag.id, selected),
                selectedColor: scheme.secondaryContainer,
                checkmarkColor: scheme.onSecondaryContainer,
              ),
            if (!readOnly)
              ActionChip(
                avatar: Icon(Icons.add, color: scheme.primary),
                label: Text(s.transactionTagCreate),
                onPressed: () => _create(context),
              ),
          ],
        ),
        if (selectedTagIds.length >= 20)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              s.transactionTagLimit,
              style: TextStyle(color: scheme.error),
            ),
          ),
      ],
    );
  }

  void _toggle(String id, bool selected) {
    final next = [...selectedTagIds];
    if (selected) {
      if (next.length >= 20 || next.contains(id)) return;
      next.add(id);
    } else {
      next.remove(id);
    }
    onTagIdsChanged(List.unmodifiable(next));
  }

  Future<void> _create(BuildContext context) async {
    if (selectedTagIds.length >= 20) return;
    final s = S.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _TagNameDialog(s: s),
    );
    if (name == null || !context.mounted) return;
    final tag = await model.createTag(name, clientId: model.newClientId());
    if (tag == null || !context.mounted) return;
    if (selectedTagIds.contains(tag.id) || selectedTagIds.length >= 20) return;
    onTagIdsChanged(List.unmodifiable([...selectedTagIds, tag.id]));
  }
}

class _TagNameDialog extends StatefulWidget {
  const _TagNameDialog({required this.s});
  final S s;

  @override
  State<_TagNameDialog> createState() => _TagNameDialogState();
}

class _TagNameDialogState extends State<_TagNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return AlertDialog(
      title: Text(s.transactionTagCreateTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        decoration: InputDecoration(labelText: s.transactionTagName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.transactionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(s.transactionTagCreate),
        ),
      ],
    );
  }
}
