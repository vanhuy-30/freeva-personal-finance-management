import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/tag.dart';
import '../../domain/tag_use_cases.dart';

/// Nhãn screen: the user's tags with their transaction counts, plus create,
/// rename and delete. Every write returns whether it worked; the reason is in
/// [failure].
class TagManageViewModel extends ChangeNotifier {
  TagManageViewModel(this._cases, this._auth);

  final TagUseCases _cases;
  final AuthViewModel _auth;
  List<Tag> tags = const [];
  bool loading = false;
  bool loaded = false;
  AuthFailure? failure;
  String query = '';
  bool _disposed = false;

  /// Tags matching the search box, in the order the server gave.
  List<Tag> get shown {
    final needle = query.trim().toLowerCase();
    return needle.isEmpty
        ? tags
        : [
            for (final tag in tags)
              if (tag.name.toLowerCase().contains(needle)) tag,
          ];
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> load() async {
    if (loading) return;
    loading = true;
    failure = null;
    notifyListeners();
    final result = await _cases.list();
    result.fold(_fail, (value) {
      tags = value;
      loaded = true;
    });
    loading = false;
    _notify();
  }

  Future<bool> create(String name) async {
    final result = await _cases.create(clientId: _clientId(), name: name);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (tag) {
        failure = null;
        tags = [...tags, tag];
        _notify();
        return true;
      },
    );
  }

  Future<bool> rename(Tag tag, String name) async {
    final result = await _cases.rename(tag, name);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (saved) {
        failure = null;
        tags = [
          for (final item in tags)
            item.id == tag.id ? tag.renamed(saved.name, saved.version) : item,
        ];
        _notify();
        return true;
      },
    );
  }

  Future<bool> delete(Tag tag) async {
    final result = await _cases.delete(tag);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (_) {
        failure = null;
        tags = [
          for (final item in tags)
            if (item.id != tag.id) item,
        ];
        _notify();
        return true;
      },
    );
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _clientId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
