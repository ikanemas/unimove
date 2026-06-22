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

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      errandId: errandId,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromMap(Map<String, Object?> map) {
    return AppNotification(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      errandId: map['errand_id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      isRead: _readBool(map['is_read']),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }
}
