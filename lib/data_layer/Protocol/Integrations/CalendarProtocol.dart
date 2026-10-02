/// Normalized device calendar (Apple Calendar on iOS, system calendars on Android).
class CalendarProtocol {
  final String id;
  final String name;
  final bool isReadOnly;
  final bool isDefault;
  final int? color;
  final String? accountName;

  const CalendarProtocol({
    required this.id,
    required this.name,
    this.isReadOnly = false,
    this.isDefault = false,
    this.color,
    this.accountName,
  });

  bool get isWritable => !isReadOnly;
}
