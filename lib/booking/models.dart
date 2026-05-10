class WorkingHours {
  const WorkingHours({
    required this.start,
    required this.end,
    required this.breaks,
  });

  final String start;
  final String end;
  final List<WorkBreak> breaks;

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      start: json['start'] as String,
      end: json['end'] as String,
      breaks: (json['breaks'] as List<dynamic>)
          .map((e) => WorkBreak.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkBreak {
  const WorkBreak({
    required this.start,
    required this.end,
    required this.label,
  });

  final String start;
  final String end;
  final String label;

  factory WorkBreak.fromJson(Map<String, dynamic> json) {
    return WorkBreak(
      start: json['start'] as String,
      end: json['end'] as String,
      label: json['label'] as String,
    );
  }
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.durationMinutes,
  });

  final String id;
  final String name;
  final int durationMinutes;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
    );
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.date,
    required this.start,
    required this.end,
    required this.clientName,
  });

  final String id;
  final String date;
  final String start;
  final String end;
  final String clientName;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      date: json['date'] as String,
      start: json['start'] as String,
      end: json['end'] as String,
      clientName: json['clientName'] as String,
    );
  }
}

class BookingScheduleData {
  const BookingScheduleData({
    required this.workingHours,
    required this.bufferMinutes,
    required this.services,
    required this.appointments,
  });

  final WorkingHours workingHours;
  final int bufferMinutes;
  final List<ServiceItem> services;
  final List<Appointment> appointments;

  factory BookingScheduleData.fromJson(Map<String, dynamic> json) {
    return BookingScheduleData(
      workingHours:
          WorkingHours.fromJson(json['workingHours'] as Map<String, dynamic>),
      bufferMinutes: (json['bufferMinutes'] as num).toInt(),
      services: (json['services'] as List<dynamic>)
          .map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      appointments: (json['appointments'] as List<dynamic>)
          .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  List<Appointment> appointmentsOnDate(String ymd) {
    return appointments.where((a) => a.date == ymd).toList();
  }
}
