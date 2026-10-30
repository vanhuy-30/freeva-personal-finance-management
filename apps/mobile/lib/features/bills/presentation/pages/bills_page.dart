import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/bill.dart';
import '../viewmodels/bill_view_model.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  late final BillViewModel model = getIt<BillViewModel>();
  String? filter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => model.load());
  }

  Future<void> _setFilter(String? value) async {
    setState(() => filter = value);
    await model.load(status: value);
  }

  String _statusLabel(S s, Bill bill) {
    if (bill.paid) return s.billsStatusPaid;
    if (bill.overdue) return s.billsStatusOverdue;
    return s.billsStatusOpen;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.billsTitle,
        onLeading: () => context.popOrGo('/me'),
        action: FreevaIconButton(
          icon: LucideIcons.plus,
          label: s.billsAdd,
          onPressed: model.loaded ? () => context.push('/me/bills/new') : null,
        ),
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          if (!model.loaded && model.failure != null) {
            return ErrorRetry(
              title: s.billsLoadError,
              message: s.homeErrorBody,
              onRetry: () => model.load(status: filter),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FreevaSpace.s4,
                  FreevaSpace.s3,
                  FreevaSpace.s4,
                  FreevaSpace.s2,
                ),
                child: Wrap(
                  spacing: FreevaSpace.s2,
                  children: [
                    FreevaChip(
                      label: s.billsFilterAll,
                      kind: FreevaChipKind.filter,
                      selected: filter == null,
                      onTap: () => _setFilter(null),
                    ),
                    FreevaChip(
                      label: s.billsStatusOpen,
                      kind: FreevaChipKind.filter,
                      selected: filter == 'open',
                      onTap: () => _setFilter('open'),
                    ),
                    FreevaChip(
                      label: s.billsStatusOverdue,
                      kind: FreevaChipKind.filter,
                      selected: filter == 'overdue',
                      onTap: () => _setFilter('overdue'),
                    ),
                    FreevaChip(
                      label: s.billsStatusPaid,
                      kind: FreevaChipKind.filter,
                      selected: filter == 'paid',
                      onTap: () => _setFilter('paid'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: !model.loaded
                    ? const Padding(
                        padding: EdgeInsets.all(FreevaSpace.s4),
                        child: SkeletonRows(count: 4),
                      )
                    : model.bills.isEmpty
                    ? EmptyState(
                        title: s.billsEmptyTitle,
                        message: s.billsEmptyBody,
                        actionLabel: s.billsAdd,
                        onAction: () => context.push('/me/bills/new'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(FreevaSpace.s4),
                        itemCount: model.bills.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: FreevaSpace.s3),
                        itemBuilder: (context, index) {
                          final bill = model.bills[index];
                          final amount = formatMoneyText(
                            bill.amountMinor,
                            0,
                            locale,
                          );
                          return FreevaCard(
                            onTap: () => context.push('/me/bills/${bill.id}'),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bill.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: FreevaSpace.s1),
                                      Text(
                                        '$amount ${bill.currencyCode} · ${bill.dueOn}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: c.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _statusLabel(s, bill),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: bill.overdue
                                            ? c.statusDanger
                                            : bill.paid
                                            ? c.statusSuccess
                                            : c.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
