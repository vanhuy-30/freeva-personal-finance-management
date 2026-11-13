import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/notifications/data/notification_repository_impl.dart';
import 'package:mobile/features/notifications/domain/notification_models.dart';
import 'package:mobile/features/notifications/domain/push_registrar.dart';

class _Api implements AuthorizedApi {
  final calls = <({String method, String path, Map<String, dynamic>? body})>[];
  Map<String, dynamic> answer = {};

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method: method, path: path, body: body));
    return right(answer);
  }
}

Map<String, dynamic> _toggle(String kind, {bool enabled = false}) => {
  'kind': kind,
  'enabled': enabled,
  'available': true,
  'managedLocally': kind == 'security',
};

Map<String, dynamic> _prefs() => {
  'kinds': [
    _toggle('budget', enabled: true),
    _toggle('daily_log', enabled: true),
    _toggle('some_future_kind'),
  ],
  'dailyLogTime': '21:30',
  'quietHoursEnabled': false,
  'quietStart': '22:00',
  'quietEnd': '07:00',
  'version': 3,
  'updatedAt': '2026-11-04T00:00:00.000Z',
};

Map<String, dynamic> _item(String id, String kind, String key) => {
  'id': id,
  'kind': kind,
  'titleKey': key,
  'bodyKey': '${key}_body',
  'params': <String, dynamic>{},
  'createdAt': '2026-11-04T13:00:00.000Z',
  'readAt': null,
};

void main() {
  test('reads daily_log toggle and time; skips unknown kinds', () async {
    final api = _Api()..answer = _prefs();
    final prefs = (await NotificationRepositoryImpl(
      api,
    ).preferences()).getOrElse(() => throw StateError('failed'));
    expect(prefs.dailyLogTime, '21:30');
    expect(prefs.toggle(NotificationKind.dailyLog)?.enabled, isTrue);
    expect(prefs.kinds, hasLength(2));
  });

  test('sends dailyLogEnabled and dailyLogTime with the version', () async {
    final api = _Api()..answer = _prefs();
    await NotificationRepositoryImpl(api).putPreferences(
      const NotificationPreferencesPatch(
        dailyLogEnabled: true,
        dailyLogTime: '20:15',
        version: 3,
      ),
    );
    expect(api.calls.single.method, 'PUT');
    expect(api.calls.single.body, {
      'dailyLogEnabled': true,
      'dailyLogTime': '20:15',
      'version': 3,
    });
  });

  test(
    'inbox keeps daily_log and drops kinds this build does not know',
    () async {
      final api = _Api()
        ..answer = {
          'items': [
            _item('a', 'daily_log', 'daily_log'),
            _item('b', 'some_future_kind', 'x'),
            _item('c', 'budget', 'budget_threshold'),
          ],
        };
      final items = (await NotificationRepositoryImpl(
        api,
      ).list()).getOrElse(() => throw StateError('failed'));
      expect(items.map((i) => i.id), ['a', 'c']);
      expect(items.first.kind, NotificationKind.dailyLog);
    },
  );

  test('wheel snaps the saved time to 15-minute steps', () {
    expect(snapDailyLogTime('20:00', step: 15, fallback: '20:00'), (20, 0));
    expect(snapDailyLogTime('20:07', step: 15, fallback: '20:00'), (20, 0));
    expect(snapDailyLogTime('20:08', step: 15, fallback: '20:00'), (20, 15));
    expect(snapDailyLogTime('23:53', step: 15, fallback: '20:00'), (0, 0));
    expect(snapDailyLogTime('bad', step: 15, fallback: '20:00'), (20, 0));
    expect(formatHm(7, 5), '07:05');
  });

  test('tapping a daily_log push opens Ghi chi; others just open the app', () {
    expect(routeForOpenedKind('daily_log'), '/record?type=expense');
    expect(routeForOpenedKind('budget'), isNull);
  });
}
