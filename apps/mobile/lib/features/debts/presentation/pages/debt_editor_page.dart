import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/sheet_amount_field.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../transactions/presentation/widgets/composer/date_picker_sheet.dart';
import '../../../transactions/presentation/widgets/composer/wallet_picker_sheet.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../../../wallets/presentation/widgets/wallet_type_icon.dart';
import '../../domain/personal_debt.dart';
import '../viewmodels/debt_view_model.dart';
import '../widgets/debt_parts.dart';
import '../../../server_config/domain/app_limits.dart';

/// Ghi khoản mượn (DebtAdd): Cho mượn · Đi mượn, amount, person, wallet,
/// date + due date, note. Editing keeps the money fixed (the API only
/// changes the person, due date and note).
class DebtEditorPage extends StatefulWidget {
  const DebtEditorPage({this.debtId, super.key});

  final String? debtId;

  @override
  State<DebtEditorPage> createState() => _DebtEditorPageState();
}

class _DebtEditorPageState extends State<DebtEditorPage> {
  late final DebtViewModel model = getIt<DebtViewModel>();
  final amount = TextEditingController();
  final person = TextEditingController();
  final note = TextEditingController();
  DebtDirection direction = DebtDirection.lent;
  String? walletId;
  late String occurredOn = model.today;
  String? dueDate;
  bool saving = false;
  bool ready = false;
  PersonalDebt? existing;

  /// Kept for the whole screen so a resend never records the debt twice.
  late final String clientId = model.newClientId();

  bool get editing => widget.debtId != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (!model.loaded) await model.load();
    if (!mounted) return;
    final debt = editing ? model.byId(widget.debtId!) : null;
    existing = debt;
    if (debt != null) {
      direction = debt.direction;
      person.text = debt.counterparty;
      note.text = debt.note ?? '';
      dueDate = debt.dueDate;
      occurredOn = debt.occurredOn;
      walletId = debt.accountId;
    } else {
      walletId = model.wallets.firstOrNull?.id;
    }
    setState(() => ready = true);
  }

  @override
  void dispose() {
    amount.dispose();
    person.dispose();
    note.dispose();
    super.dispose();
  }

  Wallet? get wallet =>
      model.wallets.where((w) => w.id == walletId).firstOrNull;

  String get _currency => wallet?.draft.currency ?? 'VND';

  BigInt? _value(String locale) =>
      parseGroupedMoney(amount.text, model.digitsOf(_currency), locale);

  Future<void> _pickWallet(S s, bool hidden) async {
    final picked = await showWalletPicker(
      context,
      title: direction == DebtDirection.lent
          ? s.debtFromWallet
          : s.debtToWallet,
      wallets: model.wallets,
      selected: walletId,
      digitsOf: model.digitsOf,
      hideBalances: hidden,
    );
    if (picked != null) setState(() => walletId = picked);
  }

  Future<void> _pickDate({required bool due}) async {
    final picked = await showDatePickerSheet(
      context,
      value: due ? (dueDate ?? occurredOn) : occurredOn,
      today: model.today,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (due) {
        dueDate = picked;
      } else {
        occurredOn = picked;
        if (dueDate != null && dueDate!.compareTo(picked) < 0) dueDate = null;
      }
    });
  }

  bool _ready(String locale) {
    if (person.text.trim().isEmpty || saving) return false;
    if (editing) return true;
    final value = _value(locale);
    return value != null && value > BigInt.zero && walletId != null;
  }

  Future<void> _save() async {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    if (dueDate != null && dueDate!.compareTo(occurredOn) < 0) {
      showFreevaToast(context, message: s.debtDueBeforeDate);
      return;
    }
    setState(() => saving = true);
    final old = existing;
    final text = note.text.trim();
    final PersonalDebt? saved;
    if (old != null) {
      saved = await model.save(
        old,
        counterparty: person.text,
        dueDate: dueDate,
        note: text.isEmpty ? null : text,
      );
    } else {
      saved = await model.create(
        DebtDraft(
          clientId: clientId,
          direction: direction,
          counterparty: person.text,
          amountMinor: _value(locale)!,
          accountId: walletId!,
          occurredOn: occurredOn,
          dueDate: dueDate,
          note: text.isEmpty ? null : text,
        ),
      );
    }
    if (!mounted) return;
    setState(() => saving = false);
    if (saved != null) {
      if (old != null) {
        context.pop();
      } else {
        context.pushReplacement('/me/debts/${saved.id}');
      }
      return;
    }
    showFreevaToast(
      context,
      message: model.failure?.code == AuthError.conflict
          ? s.meConflict
          : s.meSaveError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    final locale = Localizations.localeOf(context).toString();
    return BalancesHiddenBuilder(
      builder: (context, hidden) => Scaffold(
        appBar: editing
            ? FreevaTopBar(
                title: s.debtEditTitle,
                kind: FreevaTopBarKind.modal,
                onLeading: () => context.popOrGo('/me/debts'),
              )
            : _DirectionBar(
                direction: direction,
                onClose: () => context.popOrGo('/me/debts'),
                onChanged: (value) => setState(() => direction = value),
              ),
        body: !ready
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(child: _form(context, s, margin, hidden)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(margin, 0, margin, 28),
                    child: FreevaButton(
                      label: s.debtSave,
                      size: FreevaButtonSize.l,
                      expand: true,
                      loading: saving,
                      onPressed: _ready(locale) ? _save : null,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _form(BuildContext context, S s, double margin, bool hidden) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final lent = direction == DebtDirection.lent;
    final w = wallet;
    final digits = model.digitsOf(_currency);
    final walletValue = w == null
        ? s.recNeedWallet
        : hidden
        ? w.draft.name
        : s.debtWalletLeft(
            w.draft.name,
            formatMoneyText(
              w.balance,
              model.digitsOf(w.draft.currency),
              locale,
            ),
          );
    final dueField = PickerField(
      chevron: false,
      label: s.debtDueDate,
      value: dueDate == null ? s.debtPickDate : debtDay(dueDate!),
      placeholder: dueDate == null,
      leading: FieldIconTile(
        icon: LucideIcons.calendarClock,
        background: c.statusWarningBg,
        foreground: c.statusWarning,
      ),
      onTap: () => _pickDate(due: true),
    );
    final fields = <Widget>[
      if (!editing)
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Column(
            children: [
              Text(
                s.debtAmount,
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
                symbol: MoneyDisplay.symbolFor(_currency),
                fontSize: 48,
                lineHeight: 52,
                caretHeight: 34,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
      FreevaTextField(
        label: lent ? s.debtBorrower : s.debtLender,
        controller: person,
        maxLength: getIt<AppLimitsSource>().requireLimits.debtNameMaxLength,
        leadingIcon: LucideIcons.user,
        leadingTint: (c.tintBlue, c.tintBlueFg),
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
      ),
      if (!editing)
        PickerField(
          chevron: false,
          label: lent ? s.debtFromWallet : s.debtToWallet,
          value: walletValue,
          placeholder: w == null,
          leading: w == null
              ? FieldIconTile(
                  icon: LucideIcons.wallet,
                  background: c.tintCyan,
                  foreground: c.tintCyanFg,
                )
              : WalletTypeIcon(type: w.draft.type, size: 32),
          onTap: () => _pickWallet(s, hidden),
        ),
      if (editing)
        dueField
      else
        FormPair(
          first: PickerField(
            chevron: false,
            label: s.debtDate,
            value: occurredOn == model.today ? s.txToday : debtDay(occurredOn),
            leading: FieldIconTile(
              icon: LucideIcons.calendar,
              background: c.bgSubtle,
              foreground: c.textOnWash,
            ),
            onTap: () => _pickDate(due: false),
          ),
          second: dueField,
        ),
      FreevaTextField(
        label: s.debtNote,
        hint: s.debtNoteHint,
        controller: note,
        maxLength: getIt<AppLimitsSource>().requireLimits.noteMaxLength,
        leadingIcon: LucideIcons.textAlignStart,
      ),
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                s.debtNotCounted,
                style: FreevaTypography.bodyS.copyWith(
                  height: 18 / 13,
                  color: c.textSecondary,
                ),
              ),
            ),
            if (dueDate != null)
              TextButton(
                onPressed: () => setState(() => dueDate = null),
                child: Text(
                  s.debtClearDue,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textLink,
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 14),
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          fields[i],
        ],
      ],
    );
  }
}

/// Close on the left and Cho mượn · Đi mượn (220 wide) in the middle.
class _DirectionBar extends StatelessWidget implements PreferredSizeWidget {
  const _DirectionBar({
    required this.direction,
    required this.onClose,
    required this.onChanged,
  });

  final DebtDirection direction;
  final VoidCallback onClose;
  final ValueChanged<DebtDirection> onChanged;

  @override
  Size get preferredSize => const Size.fromHeight(FreevaSize.touch + 16);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Material(
      color: c.bgCanvas,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenMargin,
            vertical: FreevaSpace.s2,
          ),
          child: SizedBox(
            height: FreevaSize.touch,
            child: Row(
              children: [
                FreevaIconButton(
                  icon: LucideIcons.x,
                  iconSize: FreevaSize.iconSm,
                  label: s.commonClose,
                  onPressed: onClose,
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: FreevaSegmented<DebtDirection>(
                        expand: true,
                        selected: direction,
                        segments: [
                          FreevaSegment(DebtDirection.lent, s.debtLend),
                          FreevaSegment(DebtDirection.borrowed, s.debtBorrow),
                        ],
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: FreevaSize.touch),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
