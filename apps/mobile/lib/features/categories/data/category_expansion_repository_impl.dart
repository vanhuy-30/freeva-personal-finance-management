import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../core/storage/secure_storage_factory.dart';
import '../domain/category_expansion_repository.dart';

@LazySingleton(as: CategoryExpansionRepository)
class CategoryExpansionRepositoryImpl implements CategoryExpansionRepository {
  CategoryExpansionRepositoryImpl() : _storage = createFreevaSecureStorage();

  static const storageKey = 'freeva.categories.expanded.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<Set<String>> read() async {
    try {
      final raw = await _storage.read(key: storageKey);
      if (raw == null) return {};
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> write(Set<String> ids) async {
    try {
      await _storage.write(key: storageKey, value: jsonEncode(ids.toList()));
    } catch (_) {
      // Only a convenience; the list opens collapsed next time.
    }
  }
}
