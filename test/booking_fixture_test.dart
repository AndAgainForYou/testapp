import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:testt/booking/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Фікстура assets/booking_schedule.json збігається з ТЗ і парситься', () async {
    final raw = await rootBundle.loadString('assets/booking_schedule.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    final data = BookingScheduleData.fromJson(map);

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
