class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.errandId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String userId;
  final int errandId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, Object?> map) {
    return AppNotification(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      errandId: map['errand_id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      isRead: (map['is_read'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
