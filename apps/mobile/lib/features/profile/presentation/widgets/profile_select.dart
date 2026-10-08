import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';

class ProfileSelect extends StatefulWidget {
  const ProfileSelect({
    required this.label,
    required this.value,
    required this.choices,
    required this.enabled,
    required this.onChanged,
    super.key,
  });
  final String label;
  final String value;
  final Map<String, String> choices;
  final bool enabled;
  final ValueChanged<String> onChanged;
  @override
  State<ProfileSelect> createState() => _ProfileSelectState();
}

class _ProfileSelectState extends State<ProfileSelect> {
  bool expanded = false;
  String query = '';
  @override
  Widget build(BuildContext context) {
    final entries = widget.choices.entries
        .where(
          (entry) => entry.value.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(widget.label),
            subtitle: Text(widget.choices[widget.value] ?? widget.value),
            trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            enabled: widget.enabled,
            onTap: () => setState(() {
              expanded = !expanded;
              query = '';
            }),
          ),
          if (expanded && widget.enabled && widget.choices.length > 30)
            TextField(
              decoration: InputDecoration(
                labelText: S.of(context).profileSearch,
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          if (expanded && widget.enabled)
            SizedBox(
              height: 220,
              child: Scrollbar(
                child: ListView.builder(
                  primary: false,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      title: Text(entry.value),
                      selected: entry.key == widget.value,
                      trailing: entry.key == widget.value
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () {
                        widget.onChanged(entry.key);
                        setState(() => expanded = false);
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
