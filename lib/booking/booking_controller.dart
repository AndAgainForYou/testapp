import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'slot_generator.dart';

class BookingController extends ChangeNotifier {
  BookingController();

  BookingScheduleData? _data;
  Object? loadError;

  ServiceItem? _selectedService;
  DateTime? _selectedDate;
  int? _selectedStartMinutes;

  bool _loaded = false;
  bool get isLoaded => _loaded;

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

  Future<void> loadFromAssets(String assetPath) async {
    loadError = null;
    try {
      final raw = await rootBundle.loadString(assetPath);
      final map = json.decode(raw) as Map<String, dynamic>;
      _data = BookingScheduleData.fromJson(map);
      _selectedService = _data!.services.isNotEmpty ? _data!.services.first : null;
      _selectedDate = dateOnly(DateTime.now());
      _selectedStartMinutes = null;
      _loaded = true;
    } catch (e, st) {
      loadError = e;
      _loaded = false;
      debugPrint('Booking load error: $e\n$st');
    }
    notifyListeners();
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

  /// JSON для підтвердження запису.
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
