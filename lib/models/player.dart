class Player {
  final String id;
  String name;
  int lp;
  int turn;

  Player({
    required this.id,
    this.name = '',
    this.lp = 8000,
    this.turn = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      lp: json['lp'] as int? ?? 8000,
      turn: json['turn'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lp': lp,
    'turn': turn,
  };
}
