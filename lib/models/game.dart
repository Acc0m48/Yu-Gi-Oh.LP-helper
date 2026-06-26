import 'player.dart';
import 'turn_record.dart';
import 'lp_history.dart';

class Game {
  final String id;
  String name;
  final DateTime createdAt;
  List<Player> players;
  int firstPlayerIndex;
  int currentPlayerIndex;
  int turn;
  bool gameStarted;
  int initialLp;
  List<TurnRecord> memos;
  List<LpHistory> lpHistory;

  Game({
    required this.id,
    required this.name,
    DateTime? createdAt,
    List<Player>? players,
    this.firstPlayerIndex = 0,
    int? currentPlayerIndex,
    this.turn = 0,
    this.gameStarted = false,
    this.initialLp = 8000,
    List<TurnRecord>? memos,
    List<LpHistory>? lpHistory,
  })  : currentPlayerIndex = currentPlayerIndex ?? firstPlayerIndex,
        createdAt = createdAt ?? DateTime.now(),
        players = players ?? [
          Player(id: '1', name: '依', lp: initialLp),
          Player(id: '2', name: '尔', lp: initialLp),
        ],
        memos = memos ?? [],
        lpHistory = lpHistory ?? [];

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      players: (json['players'] as List<dynamic>)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      firstPlayerIndex: json['firstPlayerIndex'] as int? ?? 0,
      currentPlayerIndex: json['currentPlayerIndex'] as int?,
      turn: json['turn'] as int? ?? 0,
      gameStarted: json['gameStarted'] as bool? ?? false,
      initialLp: json['initialLp'] as int? ?? 8000,
      memos: (json['memos'] as List<dynamic>?)
          ?.map((m) => TurnRecord.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      lpHistory: (json['lpHistory'] as List<dynamic>?)
          ?.map((h) => LpHistory.fromJson(h as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'players': players.map((p) => p.toJson()).toList(),
    'firstPlayerIndex': firstPlayerIndex,
    'currentPlayerIndex': currentPlayerIndex,
    'turn': turn,
    'gameStarted': gameStarted,
    'initialLp': initialLp,
    'memos': memos.map((m) => m.toJson()).toList(),
    'lpHistory': lpHistory.map((h) => h.toJson()).toList(),
  };
}
