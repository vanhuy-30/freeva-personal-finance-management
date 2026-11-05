import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../../domain/import_models.dart';
import '../viewmodels/import_view_model.dart';
import 'import_pick_sheet.dart';

/// Board `ImportColumns`: which column of an "other" file feeds which field.
class ImportColumnsView extends StatelessWidget {
  const ImportColumnsView({
    required this.model,
    required this.onNext,
    super.key,
  });
  final ImportViewModel model;
  final VoidCallback onNext;

  String _fieldLabel(S s, ImportField field) => switch (field) {
    ImportField.date => s.importFieldDate,
    ImportField.amount => s.importFieldAmount,
    ImportField.type => s.importFieldType,
    ImportField.category => s.importFieldCategory,
    ImportField.wallet => s.importFieldWallet,
    ImportField.notes => s.importFieldNotes,
  };

  Future<void> _pickColumn(BuildContext context, ImportField field) async {
    final s = S.of(context);
    final headers = model.peek?.headers ?? const <String>[];
    final picked = await showImportPickSheet<String>(
      context,
      title: _fieldLabel(s, field),
      selected: model.mapping[field],
      options: [
        if (!field.required) ImportPickOption<String>(null, s.importColumnNone),
        for (final header in headers) ImportPickOption(header, header),
      ],
    );
    if (picked != null) model.mapColumn(field, picked.value);
  }

  static String _dateExample(ImportDateFormat f) => switch (f) {
    ImportDateFormat.dmy => '31/12/2026',
    ImportDateFormat.mdy => '12/31/2026',
    ImportDateFormat.iso => '2026-12-31',
  };

  static String _numberExample(ImportNumberFormat f) => switch (f) {
    ImportNumberFormat.dotThousands => '1.000.000',
    ImportNumberFormat.commaThousands => '1,000,000',
    ImportNumberFormat.plain => '1000000',
  };

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showImportPickSheet<ImportDateFormat>(
      context,
      title: S.of(context).importDateFormat,
      selected: model.dateFormat,
      options: [
        for (final f in ImportDateFormat.values)
          ImportPickOption(f, _dateExample(f)),
      ],
    );
    if (picked?.value != null) model.selectDateFormat(picked!.value!);
  }

  Future<void> _pickNumber(BuildContext context) async {
    final picked = await showImportPickSheet<ImportNumberFormat>(
      context,
      title: S.of(context).importNumberFormat,
      selected: model.numberFormat,
      options: [
        for (final f in ImportNumberFormat.values)
          ImportPickOption(f, _numberExample(f)),
      ],
    );
    if (picked?.value != null) model.selectNumberFormat(picked!.value!);
  }

  /// Raw cells of the first data row for the columns picked so far, in the
  /// board's order: date, type and amount together, category, wallet, note.
  String _sample() {
    final peek = model.peek;
    if (peek == null) return '';
    String cell(ImportField field) {
      final header = model.mapping[field];
      final at = header == null ? -1 : peek.headers.indexOf(header);
      if (at < 0 || at >= peek.firstRow.length) return '';
      return peek.firstRow[at].trim();
    }

    final money = [
      cell(ImportField.type),
      cell(ImportField.amount),
    ].where((v) => v.isNotEmpty).join(' ');
    return [
      cell(ImportField.date),
      money,
      cell(ImportField.category),
      cell(ImportField.wallet),
      cell(ImportField.notes),
    ].where((v) => v.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final sample = _sample();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: FreevaSpace.s2),
            children: [
              FreevaCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: FreevaSpace.s4,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.bgSubtle,
                        borderRadius: BorderRadius.circular(FreevaRadius.xs),
                      ),
                      child: SizedBox.square(
                        dimension: 32,
                        child: Icon(
                          LucideIcons.file,
                          size: 17,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.fileName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            s.importFileRows(model.peek?.rowCount ?? 0),
                            style: FreevaTypography.label.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FreevaSpace.s2),
              SettingsGroup(
                title: s.importColumnsHeader,
                children: [
                  for (final field in ImportField.values)
                    _ColumnRow(
                      label: _fieldLabel(s, field),
                      required: field.required,
                      value: model.mapping[field],
                      none: s.importColumnNone,
                      onTap: () => _pickColumn(context, field),
                    ),
                ],
              ),
              const SizedBox(height: FreevaSpace.s3),
              FormPair(
                first: _OptionField(
                  icon: LucideIcons.calendar,
                  label: s.importDateFormat,
                  value: _dateExample(model.dateFormat),
                  onTap: () => _pickDate(context),
                ),
                second: _OptionField(
                  icon: LucideIcons.hash,
                  label: s.importNumberFormat,
                  value: _numberExample(model.numberFormat),
                  onTap: () => _pickNumber(context),
                ),
              ),
              if (sample.isNotEmpty) ...[
                const SizedBox(height: FreevaSpace.s3),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.bgSubtle,
                    borderRadius: BorderRadius.circular(FreevaRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.importFirstRow,
                          style: FreevaTypography.label.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sample,
                          style: FreevaTypography.bodyM.copyWith(
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        FreevaButton(
          label: s.importNext,
          size: FreevaButtonSize.l,
          expand: true,
          loading: model.busy,
          onPressed: model.canContinueColumns && !model.busy ? onNext : null,
        ),
      ],
    );
  }
}

class _ColumnRow extends StatelessWidget {
  const _ColumnRow({
    required this.label,
    required this.required,
    required this.value,
    required this.none,
    required this.onTap,
  });
  final String label;
  final bool required;
  final String? value;
  final String none;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  children: [
                    if (required)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: c.statusDanger),
                      ),
                  ],
                ),
                style: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: ImportPill(
                label: value ?? none,
                muted: value == null,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Date or number style: icon box, small label, value (board `fld`).
class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaComponent.inputRadius);
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: Material(
        color: c.inputBg,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.inputBorder),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.bgSubtle,
                      borderRadius: BorderRadius.circular(FreevaRadius.xs),
                    ),
                    child: SizedBox.square(
                      dimension: 32,
                      child: Icon(icon, size: 16, color: c.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: FreevaTypography.label.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FreevaTypography.body.copyWith(
                            fontSize: 16,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
