import 'dart:convert';

import 'booking_schedule_load_exception.dart';
import 'booking_schedule_validator.dart';
import '../models.dart';

class BookingScheduleParser {
  BookingScheduleParser._();

  static BookingScheduleData parse(String raw) {
    Object? decoded;
    try {
      decoded = json.decode(raw);
    } on FormatException catch (e, st) {
      throw BookingScheduleLoadException(
        'Файл розкладу не є коректним JSON.',
        cause: e,
        technicalDetails: st.toString(),
      );
    }

    if (decoded is! Map) {
      throw BookingScheduleLoadException('Корінь документа має бути JSON-об’єктом.');
    }

    final map = Map<String, dynamic>.from(decoded);

    BookingScheduleValidator.validateRoot(map);

    try {
      return BookingScheduleData.fromJson(map);
    } on TypeError catch (e, st) {
      throw BookingScheduleLoadException(
        'Типи полів у JSON не відповідають очікуваній схемі (рядки, числа, масиви).',
        cause: e,
        technicalDetails: st.toString(),
      );
    }
  }
}
