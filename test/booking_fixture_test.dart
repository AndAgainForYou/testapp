import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:testt/booking/data/booking_schedule_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Фікстура assets/booking_schedule.json збігається з ТЗ і проходить парсер + валідацію', () async {
    final raw = await rootBundle.loadString('assets/booking_schedule.json');
    final data = BookingScheduleParser.parse(raw);

    expect(data.workingHours.start, '10:00');
    expect(data.workingHours.end, '20:00');
    expect(data.workingHours.breaks.single.label, 'Обід');
    expect(data.bufferMinutes, 15);
    expect(data.services.map((s) => s.id).toList(), ['s1', 's2', 's3', 's4']);

    expect(data.appointments.map((a) => a.date).toSet(), {
      '2026-04-28',
      '2026-04-29',
      '2026-04-30',
    });
    expect(data.appointments.length, 5);
  });
}
