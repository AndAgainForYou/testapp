/// Помилка завантаження або валідації розкладу — з повідомленням для користувача.
class BookingScheduleLoadException implements Exception {
  BookingScheduleLoadException(
    this.userMessage, {
    this.cause,
    this.technicalDetails,
  });

  /// Текст для SnackBar / екрана помилки.
  final String userMessage;

  /// Оригінальна причина (для логів).
  final Object? cause;

  /// Додатковий текст (stack / контекст парсера), опційно показувати згорнуто в UI.
  final String? technicalDetails;

  @override
  String toString() => userMessage;
}
