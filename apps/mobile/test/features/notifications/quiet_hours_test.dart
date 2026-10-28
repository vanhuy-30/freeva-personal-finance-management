import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/domain/notification_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('isInQuietHours', () {
    test('overnight Asia/Ho_Chi_Minh window', () {
      // 22:30 ICT
      final late = DateTime.parse('2026-10-28T15:30:00.000Z');
      expect(
        isInQuietHours(
          enabled: true,
          quietStart: '22:00',
          quietEnd: '07:00',
          timeZone: 'Asia/Ho_Chi_Minh',
          now: late,
        ),
        isTrue,
      );

      // 07:00 ICT — exclusive end
      final seven = DateTime.parse('2026-10-28T00:00:00.000Z');
      expect(
        isInQuietHours(
          enabled: true,
          quietStart: '22:00',
          quietEnd: '07:00',
          timeZone: 'Asia/Ho_Chi_Minh',
          now: seven,
        ),
        isFalse,
      );

      // 12:00 ICT
      final noon = DateTime.parse('2026-10-28T05:00:00.000Z');
      expect(
        isInQuietHours(
          enabled: true,
          quietStart: '22:00',
          quietEnd: '07:00',
          timeZone: 'Asia/Ho_Chi_Minh',
          now: noon,
        ),
        isFalse,
      );
    });

    test('disabled quiet hours never suppress', () {
      final late = DateTime.parse('2026-10-28T15:30:00.000Z');
      expect(
        isInQuietHours(
          enabled: false,
          quietStart: '22:00',
          quietEnd: '07:00',
          timeZone: 'Asia/Ho_Chi_Minh',
          now: late,
        ),
        isFalse,
      );
    });
  });
}
