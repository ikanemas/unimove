class Errand {
  const Errand({
    this.id,
    required this.title,
    required this.reward,
    required this.description,
    required this.timeToComplete,
    required this.status,
    required this.createdAt,
  });

  final int? id;
  final String title;
  final double reward;
  final String description;
  final String timeToComplete;
  final String status;
  final DateTime createdAt;

  factory Errand.fromMap(Map<String, Object?> map) {
    return Errand(
      id: map['id'] as int?,
      title: map['title'] as String,
      reward: (map['reward'] as num).toDouble(),
      description: map['description'] as String,
      timeToComplete: map['time_to_complete'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'reward': reward,
      'description': description,
      'time_to_complete': timeToComplete,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
