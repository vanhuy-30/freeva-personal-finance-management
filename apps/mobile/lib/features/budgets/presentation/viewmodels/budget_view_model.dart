import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../categories/domain/category_repository.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../settings/domain/settings_repository.dart';
import '../../domain/budget.dart';
import '../../domain/budget_use_cases.dart';

abstract class BudgetViewModel extends ChangeNotifier {
  bool get busy;
  bool get loaded;
  AuthFailure? get failure;
  BudgetSummary? get summary;
  BudgetPeriod? get period;
  List<FinanceCategory> get expenseCategories;
  String get currency;
  BigInt get draftLimit;
  List<BudgetCategoryDraft> get draftLines;
  List<int> get draftThresholds;
  BudgetApplyTo get applyTo;
  /// Fiscal-month anchor when editing a specific month (`period.from`).
  String? get monthOn;
  bool get isOverride;
  Future<void> selectApplyTo(BudgetApplyTo value);
  void setLimitDigits(String digits);
  void setLimit(BigInt value);
  void setCategoryLimit(String categoryId, BigInt limit);
  void removeCategory(String categoryId);
  void setThresholds(List<int> thresholds);
  Future<void> load({String? on, BudgetApplyTo? applyTo});
  Future<bool> save();
  Future<bool> clear();
}

@LazySingleton(as: BudgetViewModel)
class DefaultBudgetViewModel extends BudgetViewModel {
  DefaultBudgetViewModel(
    this._cases,
    this._categories,
    this._profile,
    this._settings,
    this._auth,
  ) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final BudgetUseCases _cases;
  final CategoryRepository _categories;
  final ProfileViewModel _profile;
  final SettingsRepository _settings;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _epoch = 0;

  @override
  bool busy = false;
  @override
  bool loaded = false;
  @override
  AuthFailure? failure;
  @override
  BudgetSummary? summary;
  @override
  BudgetPeriod? period;
  @override
  List<FinanceCategory> expenseCategories = const [];
  @override
  BigInt draftLimit = BigInt.zero;
  @override
  List<BudgetCategoryDraft> draftLines = const [];
  @override
  List<int> draftThresholds = List.of(defaultAlertThresholds);
  @override
  BudgetApplyTo applyTo = BudgetApplyTo.defaultTemplate;
  @override
  String? monthOn;

  @override
  bool get isOverride => summary?.isOverride ?? false;

  @override
  String get currency => _profile.saved?.currency ?? 'VND';

  void _authChanged() {
    if (_auth.stage == _stage) return;
    _stage = _auth.stage;
    _epoch++;
    summary = null;
    period = null;
    loaded = false;
    failure = null;
    draftLimit = BigInt.zero;
    draftLines = const [];
    draftThresholds = List.of(defaultAlertThresholds);
    applyTo = BudgetApplyTo.defaultTemplate;
    monthOn = null;
    notifyListeners();
  }

  void _applyDraft(BudgetSummary? budget) {
    summary = budget;
    if (budget == null) {
      draftLimit = BigInt.zero;
      draftLines = const [];
      draftThresholds = List.of(defaultAlertThresholds);
      return;
    }
    draftLimit = budget.limitMinor;
    draftLines = List.unmodifiable([
      for (final line in budget.categories)
        BudgetCategoryDraft(
          categoryId: line.categoryId,
          limitMinor: line.limitMinor,
        ),
    ]);
    draftThresholds = List.unmodifiable(budget.alertThresholds);
  }

  @override
  Future<void> selectApplyTo(BudgetApplyTo value) async {
    if (applyTo == value) return;
    applyTo = value;
    notifyListeners();
    if (value == BudgetApplyTo.month) {
      await load(on: monthOn ?? period?.from);
    } else {
      await load(applyTo: BudgetApplyTo.defaultTemplate);
    }
  }

  @override
  void setLimitDigits(String digits) {
    final cleaned = digits.replaceAll(RegExp(r'[^0-9]'), '');
    draftLimit = cleaned.isEmpty ? BigInt.zero : BigInt.parse(cleaned);
    notifyListeners();
  }

  @override
  void setLimit(BigInt value) {
    draftLimit = value < BigInt.zero ? BigInt.zero : value;
    notifyListeners();
  }

  @override
  void setCategoryLimit(String categoryId, BigInt limit) {
    final next = [
      for (final line in draftLines)
        if (line.categoryId != categoryId) line,
    ];
    if (limit > BigInt.zero) {
      next.add(BudgetCategoryDraft(categoryId: categoryId, limitMinor: limit));
    }
    draftLines = List.unmodifiable(next);
    notifyListeners();
  }

  @override
  void removeCategory(String categoryId) {
    draftLines = List.unmodifiable([
      for (final line in draftLines)
        if (line.categoryId != categoryId) line,
    ]);
    notifyListeners();
  }

  @override
  void setThresholds(List<int> thresholds) {
    draftThresholds = List.unmodifiable(thresholds);
    notifyListeners();
  }

  @override
  Future<void> load({String? on, BudgetApplyTo? applyTo}) async {
    final epoch = ++_epoch;
    if (on != null) {
      monthOn = on;
      this.applyTo = BudgetApplyTo.month;
    } else if (applyTo == BudgetApplyTo.defaultTemplate) {
      this.applyTo = BudgetApplyTo.defaultTemplate;
    } else if (applyTo == BudgetApplyTo.month) {
      this.applyTo = BudgetApplyTo.month;
    }
    // Initial open (no on / applyTo): edit the every-month template.
    final queryApplyTo = this.applyTo == BudgetApplyTo.defaultTemplate
        ? BudgetApplyTo.defaultTemplate
        : null;
    final queryOn = this.applyTo == BudgetApplyTo.month
        ? (on ?? monthOn ?? period?.from)
        : null;
    busy = true;
    failure = null;
    notifyListeners();
    final catalog = await _categories.load();
    final current = await _cases.current(on: queryOn, applyTo: queryApplyTo);
    if (epoch != _epoch) return;
    catalog.fold((error) => failure = error, (manage) {
      expenseCategories = List.unmodifiable([
        for (final category in manage.all)
          if (!category.archived && category.kind.fits(false)) category,
      ]);
    });
    current.fold((error) => failure = error, (value) {
      period = value.period;
      if (monthOn == null && value.period.from.isNotEmpty) {
        monthOn = value.period.from;
      }
      _applyDraft(value.budget);
      loaded = true;
    });
    busy = false;
    notifyListeners();
  }

  @override
  Future<bool> save() async {
    if (draftLimit <= BigInt.zero) {
      failure = const AuthFailure(AuthError.invalidInput);
      notifyListeners();
      return false;
    }
    final savingMonth = applyTo == BudgetApplyTo.month;
    final anchor = monthOn ?? period?.from;
    if (savingMonth && anchor == null) {
      failure = const AuthFailure(AuthError.invalidInput);
      notifyListeners();
      return false;
    }
    // Version only when updating the same kind of row that is loaded.
    final int? version;
    if (summary == null) {
      version = null;
    } else if (savingMonth && summary!.isOverride) {
      version = summary!.version;
    } else if (!savingMonth && !summary!.isOverride) {
      version = summary!.version;
    } else {
      version = null; // create month override from inherited default, etc.
    }
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.put(
      BudgetDraft(
        limitMinor: draftLimit,
        alertThresholds: draftThresholds,
        categories: draftLines,
        applyTo: applyTo,
        on: savingMonth ? anchor : null,
        version: version,
      ),
    );
    final ok = result.fold((error) {
      failure = error;
      return false;
    }, (saved) {
      period = saved.period;
      if (savingMonth) monthOn = saved.period.from;
      _applyDraft(saved);
      return true;
    });
    if (ok && !savingMonth) await _clearDraftPreference();
    busy = false;
    notifyListeners();
    return ok;
  }

  @override
  Future<bool> clear() async {
    busy = true;
    failure = null;
    notifyListeners();
    if (applyTo == BudgetApplyTo.month) {
      if (summary?.isOverride != true) {
        busy = false;
        notifyListeners();
        return true;
      }
      final anchor = monthOn ?? period?.from;
      final result = await _cases.delete(
        applyTo: BudgetApplyTo.month,
        on: anchor,
        version: summary!.version,
      );
      final ok = await result.fold((error) async {
        failure = error;
        return false;
      }, (_) async {
        await load(on: anchor, applyTo: BudgetApplyTo.month);
        return true;
      });
      busy = false;
      notifyListeners();
      return ok;
    }

    final version = summary?.version;
    final result = await _cases.delete(
      applyTo: BudgetApplyTo.defaultTemplate,
      version: version,
    );
    final ok = await result.fold((error) async {
      failure = error;
      return false;
    }, (_) async {
      await load(applyTo: BudgetApplyTo.defaultTemplate);
      return true;
    });
    busy = false;
    notifyListeners();
    return ok;
  }

  Future<void> _clearDraftPreference() async {
    final loadedPrefs = await _settings.load();
    await loadedPrefs.fold((_) async {}, (prefs) async {
      if (prefs.budgetDraftMinor == null) return;
      await _settings.save(prefs.copyWith(budgetDraftMinor: null));
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
