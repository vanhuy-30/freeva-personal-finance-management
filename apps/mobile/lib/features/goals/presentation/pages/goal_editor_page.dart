import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../transactions/presentation/widgets/composer/wallet_picker_sheet.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/wallet_type_icon.dart';
import '../../domain/goal.dart';
import '../../domain/goal_math.dart';
import '../viewmodels/goal_view_model.dart';
import '../widgets/goal_date_sheet.dart';
import '../widgets/goal_kind_chip.dart';
import '../widgets/goal_look.dart';
import '../widgets/goal_need_card.dart';
import '../../../server_config/domain/app_limits.dart';

/// Mục tiêu mới / Sửa mục tiêu. A new goal opens the detail after saving; an
/// edit changes name, kind, target and date, and a changed "Đã có" is a
/// correction (no money moves). The wallet cannot change once set.
class GoalEditorPage extends StatefulWidget {
  const GoalEditorPage({this.goalId, this.initialKind, super.key});

  final String? goalId;
  final String? initialKind;

  @override
  State<GoalEditorPage> createState() => _GoalEditorPageState();
}

class _GoalEditorPageState extends State<GoalEditorPage> {
  late final GoalViewModel model = getIt<GoalViewModel>();
  final name = TextEditingController();
  final target = TextEditingController();
  final current = TextEditingController();
  Goal? existing;
  late String kind;
  bool nameTouched = false;
  String? targetDate;
  String? walletId;
  bool saving = false;
  bool inited = false;
  String? nameError;
  String? targetError;
  String? walletError;

  bool get editing => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    existing = widget.goalId == null ? null : model.byId(widget.goalId!);
    kind = existing?.kind ?? widget.initialKind ?? 'emergency';
    if (!model.loaded) Future.microtask(model.load);
  }

  @override
  void dispose() {
    name.dispose();
    target.dispose();
    current.dispose();
    super.dispose();
  }

  String get currency => existing?.currencyCode ?? model.totalCurrency;

  void _init(S s, String locale) {
    inited = true;
    final goal = existing;
    if (goal != null) {
      final digits = model.digitsOf(goal.currencyCode);
      name.text = goal.name;
      nameTouched = true;
      target.text = formatMoneyText(goal.targetMinor, digits, locale);
      current.text = formatMoneyText(goal.currentMinor, digits, locale);
      targetDate = goal.targetDate;
      walletId = goal.accountId;
      return;
    }
    name.text = goalKindLabel(s, kind);
    final wallets = model.walletsFor(currency);
    walletId = wallets.isEmpty ? null : wallets.first.id;
  }

  Wallet? get wallet =>
      model.wallets.where((w) => w.id == walletId).firstOrNull;

  BigInt? _money(String text, String locale) =>
      parseGroupedMoney(text, model.digitsOf(currency), locale);

  void _pickKind(S s, String value) => setState(() {
    kind = value;
    if (!nameTouched) {
      name.text = value == 'custom' ? '' : goalKindLabel(s, value);
    }
  });

  Future<void> _pickDate(S s) async {
    final picked = await showGoalDateSheet(
      context,
      firstDate: DateTime.parse(model.today),
      current: targetDate,
      clearable: true,
    );
    if (picked == null) return;
    setState(() => targetDate = picked.isEmpty ? null : picked);
  }

  Future<void> _pickWallet(S s, bool hidden) async {
    final wallets = model.walletsFor(currency);
    final picked = await showWalletPicker(
      context,
      title: s.goalWallet,
      wallets: wallets,
      selected: walletId,
      digitsOf: model.digitsOf,
      hideBalances: hidden,
    );
    if (picked != null) setState(() => walletId = picked);
  }

  Future<void> _save() async {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final label = name.text.trim();
    final targetMinor = _money(target.text, locale);
    final currentMinor = current.text.trim().isEmpty
        ? BigInt.zero
        : _money(current.text, locale);
    setState(() {
      nameError = label.isEmpty ? s.goalNameMissing : null;
      targetError = targetMinor == null || targetMinor <= BigInt.zero
          ? s.goalTargetMissing
          : null;
      walletError = walletId == null ? s.goalWalletMissing : null;
    });
    if (nameError != null ||
        targetError != null ||
        walletError != null ||
        currentMinor == null) {
      return;
    }
    setState(() => saving = true);
    Goal? saved;
    final old = existing;
    if (old == null) {
      saved = await model.create(
        GoalDraft(
          clientId: model.newClientId(),
          kind: kind,
          name: label,
          targetMinor: targetMinor!,
          accountId: walletId!,
          currentMinor: currentMinor,
          targetDate: targetDate,
        ),
      );
    } else {
      saved = old;
      final changed =
          label != old.name ||
          kind != old.kind ||
          targetMinor != old.targetMinor ||
          targetDate != old.targetDate;
      if (changed) {
        saved = await model.save(
          old,
          kind: kind,
          name: label,
          target: targetMinor!,
          targetDate: targetDate,
        );
      }
      if (saved != null && currentMinor != old.currentMinor) {
        saved = await model.adjust(saved, currentMinor);
      }
    }
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
    if (editing) {
      context.popOrGo('/me/goals/${saved.id}');
    } else {
      context.pushReplacement('/me/goals/${saved.id}');
    }
  }

  Future<void> _archive(S s) async {
    final goal = existing;
    if (goal == null) return;
    final ok = await showFreevaConfirm(
      context: context,
      title: s.goalArchive,
      message: s.goalArchiveBody,
      cancelLabel: s.commonCancel,
      confirmLabel: s.goalArchive,
    );
    if (!ok || !mounted) return;
    setState(() => saving = true);
    final archived = await model.archive(goal);
    if (!mounted) return;
    setState(() => saving = false);
    if (!archived) {
      showFreevaToast(context, message: s.goalSaveFailed);
      return;
    }
    context.go('/me/goals');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        if (editing && existing == null) {
          existing = model.byId(widget.goalId!);
          if (existing != null) kind = existing!.kind;
        }
        final ready = !editing || existing != null;
        if (ready &&
            !inited &&
            (editing || model.wallets.isNotEmpty || model.loaded)) {
          _init(s, locale);
        }
        final digits = model.digitsOf(currency);
        final targetMinor = _money(target.text, locale);
        final currentMinor = _money(current.text, locale) ?? BigInt.zero;
        final months = targetDate == null
            ? null
            : goalMonthsLeft(model.today, targetDate!);
        final need = targetMinor == null || targetMinor <= BigInt.zero
            ? null
            : goalRequiredPerMonth(targetMinor, currentMinor, months);
        final share = goalIncomeShareBps(need, model.incomeFor(currency));
        final margin = context.screenMargin;
        return Scaffold(
          appBar: FreevaTopBar(
            title: editing ? s.goalsEdit : s.goalsNew,
            kind: FreevaTopBarKind.modal,
            onLeading: () => context.popOrGo('/me/goals'),
          ),
          body: !ready
              ? const SizedBox.shrink()
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(margin, 0, margin, 14),
                          children: [
                            const SizedBox(height: 6),
                            _label(context, s.goalsFor),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: FreevaSpace.s2,
                              runSpacing: FreevaSpace.s2,
                              children: [
                                for (final item in goalKinds)
                                  GoalKindChip(
                                    kind: item,
                                    label: goalKindLabel(s, item),
                                    selected: item == kind,
                                    onTap: () => _pickKind(s, item),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            FreevaTextField(
                              label: s.goalName,
                              controller: name,
                              error: nameError,
                              maxLength: getIt<AppLimitsSource>()
                                  .requireLimits
                                  .goalNameMaxLength,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => nameTouched = true,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _moneyField(
                                    s.goalTarget,
                                    target,
                                    digits,
                                    locale,
                                    targetError,
                                  ),
                                ),
                                const SizedBox(width: FreevaSpace.s2),
                                Expanded(
                                  child: _moneyField(
                                    s.goalCurrent,
                                    current,
                                    digits,
                                    locale,
                                    null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            PickerField(
                              label: s.goalDate,
                              value: targetDate == null
                                  ? s.goalDateNone
                                  : goalMonthLabel(targetDate!, locale),
                              placeholder: targetDate == null,
                              leading: FieldIconTile(
                                icon: LucideIcons.calendar,
                                background: c.bgSubtle,
                                foreground: c.textOnWash,
                              ),
                              onTap: () => _pickDate(s),
                            ),
                            const SizedBox(height: 14),
                            BalancesHiddenBuilder(
                              builder: (context, hidden) => PickerField(
                                label: s.goalWallet,
                                value: _walletValue(s, digits, locale, hidden),
                                placeholder: wallet == null,
                                leading: wallet == null
                                    ? FieldIconTile(
                                        icon: LucideIcons.landmark,
                                        background: c.tintBlue,
                                        foreground: c.tintBlueFg,
                                      )
                                    : WalletTypeIcon(
                                        type: wallet!.draft.type,
                                        size: 32,
                                      ),
                                onTap: editing
                                    ? () {}
                                    : () => _pickWallet(s, hidden),
                              ),
                            ),
                            if (walletError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                walletError!,
                                style: FreevaTypography.bodyS.copyWith(
                                  color: c.statusDanger,
                                ),
                              ),
                            ],
                            if (need != null && need > BigInt.zero) ...[
                              const SizedBox(height: 14),
                              GoalNeedCard(
                                amount: formatMoneyText(need, digits, locale),
                                percent: share == null
                                    ? null
                                    : (share / 100).round(),
                              ),
                            ],
                            if (editing) ...[
                              const SizedBox(height: 14),
                              Center(
                                child: TextButton(
                                  onPressed: saving ? null : () => _archive(s),
                                  child: Text(
                                    s.goalArchive,
                                    style: FreevaTypography.bodyM.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: c.statusDanger,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(margin, 0, margin, 28),
                        child: FreevaButton(
                          label: editing ? s.goalSaveAction : s.goalsCreate,
                          size: FreevaButtonSize.l,
                          expand: true,
                          loading: saving,
                          onPressed: saving ? null : _save,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  String _walletValue(S s, int digits, String locale, bool hidden) {
    final w = wallet;
    if (w == null) return s.goalDateNone;
    final left = hidden
        ? '••••••'
        : formatMoneyText(w.balance, model.digitsOf(w.draft.currency), locale);
    return s.goalWalletValue(w.draft.name, left);
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      text.toUpperCase(),
      style: FreevaTypography.sectionLabel.copyWith(
        color: context.colors.textSecondary,
      ),
    ),
  );

  Widget _moneyField(
    String label,
    TextEditingController controller,
    int digits,
    String locale,
    String? error,
  ) => FreevaTextField(
    label: label,
    controller: controller,
    tabular: true,
    error: error,
    keyboardType: TextInputType.numberWithOptions(decimal: digits > 0),
    inputFormatters: [
      MoneyInputFormatter(minorDigits: digits, locale: locale),
      LengthLimitingTextInputFormatter(24),
    ],
    onChanged: (_) => setState(() {}),
  );
}
