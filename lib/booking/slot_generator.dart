import 'models.dart';

const int gridStepMinutes = 15;

/// Один кандидат у сітці (кожні 15 хв від початку робочого дня).
class SlotGridItem {
  const SlotGridItem({
    required this.startMinutesFromMidnight,
    required this.isAvailable,
    required this.disabledReason,
  });

  final int startMinutesFromMidnight;
  final bool isAvailable;

  /// Порожньо, якщо слот доступний.
  final String disabledReason;

  String get startLabel => _formatHm(startMinutesFromMidnight);
}

/// Генерація сітки слотів (чиста логіка для unit-тестів).
class SlotGenerator {
  SlotGenerator._();

  static List<SlotGridItem> buildGrid({
    required BookingScheduleData data,
    required DateTime selectedDate,
    required int serviceDurationMinutes,
    required DateTime now,
  }) {
    final ymd =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    final workStart = _parseMinutes(data.workingHours.start);
    final workEnd = _parseMinutes(data.workingHours.end);

    final breaks = data.workingHours.breaks
        .map((b) => (_parseMinutes(b.start), _parseMinutes(b.end), b.label))
        .toList();

    final dayAppointments = data.appointmentsOnDate(ymd);

    final isToday = _isSameDate(selectedDate, now);

    final items = <SlotGridItem>[];
    for (var t = workStart; t + serviceDurationMinutes <= workEnd; t += gridStepMinutes) {
      final slot = _Interval(t, t + serviceDurationMinutes);

      String reason = '';
      var ok = true;

      if (isToday) {
        final slotStart = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          t ~/ 60,
          t % 60,
        );
        if (!slotStart.isAfter(now)) {
          ok = false;
          reason = 'Час уже минув';
        }
      }

      if (ok) {
        for (final b in breaks) {
          if (_overlaps(slot, _Interval(b.$1, b.$2))) {
            ok = false;
            reason = '${b.$3} (${_formatHm(b.$1)}–${_formatHm(b.$2)})';
            break;
          }
        }
      }

      if (ok) {
        for (final a in dayAppointments) {
          final expanded = _Interval(
            _parseMinutes(a.start) - data.bufferMinutes,
            _parseMinutes(a.end) + data.bufferMinutes,
          );
          if (_overlaps(slot, expanded)) {
            ok = false;
            reason =
                'Зайнято: ${a.clientName} (${a.start}–${a.end}, буфер ${data.bufferMinutes} хв)';
            break;
          }
        }
      }

      if (ok) {
        items.add(SlotGridItem(
          startMinutesFromMidnight: t,
          isAvailable: true,
          disabledReason: '',
        ));
      } else {
        items.add(SlotGridItem(
          startMinutesFromMidnight: t,
          isAvailable: false,
          disabledReason: reason,
        ));
      }
    }

    return items;
  }
}

class _Interval {
  _Interval(this.start, this.end);
  final int start;
  final int end;
}

bool _overlaps(_Interval a, _Interval b) {
  return a.start < b.end && b.start < a.end;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int _parseMinutes(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  return h * 60 + m;
}

String _formatHm(int minutesFromMidnight) {
  final h = minutesFromMidnight ~/ 60;
  final m = minutesFromMidnight % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Допоміжно для JSON підтвердження та тестів.
String endTimeLabel(int startMinutesFromMidnight, int durationMinutes) {
  return _formatHm(startMinutesFromMidnight + durationMinutes);
}
