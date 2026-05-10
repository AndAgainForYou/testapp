import 'package:flutter/foundation.dart';

import 'data/asset_booking_schedule_repository.dart';
import 'data/booking_schedule_load_exception.dart';
import 'domain/booking_schedule_repository.dart';
import 'models.dart';
import 'slot_generator.dart';

/// Контролер екрана: залежить від [BookingScheduleRepository], а не від assets напряму.
class BookingController extends ChangeNotifier {
  BookingController({
    BookingScheduleRepository? repository,
    String assetPath = 'assets/booking_schedule.json',
  }) : _repository = repository ?? AssetBookingScheduleRepository(assetPath: assetPath);

  final BookingScheduleRepository _repository;

  BookingScheduleData? _data;
  BookingScheduleLoadException? loadError;
  bool loading = false;

  ServiceItem? _selectedService;
  DateTime? _selectedDate;
  int? _selectedStartMinutes;

  bool get isLoaded => _data != null;

  BookingScheduleData? get data => _data;
  ServiceItem? get selectedService => _selectedService;
  DateTime? get selectedDate => _selectedDate;
  int? get selectedStartMinutes => _selectedStartMinutes;

  List<SlotGridItem> get slots {
    final d = _data;
    final svc = _selectedService;
    final day = _selectedDate;
    if (d == null || svc == null || day == null) return const [];
    return SlotGenerator.buildGrid(
      data: d,
      selectedDate: day,
      serviceDurationMinutes: svc.durationMinutes,
      now: DateTime.now(),
    );
  }

  Future<void> loadSchedule() async {
    loadError = null;
    loading = true;
    notifyListeners();

    try {
      final schedule = await _repository.loadSchedule();
      _data = schedule;
      _selectedService = schedule.services.isNotEmpty ? schedule.services.first : null;
      _selectedDate = dateOnly(DateTime.now());
      _selectedStartMinutes = null;
    } on BookingScheduleLoadException catch (e, st) {
      _data = null;
      loadError = e;
      debugPrint('BookingScheduleLoadException: ${e.userMessage}\n${e.cause}\n$st');
    } catch (e, st) {
      _data = null;
      loadError = BookingScheduleLoadException(
        'Неочікувана помилка під час завантаження розкладу.',
        cause: e,
        technicalDetails: st.toString(),
      );
      debugPrint('Booking load error: $e\n$st');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void selectService(ServiceItem? s) {
    _selectedService = s;
    _selectedStartMinutes = null;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = dateOnly(date);
    _selectedStartMinutes = null;
    notifyListeners();
  }

  void selectSlot(int? startMinutes) {
    _selectedStartMinutes = startMinutes;
    notifyListeners();
  }

  Map<String, String>? buildConfirmationPayload() {
    final d = _data;
    final svc = _selectedService;
    final day = _selectedDate;
    final startMin = _selectedStartMinutes;
    if (d == null || svc == null || day == null || startMin == null) return null;

    final ymd =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    final start = SlotGridItem(
      startMinutesFromMidnight: startMin,
      isAvailable: true,
      disabledReason: '',
    ).startLabel;
    final end = endTimeLabel(startMin, svc.durationMinutes);

    return {
      'serviceId': svc.id,
      'date': ymd,
      'startTime': start,
      'endTime': end,
    };
  }

  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }
}
