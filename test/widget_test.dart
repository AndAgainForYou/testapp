import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:testt/booking/new_booking_screen.dart';

void main() {
  testWidgets('Новий запис: завантаження та заголовок', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NewBookingScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Новий запис'), findsWidgets);
    expect(find.text('Послуга'), findsOneWidget);
  });
}
