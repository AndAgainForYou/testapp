import 'package:flutter_test/flutter_test.dart';
import 'package:testt/booking/models.dart';
import 'package:testt/booking/slot_generator.dart';

BookingScheduleData _minimal({
  List<Appointment> appointments = const [],
  List<WorkBreak> breaks = const [
    WorkBreak(start: '14:00', end: '15:00', label: 'Обід'),
  ],
}) {
  return BookingScheduleData(
    workingHours: WorkingHours(
      start: '10:00',
      end: '20:00',
      breaks: breaks,
    ),
    bufferMinutes: 15,
    services: const [
      ServiceItem(id: 's1', name: 'A', durationMinutes: 60),
    ],
    appointments: appointments,
  );
}

BookingScheduleData _noBreaks({
  List<Appointment> appointments = const [],
}) {
  return BookingScheduleData(
    workingHours: const WorkingHours(
      start: '10:00',
      end: '20:00',
      breaks: [],
    ),
    bufferMinutes: 15,
    services: const [
      ServiceItem(id: 's1', name: 'A', durationMinutes: 60),
    ],
    appointments: appointments,
  );
}

void main() {
  group('SlotGenerator', () {
    test('90 хв: останній можливий старт 18:30, 18:45 у сітці немає', () {
      final data = _noBreaks();
      final day = DateTime(2026, 5, 10);
      final now = DateTime(2026, 5, 9, 12, 0);
      final slots = SlotGenerator.buildGrid(
        data: data,
        selectedDate: day,
        serviceDurationMinutes: 90,
        now: now,
      );
      expect(slots.any((s) => s.startLabel == '18:45'), isFalse);
      expect(slots.last.startLabel, '18:30');
      expect(slots.last.isAvailable, isTrue);
    });

    test('перетин з обідом робить слот недоступним (старт за 10 хв до обіду)', () {
      final data = _minimal();
      final day = DateTime(2026, 5, 10);
      final now = DateTime(2026, 5, 9, 12, 0);
      final slots = SlotGenerator.buildGrid(
        data: data,
        selectedDate: day,
        serviceDurationMinutes: 30,
        now: now,
      );
      final lunchSlot = slots.firstWhere((s) => s.startLabel == '13:45');
      expect(lunchSlot.isAvailable, isFalse);
      expect(lunchSlot.disabledReason, contains('Обід'));
    });

    test('сьогодні слоти, що вже минули, недоступні', () {
      final data = _minimal();
      final day = DateTime(2026, 5, 10);
      final now = DateTime(2026, 5, 10, 13, 47);
      final slots = SlotGenerator.buildGrid(
        data: data,
        selectedDate: day,
        serviceDurationMinutes: 30,
        now: now,
      );
      final past = slots.firstWhere((s) => s.startLabel == '13:30');
      expect(past.isAvailable, isFalse);
      expect(past.disabledReason, 'Час уже минув');
      final future = slots.firstWhere((s) => s.startLabel == '15:00');
      expect(future.isAvailable, isTrue);
    });

    test('буфер 15 хв: після запису 11:00–12:00 старт о 12:00 недоступний', () {
      final data = _minimal(
        appointments: const [
          Appointment(
            id: 'a1',
            date: '2026-05-10',
            start: '11:00',
            end: '12:00',
            clientName: 'X',
          ),
        ],
      );
      final day = DateTime(2026, 5, 10);
      final now = DateTime(2026, 5, 9, 12, 0);
      final slots = SlotGenerator.buildGrid(
        data: data,
        selectedDate: day,
        serviceDurationMinutes: 60,
        now: now,
      );
      final atNoon = slots.firstWhere((s) => s.startLabel == '12:00');
      expect(atNoon.isAvailable, isFalse);
      expect(atNoon.disabledReason, contains('Зайнято'));

      final afterBuffer = slots.firstWhere((s) => s.startLabel == '12:15');
      expect(afterBuffer.isAvailable, isTrue);
    });

    test('150 хв при вікні 120 хв між записами — жодного доступного слоту', () {
      // Після буфера: перший запис до 12:15, другий з 14:15 — вільне вікно рівно 120 хв.
      // Обід прибираємо, щоб ізолювати кейс «вікно коротше за послугу».
      final data = _noBreaks(
        appointments: const [
          Appointment(
            id: 'a1',
            date: '2026-05-10',
            start: '11:00',
            end: '12:00',
            clientName: 'A',
          ),
          Appointment(
            id: 'a2',
            date: '2026-05-10',
            start: '14:30',
            end: '19:00',
            clientName: 'B',
          ),
        ],
      );
      final day = DateTime(2026, 5, 10);
      final now = DateTime(2026, 5, 9, 12, 0);
      final slots = SlotGenerator.buildGrid(
        data: data,
        selectedDate: day,
        serviceDurationMinutes: 150,
        now: now,
      );
      expect(slots.where((s) => s.isAvailable), isEmpty);
      expect(slots, isNotEmpty);
    });

    test('два записи поспіль з мінімальним буфером — між ними немає валідного старту', () {
      final data = _noBreaks(
        appointments: const [
          Appointment(
            id: 'a1',
            date: '2026-05-10',
            start: '11:00',
            end: '12:00',
            clientName: 'A',
          ),
          Appointment(
            id: 'a2',
            date: '2026-05-10',
            start: '12:15',
            end: '13:00',
            clientName: 'B',
          ),
        ],
      );
      final day = DateTime(2026, 5, 10);
      final now = DateTime(2026, 5, 9, 12, 0);
      final slots = SlotGenerator.buildGrid(
        data: data,
        selectedDate: day,
        serviceDurationMinutes: 30,
        now: now,
      );
      final between = slots.where(
        (s) =>
            s.startMinutesFromMidnight >= 12 * 60 &&
            s.startMinutesFromMidnight < 12 * 60 + 45,
      );
      expect(between, isNotEmpty);
      expect(between.every((s) => !s.isAvailable), isTrue);
    });

    test('коротка послуга дає більше доступних слотів, ніж довга', () {
      final data = _minimal();
      final day = DateTime(2026, 5, 10);
      final now = DateTime(2026, 5, 9, 12, 0);
      final shortSlots = SlotGenerator.buildGrid(
        data: data,
        selectedDate: day,
        serviceDurationMinutes: 30,
        now: now,
      );
      final longSlots = SlotGenerator.buildGrid(
        data: data,
        selectedDate: day,
        serviceDurationMinutes: 150,
        now: now,
      );
      final shortAvail = shortSlots.where((s) => s.isAvailable).length;
      final longAvail = longSlots.where((s) => s.isAvailable).length;
      expect(shortAvail, greaterThan(longAvail));
    });
  });
}
