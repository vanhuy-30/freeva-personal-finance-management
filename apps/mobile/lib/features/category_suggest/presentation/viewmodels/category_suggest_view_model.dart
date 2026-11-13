import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/feature_flags/feature_flag_service.dart';
import '../../../server_config/domain/server_config.dart';
import '../../../transactions/domain/transaction.dart';
import '../../domain/category_suggest_repository.dart';
import '../../domain/category_suggestion.dart';

/// "Xếp vào Cà phê?" under Cửa hàng while recording a new expense or income
/// (MOB-P5-E03, board R.1). One per form. The form pushes its state in with
/// [update]; the server is asked [debounce] after the text stops changing,
/// and only the latest answer counts. Errors and offline hide the card
/// silently.
@injectable
class CategorySuggestViewModel extends ChangeNotifier {
  CategorySuggestViewModel(this._repository, this._flags);

  /// Quiet time after the last keystroke before asking the server.
  static const debounce = Duration(milliseconds: 400);

  /// Shorter text is not worth a guess.
  static const minLength = 2;

  final CategorySuggestRepository _repository;
  final FeatureFlagService _flags;

  Timer? _timer;
  int _seq = 0;
  bool _disposed = false;
  String? _key;
  TransactionType? _type;
  String? _categoryId;
  bool Function(String id) _fits = _any;
  CategorySuggestion? _suggestion;
  String? _usedId;
  CategorySuggestion? _shown;

  static bool _any(String _) => true;

  CategorySuggestion? _visible;

  /// The card to show, or null.
  CategorySuggestion? get visible => _visible;

  /// The last suggestion the user saw on this form; feedback is sent for it.
  CategorySuggestion? get shown => _shown;

  /// Takes the form's current type, merchant, note and category. Text changes
  /// start the debounce; a category change only re-checks the card.
  void update({
    required TransactionType type,
    required String merchant,
    required String note,
    required String? categoryId,
    bool Function(String id)? fits,
  }) {
    _categoryId = categoryId;
    if (fits != null) _fits = fits;
    // A suggestion for expense says nothing about an income.
    if (_type != null && _type != type) _shown = null;
    _type = type;
    final key = _keyFor(type, merchant.trim(), note.trim());
    if (key != _key) {
      _key = key;
      _timer?.cancel();
      _seq++;
      if (key == null) {
        _suggestion = null;
      } else {
        _timer = Timer(
          debounce,
          () => _ask(type, merchant.trim(), note.trim()),
        );
      }
    }
    _refresh();
  }

  /// "Dùng": returns the category to put on the form and hides the card.
  String? use() {
    final s = visible;
    if (s == null) return null;
    _usedId = s.categoryId;
    _refresh();
    return s.categoryId;
  }

  /// After the transaction was saved (or queued offline): tells the server
  /// what the user kept, if a suggestion was shown. Fire and forget.
  void sendFeedback({
    required TransactionType type,
    required String? chosenCategoryId,
    required String merchant,
  }) {
    final s = _shown;
    if (s == null || chosenCategoryId == null) return;
    if (type == TransactionType.transfer) return;
    final name = merchant.trim();
    unawaited(
      _repository
          .feedback(
            SuggestionFeedback(
              merchant: name.isEmpty ? null : name,
              suggestedCategoryId: s.categoryId,
              chosenCategoryId: chosenCategoryId,
              source: s.source,
              surface: SuggestionSurface.entry,
            ),
          )
          .then((_) {}, onError: (Object _) {}),
    );
  }

  /// Null when nothing should be asked: transfer, flag off, text too short.
  /// Merchant wins; the note is used only while the merchant is empty.
  String? _keyFor(TransactionType type, String merchant, String note) {
    if (type != TransactionType.expense && type != TransactionType.income) {
      return null;
    }
    if (!_flags.isEnabled(FeatureFlags.categorySuggest)) return null;
    final text = merchant.isNotEmpty ? merchant : note;
    if (text.length < minLength) return null;
    return '${type.name}\n${merchant.isNotEmpty ? 'm' : 'n'}\n$text';
  }

  Future<void> _ask(TransactionType type, String merchant, String note) async {
    final seq = ++_seq;
    final byMerchant = merchant.isNotEmpty;
    CategorySuggestion? next;
    try {
      final result = await _repository.suggest(
        income: type == TransactionType.income,
        merchant: byMerchant ? merchant : null,
        note: byMerchant ? null : note,
      );
      next = result.fold((_) => null, (value) => value);
    } catch (_) {
      next = null;
    }
    if (_disposed || seq != _seq) return;
    _suggestion = next;
    _usedId = null;
    _refresh();
  }

  void _refresh() {
    final s = _suggestion;
    final next =
        s == null ||
            s.categoryId == _categoryId ||
            s.categoryId == _usedId ||
            !_fits(s.categoryId)
        ? null
        : s;
    if (next != null) _shown = next;
    if (identical(next, _visible)) return;
    _visible = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
