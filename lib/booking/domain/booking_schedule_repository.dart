import '../models.dart';

/// Джерело розкладу (assets зараз; пізніше — REST / локальна БД).
abstract class BookingScheduleRepository {
  Future<BookingScheduleData> loadSchedule();
}
