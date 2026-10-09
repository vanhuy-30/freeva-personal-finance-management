import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_status_banner.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

void main() {
  late _FixedSync model;

  setUp(() async {
    await getIt.reset();
    model = _FixedSync([
      _item('pending'),
      _item('conflict', status: SyncItemStatus.conflict, review: true),
    ]);
    getIt.registerSingleton<SyncViewModel>(model);
  });

  tearDown(() => getIt.reset());

  testWidgets('shows pending and conflict state in Vietnamese and English', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const SyncStatusBanner()));
    expect(find.text('1 thay đổi chờ đồng bộ'), findsOneWidget);
    expect(find.text('Chi · 2026-01-15'), findsNWidgets(2));
    expect(find.text('Đồng bộ'), findsOneWidget);
    expect(find.text('Số tiền khác bản đã lưu. Không ghi đè.'), findsOneWidget);

    await tester.pumpWidget(_app(const SyncStatusBanner(), locale: 'en'));
    expect(find.text('1 changes waiting to sync'), findsOneWidget);
    expect(find.text('Expense · 2026-01-15'), findsNWidgets(2));
    expect(
      find.text('The amount differs from the saved copy. Not overwritten.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Discard'));
    await tester.pump();
    expect(
      find.text('The amount differs from the saved copy. Not overwritten.'),
      findsNothing,
    );
    expect(model.items.single.opId, 'pending');
  });
}

Widget _app(Widget child, {String locale = 'vi'}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: Locale(locale),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

class _FixedSync extends SyncViewModel {
  _FixedSync(this.items);

  @override
  List<SyncQueueItem> items;
  @override
  bool syncing = false;
  @override
  bool schemaMismatch = false;
  @override
  bool duplicateHint = false;
  @override
  int appliedEpoch = 0;

  @override
  Future<void> acknowledge({String? clientId, String? serverId}) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> discard(String opId) async {
    items = items.where((item) => item.opId != opId).toList();
    notifyListeners();
  }

  @override
  Future<void> enqueue(SyncMutation mutation) async {}

  @override
  Future<void> flush() async {}

  @override
  void onResume() {}
}

SyncQueueItem _item(
  String opId, {
  SyncItemStatus status = SyncItemStatus.pending,
  bool review = false,
}) {
  return SyncQueueItem(
    opId: opId,
    clientId: '11111111-1111-4111-8111-111111111111',
    action: SyncAction.create,
    type: TransactionType.expense,
    occurredOn: '2026-01-15',
    createdAt: DateTime.utc(2026, 1, 15),
    retryCount: 0,
    status: status,
    review: review,
  );
}
