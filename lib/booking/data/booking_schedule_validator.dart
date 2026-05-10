import 'booking_schedule_load_exception.dart';

/// Ручна валідація схеми JSON перед / після мапінгу в моделі.
class BookingScheduleValidator {
  BookingScheduleValidator._();

  static final RegExp _hm = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');
  static final RegExp _ymd = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static void validateRoot(Map<String, dynamic> json) {
    _requireKeys(json, const ['workingHours', 'bufferMinutes', 'services', 'appointments']);

    final wh = json['workingHours'];
    if (wh is! Map) {
      throw BookingScheduleLoadException('Поле «workingHours» має бути об’єктом.');
    }
    final whMap = Map<String, dynamic>.from(wh);
    _requireKeys(whMap, const ['start', 'end', 'breaks']);
    final ws = _parseMinutesLabel('workingHours.start', whMap['start'] as String);
    final we = _parseMinutesLabel('workingHours.end', whMap['end'] as String);
    if (ws >= we) {
      throw BookingScheduleLoadException(
        'Робочий день некоректний: початок має бути раніше за кінець.',
      );
    }

    final breaksRaw = whMap['breaks'];
    if (breaksRaw is! List) {
      throw BookingScheduleLoadException('Поле «breaks» має бути масивом.');
    }
    for (var i = 0; i < breaksRaw.length; i++) {
      final b = breaksRaw[i];
      if (b is! Map) {
        throw BookingScheduleLoadException('Елемент перерви #$i має бути об’єктом.');
      }
      final bm = Map<String, dynamic>.from(b);
      _requireKeys(bm, const ['start', 'end', 'label']);
      final bs = _parseMinutesLabel('breaks[$i].start', bm['start'] as String);
      final be = _parseMinutesLabel('breaks[$i].end', bm['end'] as String);
      if (bs >= be) {
        throw BookingScheduleLoadException('Перерва #$i: початок має бути раніше за кінець.');
      }
      if (bs < ws || be > we) {
        throw BookingScheduleLoadException(
          'Перерва #$i має повністю міститися в робочі години.',
        );
      }
    }

    final buf = json['bufferMinutes'];
    if (buf is! num || buf.toInt() != buf || buf < 0) {
      throw BookingScheduleLoadException(
        'Поле «bufferMinutes» має бути невід’ємним цілим числом.',
      );
    }

    final servicesRaw = json['services'];
    if (servicesRaw is! List || servicesRaw.isEmpty) {
      throw BookingScheduleLoadException(
        'Поле «services» має бути непорожнім масивом.',
      );
    }
    final seenIds = <String>{};
    for (var i = 0; i < servicesRaw.length; i++) {
      final s = servicesRaw[i];
      if (s is! Map) {
        throw BookingScheduleLoadException('Послуга #$i має бути об’єктом.');
      }
      final sm = Map<String, dynamic>.from(s);
      _requireKeys(sm, const ['id', 'name', 'durationMinutes']);
      final id = sm['id'] as String;
      if (id.trim().isEmpty) {
        throw BookingScheduleLoadException('Послуга #$i: порожній «id».');
      }
      if (!seenIds.add(id)) {
        throw BookingScheduleLoadException('Дубльований ідентифікатор послуги «$id».');
      }
      final name = sm['name'] as String;
      if (name.trim().isEmpty) {
        throw BookingScheduleLoadException('Послуга «$id»: порожня назва.');
      }
      final dm = sm['durationMinutes'];
      if (dm is! num || dm.toInt() != dm || dm <= 0) {
        throw BookingScheduleLoadException(
          'Послуга «$id»: «durationMinutes» має бути додатним цілим.',
        );
      }
    }

    final appRaw = json['appointments'];
    if (appRaw is! List) {
      throw BookingScheduleLoadException('Поле «appointments» має бути масивом.');
    }
    for (var i = 0; i < appRaw.length; i++) {
      final a = appRaw[i];
      if (a is! Map) {
        throw BookingScheduleLoadException('Запис #$i має бути об’єктом.');
      }
      final am = Map<String, dynamic>.from(a);
      _requireKeys(am, const ['id', 'date', 'start', 'end', 'clientName']);
      final dateStr = am['date'] as String;
      if (!_ymd.hasMatch(dateStr)) {
        throw BookingScheduleLoadException(
          'Запис #$i: дата «$dateStr» має формат РРРР-ММ-ДД.',
        );
      }
      final aStart = _parseMinutesLabel('appointments[$i].start', am['start'] as String);
      final aEnd = _parseMinutesLabel('appointments[$i].end', am['end'] as String);
      if (aStart >= aEnd) {
        throw BookingScheduleLoadException(
          'Запис #$i: час початку має бути раніше за час закінчення.',
        );
      }
      final cn = am['clientName'] as String;
      if (cn.trim().isEmpty) {
        throw BookingScheduleLoadException('Запис #$i: порожнє ім’я клієнта.');
      }
    }
  }

  static void _requireKeys(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (!map.containsKey(k)) {
        throw BookingScheduleLoadException('У JSON бракує обов’язкового поля «$k».');
      }
    }
  }

  static int _parseMinutesLabel(String label, String value) {
    final m = _hm.firstMatch(value.trim());
    if (m == null) {
      throw BookingScheduleLoadException(
        'Некоректний час у «$label»: очікується ГГ:ХХ (00:00–23:59).',
      );
    }
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    return h * 60 + min;
  }
}
