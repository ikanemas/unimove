class Errand {
  const Errand({
    this.id,
    required this.title,
    required this.reward,
    required this.description,
    required this.timeToComplete,
    required this.status,
    required this.createdAt,
    this.posterId,
    this.posterName,
    this.posterPhone,
    this.runnerId,
    this.runnerName,
    this.runnerPhone,
    this.acceptedAt,
    this.isSeed = false,
  });

  final int? id;
  final String title;
  final double reward;
  final String description;
  final String timeToComplete;
  final String status;
  final DateTime createdAt;
  final String? posterId;
  final String? posterName;
  final String? posterPhone;
  final String? runnerId;
  final String? runnerName;
  final String? runnerPhone;
  final DateTime? acceptedAt;
  final bool isSeed;

  bool get isAssigned => runnerId != null && runnerId!.isNotEmpty;
  String get displayStatus =>
      status == 'Open' && isAssigned ? 'Accepted' : status;

  factory Errand.fromMap(Map<String, Object?> map) {
    return Errand(
      id: map['id'] as int?,
      title: map['title'] as String,
      reward: (map['reward'] as num).toDouble(),
      description: map['description'] as String,
      timeToComplete: map['time_to_complete'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      posterId: (map['poster_id'] ?? map['user_id']) as String?,
      posterName: map['poster_name'] as String?,
      posterPhone: map['poster_phone'] as String?,
      runnerId: map['runner_id'] as String?,
      runnerName: map['runner_name'] as String?,
      runnerPhone: map['runner_phone'] as String?,
      acceptedAt: map['accepted_at'] == null
          ? null
          : DateTime.parse(map['accepted_at'] as String),
      isSeed: _readBool(map['is_seed']),
    );
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
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
      'poster_id': posterId,
      'poster_name': posterName,
      'poster_phone': posterPhone,
      'runner_id': runnerId,
      'runner_name': runnerName,
      'runner_phone': runnerPhone,
      'accepted_at': acceptedAt?.toIso8601String(),
      'is_seed': isSeed ? 1 : 0,
    };
  }
}
