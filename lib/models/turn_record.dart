class TurnRecord {
  final int turnNumber;
  final String phase;
  final DateTime timestamp;
  String note;

  TurnRecord({
    required this.turnNumber,
    this.phase = '',
    DateTime? timestamp,
    this.note = '',
  }) : timestamp = timestamp ?? DateTime.now();

  factory TurnRecord.fromJson(Map<String, dynamic> json) {
    return TurnRecord(
      turnNumber: json['turnNumber'] as int,
      phase: json['phase'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'turnNumber': turnNumber,
    'phase': phase,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
  };
}
