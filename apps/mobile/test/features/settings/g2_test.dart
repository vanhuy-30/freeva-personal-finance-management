import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/feedback/domain/feedback.dart';
import 'package:mobile/features/feedback/presentation/pages/feedback_page.dart';
import 'package:mobile/features/feedback/presentation/viewmodels/feedback_view_model.dart';
import 'package:mobile/features/settings/presentation/pages/faq_page.dart';
import 'package:mobile/features/settings/presentation/pages/notification_settings_page.dart';
import 'package:mobile/features/tags/domain/tag.dart';
import 'package:mobile/features/tags/domain/tag_use_cases.dart';
import 'package:mobile/features/tags/presentation/pages/tag_page.dart';
import 'package:mobile/features/tags/presentation/viewmodels/tag_manage_view_model.dart';
import 'package:mobile/features/transactions/domain/transaction_filter.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';

import '../transactions/c1_stub.dart' show StubTransactionViewModel;
import 'g1_harness.dart';

class FakeTags implements TagUseCases {
  final tags = [
    const Tag(
      id: 'a',
      clientId: 'ca',
      name: 'Ăn trưa',
      version: 1,
      transactionCount: 24,
    ),
    const Tag(
      id: 'b',
      clientId: 'cb',
      name: 'Du lịch',
      version: 1,
      transactionCount: 9,
    ),
  ];
  AuthFailure? failure;

  Either<AuthFailure, T> _r<T>(T value) =>
      failure == null ? right(value) : left(failure!);

  @override
  Future<Either<AuthFailure, List<Tag>>> list() async => _r(List.of(tags));

  @override
  Future<Either<AuthFailure, Tag>> create({
    required String clientId,
    required String name,
  }) async => _r(Tag(id: 'n', clientId: clientId, name: name, version: 1));

  @override
  Future<Either<AuthFailure, Tag>> rename(Tag tag, String name) async => _r(
    Tag(
      id: tag.id,
      clientId: tag.clientId,
      name: name,
      version: tag.version + 1,
    ),
  );

  @override
  Future<Either<AuthFailure, Unit>> delete(Tag tag) async => _r(unit);
}

class FakeFeedback implements FeedbackUseCases {
  FeedbackDraft? sent;
  AuthFailure? failure;

  @override
  Future<Either<AuthFailure, Unit>> send(
    FeedbackDraft draft,
    String version,
  ) async {
    if (failure != null) return left(failure!);
    sent = draft;
    return right(unit);
  }
}

void main() {
  late G1 g;
  late FakeTags tags;
  late FakeFeedback feedback;

  setUp(() async {
    g = await G1.create();
    tags = FakeTags();
    feedback = FakeFeedback();
    getIt
      ..registerSingleton<TagUseCases>(tags)
      ..registerSingleton<FeedbackUseCases>(feedback);
  });
  tearDown(() async {
    g.dispose();
    await getIt.reset();
  });

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  test('tag list searches, creates, renames and deletes in place', () async {
    final model = TagManageViewModel(tags, g.auth);
    await model.load();
    model.search('lịch');
    expect(model.shown.map((t) => t.name), ['Du lịch']);
    model.search('');
    expect(await model.create('Công ty'), isTrue);
    expect(await model.rename(model.tags.first, 'Bữa trưa'), isTrue);
    expect(model.tags.first.name, 'Bữa trưa');
    expect(
      model.tags.first.transactionCount,
      24,
      reason: 'a rename keeps the count',
    );
    expect(await model.delete(model.tags.last), isTrue);
    expect(model.tags.map((t) => t.name), ['Bữa trưa', 'Du lịch']);
    tags.failure = const AuthFailure(AuthError.conflict);
    expect(await model.delete(model.tags.first), isFalse);
    expect(model.tags, hasLength(2));
    model.dispose();
  });

  testWidgets('Nhãn lists counts and opens the filtered transactions', (
    tester,
  ) async {
    tall(tester);
    final transactions = StubTransactionViewModel();
    getIt.registerSingleton<TransactionViewModel>(transactions);
    await tester.pumpWidget(g.app(const TagPage(), routes: []));
    await tester.pumpAndSettle();
    expect(find.text('Ăn trưa'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'du');
    await tester.pump();
    expect(find.text('Ăn trưa'), findsNothing);
    await tester.tap(find.text('Du lịch'));
    await tester.pumpAndSettle();
    expect(transactions.filter.tagIds, {'b'});
    expect(transactions.filter.period, PeriodPreset.allTime);
  });

  testWidgets('Góp ý sends the draft and then says thanks', (tester) async {
    tall(tester);
    await tester.pumpWidget(g.app(const FeedbackPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi góp ý'));
    await tester.pump();
    expect(feedback.sent, isNull, reason: 'empty message cannot be sent');
    await tester.tap(find.text('Lỗi'));
    await tester.tap(find.text('Báo cáo'));
    await tester.enterText(find.byType(TextField), '  Số sai  ');
    await tester.pump();
    expect(find.text('10/2000'), findsOneWidget);
    await tester.tap(find.text('Gửi góp ý'));
    await tester.pumpAndSettle();
    expect(feedback.sent?.kind, FeedbackKind.bug);
    expect(feedback.sent?.topic, FeedbackTopic.reports);
    expect(find.text('Cảm ơn bạn!'), findsOneWidget);
    expect(find.text('Freeva sẽ đọc và trả lời qua email.'), findsOneWidget);
  });

  test(
    'a failed send keeps the form and an expired session signs out',
    () async {
      final model = FeedbackViewModel(feedback, g.auth)..edit(message: 'hi');
      feedback.failure = const AuthFailure(AuthError.network);
      await model.send();
      expect(model.sent, isFalse);
      expect(model.failure?.code, AuthError.network);
      feedback.failure = const AuthFailure(AuthError.expired);
      await model.send();
      expect(g.auth.stage, AuthStage.signedOut);
      model.dispose();
    },
  );

  testWidgets('FAQ search narrows the questions', (tester) async {
    tall(tester);
    await tester.pumpWidget(g.app(const FaqPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.text('Không có câu hỏi khớp'), findsOneWidget);
  });

  testWidgets('Thông báo: only new-device alerts has a switch', (tester) async {
    tall(tester);
    await tester.pumpWidget(g.app(const NotificationSettingsPage()));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Sắp có'), findsNWidgets(4));
    final before = g.settings.sessionAlertsEnabled;
    await tester.tap(find.text('Máy mới đăng nhập'));
    await tester.pumpAndSettle();
    expect(g.settings.sessionAlertsEnabled, !before);
  });
}
