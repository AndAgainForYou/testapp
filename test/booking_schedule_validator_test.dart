import 'package:flutter_test/flutter_test.dart';

import 'package:testt/booking/data/booking_schedule_load_exception.dart';
import 'package:testt/booking/data/booking_schedule_validator.dart';

void main() {
  group('BookingScheduleValidator', () {
    test('дубль id послуги', () {
      expect(
        () => BookingScheduleValidator.validateRoot({
          'workingHours': {
            'start': '10:00',
            'end': '20:00',
            'breaks': <dynamic>[],
          },
          'bufferMinutes': 15,
          'services': [
            {'id': 's1', 'name': 'A', 'durationMinutes': 30},
            {'id': 's1', 'name': 'B', 'durationMinutes': 60},
          ],
          'appointments': <dynamic>[],
        }),
        throwsA(
          predicate((Object e) =>
              e is BookingScheduleLoadException && e.userMessage.contains('Дубльований')),
        ),
      );
    });

    test('початок робочого дня не раніше за кінець', () {
      expect(
        () => BookingScheduleValidator.validateRoot({
          'workingHours': {
            'start': '20:00',
            'end': '10:00',
            'breaks': <dynamic>[],
          },
          'bufferMinutes': 15,
          'services': [
            {'id': 's1', 'name': 'A', 'durationMinutes': 30},
          ],
          'appointments': <dynamic>[],
        }),
        throwsA(
          predicate((Object e) =>
              e is BookingScheduleLoadException &&
              e.userMessage.contains('Робочий день')),
        ),
      );
    });
  });
}
