import 'package:flutter_test/flutter_test.dart';

import 'package:testt/booking/data/booking_schedule_load_exception.dart';
import 'package:testt/booking/data/booking_schedule_parser.dart';

void main() {
  group('BookingScheduleParser', () {
    test('невалідний JSON кидає BookingScheduleLoadException', () {
      expect(
        () => BookingScheduleParser.parse('{'),
        throwsA(isA<BookingScheduleLoadException>()),
      );
    });

    test('корінь не об’єкт — помилка', () {
      expect(
        () => BookingScheduleParser.parse('[]'),
        throwsA(isA<BookingScheduleLoadException>()),
      );
    });

    test('бракує ключа — зрозуміле повідомлення', () {
      try {
        BookingScheduleParser.parse('{"bufferMinutes":0,"services":[],"appointments":[]}');
        fail('expected exception');
      } on BookingScheduleLoadException catch (e) {
        expect(e.userMessage, contains('workingHours'));
      }
    });

    test('порожній services — помилка', () {
      expect(
        () => BookingScheduleParser.parse(
          '{"workingHours":{"start":"10:00","end":"20:00","breaks":[]},"bufferMinutes":15,"services":[],"appointments":[]}',
        ),
        throwsA(isA<BookingScheduleLoadException>()),
      );
    });
  });
}
