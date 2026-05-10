import 'package:flutter/services.dart';

import '../domain/booking_schedule_repository.dart';
import '../models.dart';
import 'booking_schedule_load_exception.dart';
import 'booking_schedule_parser.dart';

/// Завантаження розкладу з Flutter asset (локальний JSON).
class AssetBookingScheduleRepository implements BookingScheduleRepository {
  AssetBookingScheduleRepository({
    required this.assetPath,
    AssetBundle? bundle,
  }) : _bundle = bundle;

  final String assetPath;
  final AssetBundle? _bundle;

  @override
  Future<BookingScheduleData> loadSchedule() async {
    final bundle = _bundle ?? rootBundle;
    late final String raw;
    try {
      raw = await bundle.loadString(assetPath);
    } catch (e, st) {
      throw BookingScheduleLoadException(
        'Не вдалося прочитати файл розкладу. Перевірте, що «$assetPath» '
        'оголошено в pubspec.yaml у секції flutter/assets.',
        cause: e,
        technicalDetails: st.toString(),
      );
    }

    return BookingScheduleParser.parse(raw);
  }
}
