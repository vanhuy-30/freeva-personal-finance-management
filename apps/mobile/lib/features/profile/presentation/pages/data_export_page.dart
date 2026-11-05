import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/selectable_card.dart';
import '../../../transactions/domain/transaction_filter.dart';
import '../../../transactions/presentation/widgets/filter_pick_sheet.dart';
import '../../../transactions/presentation/widgets/filter_select_field.dart';
import '../../domain/export_period.dart';
import '../viewmodels/data_export_view_model.dart';

/// `MOB-P3-010` — Xuất dữ liệu (board `DataExport`): a filtered transactions
/// CSV, or the full JSON copy.
class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  final DataExportViewModel model = getIt<DataExportViewModel>();

  @override
  void initState() {
    super.initState();
    model.addListener(_changed);
    Future.microtask(model.load);
  }

  @override
  void dispose() {
    model.removeListener(_changed);
    model.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _export() async {
    final s = S.of(context);
    await model.export();
    if (!mounted || model.failure == null) return;
    showFreevaToast(context, message: s.meExportError);
  }

  Future<void> _pickPeriod(ExportPeriod period) async {
    if (period != ExportPeriod.custom) {
      model.selectPeriod(period);
      return;
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (range == null) return;
    String d(DateTime v) =>
        '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    model.selectPeriod(period, custom: DateRange(d(range.start), d(range.end)));
  }

  Future<void> _pickWallets() async {
    final picked = await showFilterPickSheet(
      context,
      title: S.of(context).dataExportWallets,
      selected: model.accountIds,
      options: [
        for (final wallet in model.wallets.where((w) => !w.archived))
          PickOption(wallet.id, wallet.draft.name),
      ],
    );
    if (picked != null) model.selectWallets(picked);
  }

  String _day(String date) =>
      '${date.substring(8, 10)}/${date.substring(5, 7)}';

  String _summary(S s) {
    final count = model.count;
    if (count == null) return '';
    final range = model.range;
    return range == null
        ? s.dataExportSummaryAll(count)
        : s.dataExportSummaryRange(_day(range.from), _day(range.to), count);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final table = model.kind == ExportKind.table;
    final names = {for (final w in model.wallets) w.id: w.draft.name};
    final walletValue = model.accountIds.isEmpty
        ? s.dataExportAllWallets
        : model.accountIds.map((id) => names[id] ?? '').join(', ');
    final labels = {
      ExportPeriod.thisMonth: s.dataExportPeriodThisMonth,
      ExportPeriod.last3Months: s.dataExportPeriod3Months,
      ExportPeriod.thisYear: s.dataExportPeriodThisYear,
      ExportPeriod.allTime: s.dataExportPeriodAll,
      ExportPeriod.custom: s.dataExportPeriodCustom,
    };
    final hint = !table
        ? s.dataExportFullNote
        : model.tooMany
        ? s.dataExportTooMany
        : _summary(s);
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.dataExportTitle,
        onLeading: () => context.popOrGo('/profile'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.screenMargin,
            0,
            context.screenMargin,
            FreevaSpace.s5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: FreevaSpace.s2),
                  children: [
                    SelectableCard(
                      label: s.dataExportTable,
                      subtitle: s.dataExportTableHint,
                      icon: LucideIcons.fileSpreadsheet,
                      selected: table,
                      iconBoxSize: 32,
                      iconBoxRadius: FreevaRadius.xs,
                      onTap: () => model.selectKind(ExportKind.table),
                    ),
                    const SizedBox(height: FreevaSpace.s2),
                    SelectableCard(
                      label: s.dataExportFull,
                      subtitle: s.dataExportFullHint,
                      icon: LucideIcons.archive,
                      selected: !table,
                      iconBoxSize: 32,
                      iconBoxRadius: FreevaRadius.xs,
                      onTap: () => model.selectKind(ExportKind.fullCopy),
                    ),
                    if (table) ...[
                      const SizedBox(height: FreevaSpace.s5),
                      Text(
                        s.txFilterPeriod,
                        style: FreevaTypography.label.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: FreevaSpace.s2),
                      Wrap(
                        spacing: FreevaSpace.s2,
                        runSpacing: FreevaSpace.s2,
                        children: [
                          for (final period in ExportPeriod.values)
                            FreevaChip(
                              label: labels[period]!,
                              icon: period == ExportPeriod.custom
                                  ? LucideIcons.calendar
                                  : null,
                              selected: model.period == period,
                              onTap: () => _pickPeriod(period),
                            ),
                        ],
                      ),
                      const SizedBox(height: FreevaSpace.s4),
                      FilterSelectField(
                        label: s.dataExportWallets,
                        value: walletValue,
                        onTap: _pickWallets,
                      ),
                    ],
                    const SizedBox(height: FreevaSpace.s3),
                    if (hint.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: FreevaSpace.s1),
                        child: Text(
                          hint,
                          style: FreevaTypography.bodyS.copyWith(
                            color: model.tooMany && table
                                ? c.statusDanger
                                : c.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: FreevaSpace.s3),
              FreevaButton(
                label: s.dataExportButton,
                icon: LucideIcons.share,
                size: FreevaButtonSize.l,
                expand: true,
                loading: model.exporting,
                onPressed: model.canExport ? _export : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
