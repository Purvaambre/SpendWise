class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String type;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });
}
