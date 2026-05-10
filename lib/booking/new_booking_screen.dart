import 'dart:convert';

import 'package:flutter/material.dart';

import 'booking_controller.dart';
import 'models.dart';
import 'slot_generator.dart';

const String kBookingAsset = 'assets/booking_schedule.json';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final BookingController _controller = BookingController();

  static const _months = [
    'січня',
    'лютого',
    'березня',
    'квітня',
    'травня',
    'червня',
    'липня',
    'серпня',
    'вересня',
    'жовтня',
    'листопада',
    'грудня',
  ];

  /// DateTime.weekday: 1 = понеділок … 7 = неділя
  static const _weekdaysShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'нд'];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onCtrl);
    _controller.loadFromAssets(kBookingAsset);
  }

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onCtrl);
    _controller.dispose();
    super.dispose();
  }

  List<DateTime> _weekDaysFromToday() {
    final t = BookingController.dateOnly(DateTime.now());
    return List.generate(7, (i) => t.add(Duration(days: i)));
  }

  String _formatDayChip(DateTime d) {
    final wd = _weekdaysShort[d.weekday - 1];
    return '$wd, ${d.day} ${_months[d.month - 1]}';
  }

  void _confirm(BuildContext context) {
    final payload = _controller.buildConfirmationPayload();
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оберіть послугу, дату та час')),
      );
      return;
    }

    final sm = _controller.selectedStartMinutes;
    final slots = _controller.slots;
    final slotOk = sm != null &&
        slots.any(
          (s) => s.startMinutesFromMidnight == sm && s.isAvailable,
        );
    if (!slotOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оберіть доступний час')),
      );
      return;
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    debugPrint(jsonStr);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText(jsonStr, style: const TextStyle(fontSize: 12)),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isLoaded && _controller.loadError == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller.loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Новий запис')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Не вдалося завантажити розклад:\n${_controller.loadError}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final data = _controller.data!;
    final services = data.services;
    final days = _weekDaysFromToday();
    final selectedDate = _controller.selectedDate ?? days.first;
    final slots = _controller.slots;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новий запис'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Послуга',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ServiceItem>(
                isExpanded: true,
                value: _controller.selectedService,
                items: services
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.name} (${s.durationMinutes} хв)'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => _controller.selectService(v),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Дата (7 днів від сьогодні)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = days[i];
                final selected = d.year == selectedDate.year &&
                    d.month == selectedDate.month &&
                    d.day == selectedDate.day;
                return ChoiceChip(
                  label: Text(_formatDayChip(d)),
                  selected: selected,
                  onSelected: (_) => _controller.selectDate(d),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Час (крок 15 хв)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (slots.isEmpty)
            const Text('Немає жодного старту, що вміщує обрану послугу до кінця дня.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final selected =
                    _controller.selectedStartMinutes == slot.startMinutesFromMidnight;
                final duration = _controller.selectedService?.durationMinutes ?? 0;
                final end = endTimeLabel(slot.startMinutesFromMidnight, duration);

                Widget chip = FilterChip(
                  label: Text('${slot.startLabel}–$end'),
                  selected: selected && slot.isAvailable,
                  onSelected: slot.isAvailable
                      ? (_) => _controller.selectSlot(slot.startMinutesFromMidnight)
                      : null,
                  showCheckmark: false,
                  disabledColor: Colors.grey.shade300,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                );

                if (!slot.isAvailable) {
                  chip = Tooltip(
                    message: slot.disabledReason,
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 4),
                    child: chip,
                  );
                }

                return chip;
              }).toList(),
            ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => _confirm(context),
            child: const Text('Підтвердити запис'),
          ),
        ],
      ),
    );
  }
}
