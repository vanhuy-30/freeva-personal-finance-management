import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/sheet_amount_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/wallet_type_icon.dart';
import '../../domain/goal.dart';
import '../viewmodels/goal_view_model.dart';
import '../../../../core/money/currency_catalog.dart';

/// Góp vào / Rút ra over the goal detail. Returns true when something was
/// recorded. Taking money from another wallet is a wallet transfer; "Đã nằm
/// trong …" only records it.
Future<bool?> showGoalMoveSheet(
  BuildContext context,
  GoalViewModel model,
  Goal goal, {
  required bool out,
}) => showFreevaSheet<bool>(
  context: context,
  builder: (context) => _MoveSheet(model: model, goal: goal, out: out),
);

class _MoveSheet extends StatefulWidget {
  const _MoveSheet({
    required this.model,
    required this.goal,
    required this.out,
  });

  final GoalViewModel model;
  final Goal goal;
  final bool out;

  @override
  State<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends State<_MoveSheet> {
  final amount = TextEditingController();
  late bool out = widget.out;
  String? walletId;
  bool picked = false;
  bool saving = false;
  String? _clientId;
  String? _clientKey;

  GoalViewModel get model => widget.model;
  Goal get goal => widget.goal;

  List<Wallet> get others => [
    for (final w in model.walletsFor(goal.currencyCode))
      if (w.id != goal.accountId) w,
  ];

  Wallet? get home =>
      model.wallets.where((w) => w.id == goal.accountId).firstOrNull;

  @override
  void initState() {
    super.initState();
    walletId = others.isEmpty ? null : others.first.id;
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  BigInt? _value(String locale) =>
      parseGroupedMoney(amount.text, model.digitsOf(goal.currencyCode), locale);

  Future<void> _submit(String locale) async {
    final s = S.of(context);
    final value = _value(locale);
    if (value == null || value <= BigInt.zero) return;
    final key = '$out|$walletId|$value';
    if (_clientKey != key) {
      _clientKey = key;
      _clientId = model.newClientId();
    }
    final move = GoalMove(
      clientId: _clientId!,
      amountMinor: value,
      occurredOn: model.today,
      accountId: walletId,
    );
    setState(() => saving = true);
    final saved = out
        ? await model.withdraw(goal, move)
        : await model.contribute(goal, move);
    if (!mounted) return;
    setState(() => saving = false);
    if (saved == null) {
      final conflict = model.failure?.code == AuthError.conflict;
      showFreevaToast(
        context,
        message: conflict ? s.goalConflict : s.goalSaveFailed,
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final digits = model.digitsOf(goal.currencyCode);
    final value = _value(locale);
    final tooMuch = out && value != null && value > goal.currentMinor;
    final ready = value != null && value > BigInt.zero && !tooMuch;
    final symbol = CurrencyCatalog.current.symbol(goal.currencyCode);
    final confirm = value == null || value == BigInt.zero
        ? (out ? s.goalMoveOut : s.goalMoveIn)
        : (out ? s.goalMoveConfirmOut : s.goalMoveConfirmIn)(
            '${formatMoneyText(value, digits, locale)} $symbol',
          );
    return BalancesHiddenBuilder(
      builder: (context, hidden) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: out
                ? s.goalMoveTitleOut(goal.name)
                : s.goalMoveTitleIn(goal.name),
            child: Center(
              child: SizedBox(
                width: 220,
                child: FreevaSegmented<bool>(
                  expand: true,
                  selected: out,
                  segments: [
                    FreevaSegment(false, s.goalMoveIn),
                    FreevaSegment(true, s.goalMoveOut),
                  ],
                  onChanged: (v) => setState(() => out = v),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Text(
                  s.goalMoveAmount,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                SheetAmountField(
                  controller: amount,
                  digits: digits,
                  locale: locale,
                  symbol: symbol,
                  onChanged: () => setState(() {}),
                ),
                if (tooMuch)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      s.goalMoveTooMuch,
                      style: FreevaTypography.bodyS.copyWith(
                        color: c.statusDanger,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              (out ? s.goalMoveTo : s.goalMoveFrom).toUpperCase(),
              style: FreevaTypography.sectionLabel.copyWith(
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FreevaCard(
            list: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final w in others)
                  _Option(
                    leading: WalletTypeIcon(type: w.draft.type, size: 32),
                    title: w.draft.name,
                    subtitle: s.goalMoveWalletLeft(
                      hidden
                          ? '••••••'
                          : formatMoneyText(
                              w.balance,
                              model.digitsOf(w.draft.currency),
                              locale,
                            ),
                    ),
                    selected: walletId == w.id,
                    onTap: () => setState(() => walletId = w.id),
                  ),
                if (home case final Wallet h)
                  _Option(
                    leading: WalletTypeIcon(type: h.draft.type, size: 32),
                    title: out
                        ? s.goalMoveStaysOut(h.draft.name)
                        : s.goalMoveStaysIn(h.draft.name),
                    subtitle: s.goalMoveOnlyRecord,
                    selected: walletId == null,
                    divider: others.isNotEmpty,
                    onTap: () => setState(() => walletId = null),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              s.goalMoveHint,
              style: FreevaTypography.bodyS.copyWith(
                height: 18 / 13,
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          FreevaButton(
            label: confirm,
            size: FreevaButtonSize.l,
            expand: true,
            loading: saving,
            onPressed: ready && !saving ? () => _submit(locale) : null,
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.divider = false,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Color.lerp(c.bgSurface, c.tintBlue, .5)
                : Colors.transparent,
            border: divider
                ? Border(top: BorderSide(color: c.listDivider))
                : null,
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.actionPrimary : c.borderStrong,
                    width: selected ? 6 : 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
