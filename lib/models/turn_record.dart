class TurnRecord {
  int turnNumber;
  String phase;
  final DateTime timestamp;
  String note;
  int? playerIndex;
  int? lpDelta;
  int? lpBefore;
  int? lpAfter;

  TurnRecord({
    required this.turnNumber,
    this.phase = '',
    DateTime? timestamp,
    this.note = '',
    this.playerIndex,
    this.lpDelta,
    this.lpBefore,
    this.lpAfter,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isLpChange => playerIndex != null;

  factory TurnRecord.fromJson(Map<String, dynamic> json) {
    return TurnRecord(
      turnNumber: json['turnNumber'] as int,
      phase: json['phase'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String? ?? '',
      playerIndex: json['playerIndex'] as int?,
      lpDelta: json['lpDelta'] as int?,
      lpBefore: json['lpBefore'] as int?,
      lpAfter: json['lpAfter'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'turnNumber': turnNumber,
    'phase': phase,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
    if (playerIndex != null) 'playerIndex': playerIndex,
    if (lpDelta != null) 'lpDelta': lpDelta,
    if (lpBefore != null) 'lpBefore': lpBefore,
    if (lpAfter != null) 'lpAfter': lpAfter,
  };
}
