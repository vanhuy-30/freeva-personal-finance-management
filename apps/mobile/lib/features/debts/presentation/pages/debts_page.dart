import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../loans/presentation/viewmodels/loan_view_model.dart';
import '../../../loans/presentation/widgets/loans_tab.dart';
import '../viewmodels/debt_view_model.dart';
import '../widgets/debts_people_tab.dart';

/// Vay và nợ: Người quen (lend / borrow with people you know) and Khoản vay
/// (bank loans with interest). Reached from Cá nhân → Thiết lập tài chính.
class DebtsPage extends StatefulWidget {
  const DebtsPage({this.loans = false, super.key});

  /// Open on the Khoản vay tab (`?tab=loans`).
  final bool loans;

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  late final DebtViewModel debts = getIt<DebtViewModel>();
  late final LoanViewModel loans = getIt<LoanViewModel>();
  late bool _loansTab = widget.loans;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      debts.load();
      loans.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([debts, loans]),
      builder: (context, _) {
        final showAdd = _loansTab
            ? loans.loaded && !loans.isEmpty
            : debts.loaded && !debts.isEmpty;
        final margin = context.screenMargin;
        return Scaffold(
          appBar: FreevaTopBar(
            title: s.meDebts,
            onLeading: () => context.popOrGo('/me'),
            action: showAdd
                ? FreevaIconButton(
                    icon: LucideIcons.plus,
                    label: _loansTab ? s.loansAdd : s.debtsAdd,
                    onPressed: () => context.push(
                      _loansTab ? '/me/debts/loans/new' : '/me/debts/new',
                    ),
                  )
                : null,
          ),
          body: Padding(
            padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FreevaSegmented<bool>(
                  expand: true,
                  selected: _loansTab,
                  segments: [
                    FreevaSegment(false, s.debtsTabPeople),
                    FreevaSegment(true, s.debtsTabLoans),
                  ],
                  onChanged: (value) => setState(() => _loansTab = value),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _loansTab
                      ? LoansTab(model: loans)
                      : DebtsPeopleTab(model: debts),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
