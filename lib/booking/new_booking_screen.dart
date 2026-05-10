import 'dart:convert';

import 'package:flutter/material.dart';

import 'booking_controller.dart';
import 'models.dart';
import 'slot_generator.dart';
import '../theme/app_palette.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final BookingController _controller = BookingController();

  static const _monthsShort = [
    'Січ',
    'Лют',
    'Бер',
    'Кві',
    'Трав',
    'Чер',
    'Лип',
    'Сер',
    'Вер',
    'Жов',
    'Лис',
    'Гру',
  ];

  /// Короткі назви днів (DateTime.weekday: 1 = пн … 7 = нд)
  static const _weekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

  static const _sectionBottom = 12.0;
  static const _horizontalPad = 20.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onCtrl);
    _controller.loadSchedule();
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _sectionBottom),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppPalette.labelGray,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _dateCard(BuildContext context, DateTime d, bool selected) {
    final scheme = Theme.of(context).colorScheme;
    final wd = _weekdaysShort[d.weekday - 1];
    final month = _monthsShort[d.month - 1];

    return Material(
      color: selected ? scheme.primary : Colors.white,
      elevation: selected ? 2 : 0,
      shadowColor: scheme.primary.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? Colors.transparent : AppPalette.borderMuted,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _controller.selectDate(d),
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 62,
          height: 88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                wd,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white70 : AppPalette.labelGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${d.day}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: selected ? Colors.white : AppPalette.titleDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                month,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white.withValues(alpha: 0.92) : AppPalette.labelGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeSlotCell(BuildContext context, SlotGridItem slot) {
    final scheme = Theme.of(context).colorScheme;
    final selected =
        _controller.selectedStartMinutes == slot.startMinutesFromMidnight &&
            slot.isAvailable;
    final label = slot.startLabel;

    if (!slot.isAvailable) {
      final box = Material(
        color: AppPalette.slotDisabledBg,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPalette.slotDisabledFg,
            ),
          ),
        ),
      );
      return Tooltip(
        message: slot.disabledReason,
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 4),
        child: box,
      );
    }

    return Material(
      color: selected ? scheme.primary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? Colors.transparent : scheme.primary,
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () => _controller.selectSlot(slot.startMinutesFromMidnight),
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : scheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.loading) {
      return Scaffold(
        backgroundColor: AppPalette.scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final err = _controller.loadError;
    if (err != null) {
      return Scaffold(
        backgroundColor: AppPalette.scaffoldBg,
        appBar: AppBar(
          title: const Text('Новий запис'),
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
          automaticallyImplyLeading: Navigator.of(context).canPop(),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(_horizontalPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 56, color: AppPalette.labelGray),
                const SizedBox(height: 16),
                Text(
                  'Не вдалося завантажити розклад',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppPalette.titleDark,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  err.userMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: AppPalette.labelGray,
                  ),
                ),
                if (err.technicalDetails != null && err.technicalDetails!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text(
                      'Технічні деталі',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.teal),
                    ),
                    children: [
                      SelectableText(
                        err.technicalDetails!,
                        style: const TextStyle(fontSize: 11, height: 1.35, color: AppPalette.labelGray, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _controller.loadSchedule(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Спробувати знову'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
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
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppPalette.scaffoldBg,
      appBar: AppBar(
        title: const Text('Новий запис'),
        leading: canPop
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        automaticallyImplyLeading: canPop,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(_horizontalPad, 8, _horizontalPad, 16),
                children: [
                  _sectionLabel('Послуга'),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppPalette.borderMuted),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ServiceItem>(
                          isExpanded: true,
                          value: _controller.selectedService,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppPalette.labelGray),
                          borderRadius: BorderRadius.circular(12),
                          items: services
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    '${s.name} (${s.durationMinutes} хв)',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppPalette.titleDark,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => _controller.selectService(v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionLabel('Виберіть дату'),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final d = days[i];
                        final selected = d.year == selectedDate.year &&
                            d.month == selectedDate.month &&
                            d.day == selectedDate.day;
                        return _dateCard(context, d, selected);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionLabel('Оберіть час'),
                  if (slots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Немає стартів, що вміщають обрану послугу до кінця робочого дня.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppPalette.labelGray,
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const cols = 5;
                        const spacing = 10.0;
                        const rowHeight = 42.0;
                        final rows = (slots.length / cols).ceil();
                        final gridH = rows * rowHeight + (rows - 1) * spacing;

                        return SizedBox(
                          height: gridH,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: spacing,
                              crossAxisSpacing: spacing,
                              mainAxisExtent: rowHeight,
                            ),
                            itemCount: slots.length,
                            itemBuilder: (context, index) => _timeSlotCell(context, slots[index]),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(_horizontalPad, 0, _horizontalPad, 16 + MediaQuery.paddingOf(context).bottom),
              child: FilledButton(
                onPressed: () => _confirm(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_available_rounded, size: 22, color: Colors.white.withValues(alpha: 0.98)),
                    const SizedBox(width: 10),
                    const Text(
                      'Підтвердити запис',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
