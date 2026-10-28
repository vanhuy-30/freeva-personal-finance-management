import 'package:flutter/material.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/categories/presentation/viewmodels/category_view_model.dart';

import '../auth/fakes.dart';

FinanceCategory _cat(
  String id,
  String name, {
  String? parent,
  String? color,
  String? icon,
  CategoryKind kind = CategoryKind.expense,
  bool archived = false,
  required int order,
}) => FinanceCategory(
  id: id,
  name: name,
  parentId: parent,
  colorToken: color,
  iconToken: icon,
  kind: kind,
  archived: archived,
  createdAt: DateTime.utc(2026, 10, 1).add(Duration(minutes: order)),
);

/// Categories like the E artboards.
List<FinanceCategory> canvasCategories() => [
  _cat('food', 'Ăn uống', color: 'color.brand.primary', icon: 'food', order: 1),
  _cat(
    'snack',
    'Ăn vặt',
    parent: 'food',
    color: 'color.brand.accent',
    icon: 'food',
    order: 2,
  ),
  _cat(
    'market',
    'Đi chợ',
    parent: 'food',
    color: 'color.semantic.success',
    order: 3,
  ),
  _cat(
    'bills',
    'Hóa đơn',
    color: 'color.semantic.warning',
    icon: 'electricity',
    order: 4,
  ),
  _cat('power', 'Điện nước', parent: 'bills', order: 5),
  _cat('net', 'Internet', parent: 'bills', order: 6),
  _cat('phone', 'Điện thoại', parent: 'bills', order: 7),
  _cat(
    'move',
    'Đi lại',
    color: 'color.category.oceanDeep',
    icon: 'transport',
    order: 8,
  ),
  _cat(
    'home',
    'Nhà ở',
    color: 'color.category.violetDeep',
    icon: 'housing',
    order: 9,
  ),
  _cat(
    'shop',
    'Mua sắm',
    color: 'color.semantic.success',
    icon: 'shopping',
    order: 10,
  ),
  _cat('health', 'Sức khỏe', icon: 'health', order: 11),
  _cat(
    'salary',
    'Lương',
    color: 'color.semantic.success',
    icon: 'salary',
    kind: CategoryKind.income,
    order: 12,
  ),
  _cat(
    'bonus',
    'Thưởng',
    color: 'color.category.yellowLight',
    icon: 'bonus',
    kind: CategoryKind.income,
    order: 13,
  ),
  _cat(
    'gift',
    'Quà tặng',
    color: 'color.category.orange',
    icon: 'gifts',
    kind: CategoryKind.both,
    order: 14,
  ),
  _cat('school', 'Giáo dục', icon: 'education', archived: true, order: 15),
  _cat('trip', 'Du lịch', icon: 'travel', archived: true, order: 16),
  _cat('hotel', 'Khách sạn', parent: 'trip', archived: true, order: 17),
  _cat('ticket', 'Vé máy bay', parent: 'trip', archived: true, order: 18),
];

class StubCategoryViewModel extends ChangeNotifier
    implements CategoryViewModel {
  StubCategoryViewModel({List<FinanceCategory>? categories, Set<String>? open})
    : categories = categories ?? canvasCategories(),
      expanded = open ?? const {};

  @override
  List<FinanceCategory> categories;
  @override
  CategoryOptions options = const CategoryOptions(
    colorTokens: [
      'color.brand.primary',
      'color.category.blueDeep',
      'color.brand.secondary',
      'color.category.oceanDeep',
      'color.brand.accent',
      'color.category.violetDeep',
      'color.semantic.success',
      'color.semantic.warning',
      'color.category.blueLight',
      'color.brand.highlight',
      'color.category.violetLight',
      'color.category.greenLight',
      'color.category.yellowLight',
      'color.category.pink',
      'color.category.orange',
      'color.category.brown',
      'color.category.lime',
      'color.category.olive',
      'color.category.plum',
      'color.category.gray',
    ],
    iconTokens: ['food'],
  );
  @override
  bool busy = false;
  @override
  bool needsReload = false;
  @override
  AuthFailure? failure;
  @override
  Set<String> expanded;
  final restored = <String>[];

  @override
  String newClientId() => 'client';
  @override
  Future<void> load() async {}
  @override
  Future<bool> save(
    CategoryDraft draft,
    String clientId, {
    FinanceCategory? category,
  }) async => true;
  @override
  Future<bool> archive(FinanceCategory category) async => true;
  int usageCount = 12;
  @override
  Future<int?> usage(FinanceCategory category) async => usageCount;
  @override
  Future<bool> restore(FinanceCategory category) async {
    restored.add(category.id);
    return true;
  }

  @override
  Future<bool> remove(
    FinanceCategory category, {
    String? replacementCategoryId,
  }) async => true;
  @override
  void toggleExpanded(String id) {
    expanded = expanded.contains(id)
        ? expanded.difference({id})
        : {...expanded, id};
    notifyListeners();
  }

  @override
  void expand(String id) => toggleExpanded(id);
}

Future<Widget> e1App(
  Widget page, {
  StubCategoryViewModel? model,
  bool dark = false,
  double scale = 1,
}) async {
  await getIt.reset();
  getIt.registerSingleton<AuthViewModel>(
    DefaultAuthViewModel(
        DefaultAuthUseCases(
          AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
        ),
      )
      ..stage = AuthStage.unlocked
      ..hasPin = true
      ..ready = true,
  );
  getIt.registerSingleton<CategoryViewModel>(model ?? StubCategoryViewModel());
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: MediaQuery.withClampedTextScaling(
      minScaleFactor: scale,
      maxScaleFactor: scale,
      child: page,
    ),
  );
}
