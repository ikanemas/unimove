class ErrandOffer {
  const ErrandOffer({
    required this.id,
    required this.errandId,
    required this.runnerId,
    required this.runnerName,
    required this.runnerPhone,
    required this.message,
    required this.proposedReward,
    required this.estimatedTime,
    required this.status,
    required this.createdAt,
    this.errandTitle,
    this.posterPhone,
  });

  final int id;
  final int errandId;
  final String runnerId;
  final String runnerName;
  final String runnerPhone;
  final String message;
  final double proposedReward;
  final String estimatedTime;
  final String status;
  final DateTime createdAt;
  final String? errandTitle;
  final String? posterPhone;

  factory ErrandOffer.fromMap(Map<String, Object?> map) {
    return ErrandOffer(
      id: map['id'] as int,
      errandId: map['errand_id'] as int,
      runnerId: map['runner_id'] as String,
      runnerName: map['runner_name'] as String,
      runnerPhone: map['runner_phone'] as String? ?? '',
      message: map['message'] as String,
      proposedReward: (map['proposed_reward'] as num).toDouble(),
      estimatedTime: map['estimated_time'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      errandTitle: map['errand_title'] as String?,
      posterPhone: map['poster_phone'] as String?,
    );
  }
}
