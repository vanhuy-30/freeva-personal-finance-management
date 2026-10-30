import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/amount_keypad.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../settings/presentation/widgets/choice_sheet.dart';
import '../../domain/budget.dart';
import '../viewmodels/budget_view_model.dart';
import '../widgets/budget_progress_card.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({this.on, super.key});

  /// Fiscal-month anchor (`YYYY-MM-DD`) when opened from Reports.
  final String? on;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late final BudgetViewModel model = getIt<BudgetViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.on != null) {
        model.load(on: widget.on);
      } else {
        model.load(applyTo: BudgetApplyTo.defaultTemplate);
      }
    });
  }

  void _reload() {
    if (model.applyTo == BudgetApplyTo.month) {
      model.load(on: model.monthOn ?? widget.on);
    } else {
      model.load(applyTo: BudgetApplyTo.defaultTemplate);
    }
  }

  void _toastFailure() {
    final s = S.of(context);
    final conflict = model.failure?.code == AuthError.conflict;
    showFreevaToast(context, message: conflict ? s.meConflict : s.meSaveError);
    if (conflict) _reload();
  }

  Future<void> _save() async {
    final ok = await model.save();
    if (!mounted) return;
    if (ok) {
      showFreevaToast(context, message: S.of(context).budgetSaved);
    } else {
      _toastFailure();
    }
  }

  Future<void> _clear() async {
    final s = S.of(context);
    final month = model.applyTo == BudgetApplyTo.month;
    final ok = await showFreevaConfirm(
      context: context,
      title: month ? s.budgetClearMonthTitle : s.budgetClearTitle,
      message: month ? s.budgetClearMonthBody : s.budgetClearBody,
      icon: LucideIcons.trash2,
      iconTone: FreevaDialogTone.danger,
      cancelLabel: s.commonCancel,
      confirmLabel: month ? s.budgetClearMonthAction : s.budgetClearAction,
      destructive: true,
    );
    if (!ok) return;
    final cleared = await model.clear();
    if (!mounted) return;
    if (cleared) {
      showFreevaToast(
        context,
        message: month ? s.budgetMonthCleared : s.budgetCleared,
      );
    } else {
      _toastFailure();
    }
  }

  Future<void> _addCategory() async {
    final s = S.of(context);
    final used = {for (final line in model.draftLines) line.categoryId};
    final options = [
      for (final category in model.expenseCategories)
        if (!used.contains(category.id)) Choice(category.id, category.name),
    ];
    if (options.isEmpty) {
      showFreevaToast(context, message: s.budgetNoCategories);
      return;
    }
    final picked = await showChoiceSheet<String>(
      context,
      title: s.budgetAddCategory,
      selected: options.first.value,
      options: options,
    );
    if (picked == null) return;
    final amount = await _askAmount(s.budgetCategoryLimit);
    if (amount == null || amount <= BigInt.zero) return;
    model.setCategoryLimit(picked, amount);
  }

  Future<BigInt?> _askAmount(String title) async {
    final s = S.of(context);
    var digits = '';
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            final locale = Localizations.localeOf(context).toString();
            final display = digits.isEmpty
                ? '0'
                : formatMoneyText(BigInt.parse(digits), 0, locale);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: FreevaTypography.titleL),
                  const SizedBox(height: FreevaSpace.s4),
                  Text(
                    display,
                    textAlign: TextAlign.center,
                    style: FreevaTypography.moneyDisplay.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: FreevaSpace.s4),
                  AmountKeypad(
                    filled: false,
                    onDigits: (value) {
                      setSheet(() {
                        final next = '$digits$value';
                        if (next.length <= 12) {
                          digits = next.replaceFirst(RegExp(r'^0+(?=.)'), '');
                        }
                      });
                    },
                    onDelete: () => setSheet(() {
                      if (digits.isNotEmpty) {
                        digits = digits.substring(0, digits.length - 1);
                      }
                    }),
                  ),
                  const SizedBox(height: FreevaSpace.s4),
                  FreevaButton(
                    label: s.budgetSave,
                    onPressed: digits.isEmpty
                        ? null
                        : () => Navigator.pop(context, true),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (confirmed != true || digits.isEmpty) return null;
    return BigInt.parse(digits);
  }

  Future<void> _editOverall() async {
    final amount = await _askAmount(S.of(context).budgetOverallLimit);
    if (amount == null) return;
    model.setLimit(amount);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final margin = context.screenMargin;
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.budgetTitle,
        onLeading: () => context.popOrGo('/me'),
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          if (!model.loaded && model.failure != null) {
            return ErrorRetry(
              title: s.budgetLoadError,
              message: s.homeErrorBody,
              onRetry: _reload,
            );
          }
          if (!model.loaded) {
            return ListView(
              padding: EdgeInsets.all(margin),
              children: const [
                SkeletonBox(height: 180, radius: 24),
                SizedBox(height: 16),
                SkeletonBox(height: 120, radius: 24),
              ],
            );
          }
          final names = {
            for (final category in model.expenseCategories)
              category.id: category.name,
          };
          final showClear = model.applyTo == BudgetApplyTo.defaultTemplate
              ? model.summary != null && !model.isOverride
              : model.isOverride;
          return ListView(
            padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 40),
            children: [
              FreevaSegmented<BudgetApplyTo>(
                expand: true,
                style: FreevaSegmentedStyle.raised,
                selected: model.applyTo,
                onChanged: model.selectApplyTo,
                segments: [
                  FreevaSegment(
                    BudgetApplyTo.defaultTemplate,
                    s.budgetScopeDefault,
                  ),
                  FreevaSegment(BudgetApplyTo.month, s.budgetScopeMonth),
                ],
              ),
              if (model.applyTo == BudgetApplyTo.month) ...[
                const SizedBox(height: FreevaSpace.s2),
                Text(
                  model.isOverride
                      ? s.budgetScopeMonthOverrideHint
                      : s.budgetScopeMonthHint,
                  style: FreevaTypography.label.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: FreevaSpace.s4),
              if (model.summary case final summary?) ...[
                BudgetProgressCard(summary: summary, minorDigits: 0),
                const SizedBox(height: FreevaSpace.s4),
              ],
              FreevaCard(
                onTap: _editOverall,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.budgetOverallLimit,
                            style: FreevaTypography.label.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            model.draftLimit <= BigInt.zero
                                ? s.budgetTapToSet
                                : formatMoneyText(model.draftLimit, 0, locale),
                            style: FreevaTypography.titleL.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.pencil, size: 18, color: c.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: FreevaSpace.s4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.budgetCategoriesTitle,
                      style: FreevaTypography.titleM.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addCategory,
                    icon: Icon(LucideIcons.plus, size: 16, color: c.actionInk),
                    label: Text(s.budgetAddCategory),
                  ),
                ],
              ),
              if (model.draftLines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    s.budgetCategoriesHint,
                    style: FreevaTypography.bodyM.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                )
              else
                for (final line in model.draftLines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FreevaCard(
                      list: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              names[line.categoryId] ?? s.budgetUnknownCategory,
                              style: FreevaTypography.titleM,
                            ),
                          ),
                          Text(
                            formatMoneyText(line.limitMinor, 0, locale),
                            style: FreevaTypography.titleM,
                          ),
                          IconButton(
                            onPressed: () =>
                                model.removeCategory(line.categoryId),
                            icon: Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: c.statusDanger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: FreevaSpace.s4),
              FreevaCard(
                onTap: () async {
                  const presets = <List<int>>[
                    [70, 80, 90, 100],
                    [80, 100],
                    [90, 100],
                    [100],
                  ];
                  String labelOf(List<int> t) => t.join(' · ');
                  final picked = await showChoiceSheet<String>(
                    context,
                    title: s.budgetThresholdsTitle,
                    selected: labelOf(model.draftThresholds),
                    options: [
                      for (final preset in presets)
                        Choice(labelOf(preset), labelOf(preset)),
                    ],
                  );
                  if (picked == null) return;
                  model.setThresholds([
                    for (final part in picked.split(' · ')) int.parse(part),
                  ]);
                },
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.budgetThresholdsTitle,
                            style: FreevaTypography.label.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            model.draftThresholds.map((t) => '$t%').join(' · '),
                            style: FreevaTypography.titleM.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.pencil, size: 18, color: c.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: FreevaSpace.s5),
              FreevaButton(
                label: s.budgetSave,
                loading: model.busy,
                onPressed: model.draftLimit <= BigInt.zero || model.busy
                    ? null
                    : _save,
              ),
              if (showClear) ...[
                const SizedBox(height: FreevaSpace.s3),
                FreevaButton(
                  label: model.applyTo == BudgetApplyTo.month
                      ? s.budgetClearMonthAction
                      : s.budgetClearAction,
                  variant: FreevaButtonVariant.secondary,
                  onPressed: model.busy ? null : _clear,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
