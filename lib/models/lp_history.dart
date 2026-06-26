class LpHistory {
  final int playerIndex;
  final int previousLp;
  final int newLp;
  final int delta;
  final DateTime timestamp;

  LpHistory({
    required this.playerIndex,
    required this.previousLp,
    required this.newLp,
    DateTime? timestamp,
  })  : delta = newLp - previousLp,
        timestamp = timestamp ?? DateTime.now();

  factory LpHistory.fromJson(Map<String, dynamic> json) {
    return LpHistory(
      playerIndex: json['playerIndex'] as int,
      previousLp: json['previousLp'] as int,
      newLp: json['newLp'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'playerIndex': playerIndex,
    'previousLp': previousLp,
    'newLp': newLp,
    'timestamp': timestamp.toIso8601String(),
  };
}
