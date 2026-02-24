class WidgetProtocol {
  final int widgetID;
  final String personID;
  final String widgetName;
  final String widgetType;
  final String configuration; // JSON string
  final int displayOrder;
  final bool isActive;
  final String role;

  WidgetProtocol({
    required this.widgetID,
    required this.personID,
    required this.widgetName,
    required this.widgetType,
    this.configuration = '{}',
    this.displayOrder = 0,
    this.isActive = true,
    this.role = 'admin',
  });
}
