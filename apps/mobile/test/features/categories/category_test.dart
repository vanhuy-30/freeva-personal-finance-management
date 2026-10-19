import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/data/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/category_rules.dart';
import 'package:mobile/features/categories/domain/category_use_cases.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/categories/presentation/viewmodels/category_view_model.dart';

import '../auth/fakes.dart';

Map<String, dynamic> categoryJson(
  String id, {
  String name = 'Food',
  String? parentId,
  bool archived = false,
  bool system = false,
  int version = 1,
  String createdAt = '2026-10-01T00:00:00Z',
}) => {
  'id': id,
  'clientId': '11111111-1111-4111-8111-111111111111',
  'name': name,
  'parentId': parentId,
  'colorToken': 'color.brand.primary',
  'iconToken': 'food',
  'groupId': null,
  'isSystem': system,
  'archivedAt': archived ? '2026-10-01T00:00:00Z' : null,
  'version': version,
  'createdAt': createdAt,
  'updatedAt': '2026-10-08T00:00:00Z',
};

class CategoryTransport implements AuthorizedApi {
  final calls = <({String method, String path, Map<String, dynamic>? body})>[];
  final rows = [
    categoryJson(
      'food',
      name: 'Ăn uống',
      system: true,
      createdAt: '2026-10-01T00:00:00Z',
    ),
    categoryJson(
      'coffee',
      name: 'Cà phê',
      parentId: 'food',
      createdAt: '2026-10-02T00:00:00Z',
    ),
    categoryJson(
      'gift',
      name: 'Quà',
      archived: true,
      createdAt: '2026-10-03T00:00:00Z',
    ),
  ];
  AuthFailure? failure;
  int writes = 0;
  Completer<void>? pending;
  bool paginate = false;
  bool requireReplacement = false;

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method: method, path: path, body: body));
    if (pending != null) await pending!.future;
    if (failure != null) return left(failure!);
    if (path == 'categories/defaults') return right({});
    if (path == 'categories/options') {
      return right({
        'colorTokens': ['color.brand.primary', 'color.semantic.success'],
        'iconTokens': ['food', 'category'],
      });
    }
    if (path == 'categories/recent') return right({'items': <Object>[]});
    if (method == 'GET' && path.startsWith('categories?')) {
      final page = int.parse(Uri.parse(path).queryParameters['page']!);
      return right({
        'items': paginate
            ? [Map<String, dynamic>.from(rows[page - 1])]
            : rows.map(Map<String, dynamic>.from).toList(),
        'total': rows.length,
      });
    }
    final mutation =
        method == 'DELETE' ||
        method == 'PATCH' ||
        (method == 'POST' && path == 'categories');
    if (!mutation) return left(const AuthFailure(AuthError.unavailable));
    writes++;
    if (method == 'POST') {
      final created = {
        ...categoryJson('tea', name: body!['name'] as String),
        ...body,
        'id': 'tea',
        'isSystem': false,
        'archivedAt': null,
        'version': 1,
      };
      rows.add(created);
      return right(created);
    }
    final uri = Uri.parse(path);
    final id = uri.pathSegments.last;
    final row = rows.firstWhere((item) => item['id'] == id);
    if (method == 'DELETE') {
      final version = int.parse(uri.queryParameters['version']!);
      final replacement = uri.queryParameters['replacementCategoryId'];
      if (row['version'] != version ||
          (requireReplacement && replacement == null)) {
        return left(const AuthFailure(AuthError.conflict));
      }
      rows.remove(row);
      return right({});
    }
    if (row['version'] != body!['version']) {
      return left(const AuthFailure(AuthError.conflict));
    }
    row.addAll(body);
    row['version'] = (row['version'] as int) + 1;
    if (body.containsKey('archived')) {
      row['archivedAt'] = body['archived'] == true
          ? '2026-10-08T00:00:00Z'
          : null;
    }
    return right(Map<String, dynamic>.from(row));
  }
}

const options = CategoryOptions(
  colorTokens: ['color.brand.primary', 'color.semantic.success'],
  iconTokens: ['food', 'category'],
);

void main() {
  test('rules reject cycles and order the tree by creation', () {
    final food = FinanceCategory(
      id: 'food',
      name: 'Ăn uống',
      parentId: null,
      createdAt: DateTime.utc(2026, 10, 2),
    );
    final coffee = FinanceCategory(
      id: 'coffee',
      name: 'Cà phê',
      parentId: 'food',
      createdAt: DateTime.utc(2026, 10, 1),
    );
    final rows = orderedCategories([coffee, food]);
    expect(rows.map((row) => row.category.id), ['food', 'coffee']);
    expect(rows.last.depth, 1);
    expect(categoryParentInvalid('coffee', 'food', [food, coffee]), isTrue);
    expect(categoryParentInvalid('food', 'coffee', [food, coffee]), isFalse);
    expect(categoryHasActiveChild(food, [food, coffee]), isTrue);
  });

  test(
    'repository pages every status, patches version and deletes by query',
    () async {
      final api = CategoryTransport()..paginate = true;
      final repo = CategoryRepositoryImpl(api);
      final managed = (await repo.manage()).getOrElse(
        () => throw StateError('x'),
      );
      expect(managed.items.map((item) => item.id), ['food', 'coffee', 'gift']);
      expect(managed.options.iconTokens, ['food', 'category']);
      expect(
        api.calls
            .where((call) => call.path.startsWith('categories?'))
            .map((call) => Uri.parse(call.path).queryParameters['status']),
        everyElement('all'),
      );
      final coffee = managed.items[1];
      final cleared = (await repo.save(
        CategoryDraft(name: coffee.name),
        category: coffee,
        clientId: 'unused',
      )).getOrElse(() => throw StateError('x'));
      expect(api.calls.last.body!['version'], 1);
      expect(api.calls.last.body!.containsKey('parentId'), isTrue);
      expect(cleared.parentId, isNull);
      expect(cleared.version, 2);
      expect(api.calls.last.body!.containsKey('clientId'), isFalse);
      expect(
        (await repo.delete(cleared, replacementCategoryId: 'food')).isRight(),
        isTrue,
      );
      expect(api.calls.last.path, contains('version=2'));
      expect(api.calls.last.path, contains('replacementCategoryId=food'));
      await repo.save(
        const CategoryDraft(name: 'Trà'),
        clientId: 'same-client',
      );
      expect(api.calls.last.path, 'categories');
      expect(api.calls.last.body!['clientId'], 'same-client');
      expect(api.calls.last.body!.containsKey('version'), isFalse);
      api.rows[0]['name'] = 1;
      expect((await repo.manage()).isLeft(), isTrue);
    },
  );

  test('use case blocks invalid names, tokens, cycles, children and stale versions', () async {
    final api = CategoryTransport();
    final cases = DefaultCategoryUseCases(CategoryRepositoryImpl(api));
    final managed = (await cases.manage()).getOrElse(
      () => throw StateError('x'),
    );
    final items = managed.items;
    final food = items.first;
    final coffee = items[1];
    for (final draft in [
      const CategoryDraft(name: ' '),
      const CategoryDraft(name: 'ok', colorToken: 'color.brand.highlight'),
      CategoryDraft(name: 'ok', parentId: coffee.id),
    ]) {
      expect(
        (await cases.save(
          draft,
          items,
          options,
          category: food,
          clientId: 'id',
        )).isLeft(),
        isTrue,
      );
    }
    expect((await cases.update(food, items, archived: true)).isLeft(), isTrue);
    expect((await cases.delete(food, items)).isLeft(), isTrue);
    expect(
      (await cases.delete(coffee.copyWithVersion(2147483647), items)).isLeft(),
      isTrue,
    );
    expect(api.writes, 0);
    expect(
      (await cases.delete(
        coffee,
        items,
        replacementCategoryId: food.id,
      )).isRight(),
      isTrue,
    );
  });

  group('view model', () {
    late CategoryTransport api;
    late DefaultAuthViewModel auth;
    late DefaultCategoryViewModel model;
    setUp(() async {
      api = CategoryTransport();
      auth = DefaultAuthViewModel(
        DefaultAuthUseCases(
          AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
        ),
      )..stage = AuthStage.unlocked;
      model = DefaultCategoryViewModel(
        DefaultCategoryUseCases(CategoryRepositoryImpl(api)),
        auth,
      );
      await model.load();
    });
    tearDown(() {
      model.dispose();
      auth.dispose();
    });

    test(
      'creation retries keep clientId and conflict requires reload',
      () async {
        final id = model.newClientId();
        expect(
          id,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        const draft = CategoryDraft(name: 'Trà', iconToken: 'category');
        api.failure = const AuthFailure(AuthError.network);
        expect(await model.save(draft, id), isFalse);
        api.failure = null;
        expect(await model.save(draft, id), isTrue);
        final creates = api.calls.where(
          (call) => call.method == 'POST' && call.path == 'categories',
        );
        expect(creates.map((call) => call.body!['clientId']), [id, id]);
        api.failure = const AuthFailure(AuthError.conflict);
        await model.save(draft, id, category: model.categories.first);
        expect(model.needsReload, isTrue);
        expect(await model.archive(model.categories.first), isFalse);
      },
    );

    test(
      'delete without replacement reloads; replacement removes the row',
      () async {
        api.requireReplacement = true;
        final coffee = model.categories.firstWhere(
          (item) => item.id == 'coffee',
        );
        expect(await model.remove(coffee), isFalse);
        expect(model.needsReload, isTrue);
        await model.load();
        final again = model.categories.firstWhere(
          (item) => item.id == 'coffee',
        );
        expect(
          await model.remove(again, replacementCategoryId: 'food'),
          isTrue,
        );
        expect(
          model.categories.map((item) => item.id),
          isNot(contains('coffee')),
        );
      },
    );

    test('lock clears categories and discards a late response', () async {
      api.pending = Completer<void>();
      final work = model.archive(
        model.categories.firstWhere((item) => item.id == 'coffee'),
      );
      auth.lock();
      expect(model.categories, isEmpty);
      expect(model.options.isReady, isFalse);
      api.pending!.complete();
      await work;
      expect(model.categories, isEmpty);
      expect(model.busy, isFalse);
    });

    test('expired session clears categories', () async {
      api.failure = const AuthFailure(AuthError.expired);
      await model.load();
      expect(model.categories, isEmpty);
      expect(auth.stage, AuthStage.signedOut);
    });
  });
}

extension on FinanceCategory {
  FinanceCategory copyWithVersion(int value) => FinanceCategory(
    id: this.id,
    name: name,
    parentId: parentId,
    clientId: clientId,
    colorToken: colorToken,
    iconToken: iconToken,
    isSystem: isSystem,
    archived: archived,
    version: value,
    createdAt: createdAt,
  );
}
