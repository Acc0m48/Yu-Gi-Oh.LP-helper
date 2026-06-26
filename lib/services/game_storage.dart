import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/game.dart';

class GameStorage {
  static Future<String> get _dir async {
    final dir = await getApplicationDocumentsDirectory();
    final gamesDir = Directory('${dir.path}/games');
    if (!await gamesDir.exists()) {
      await gamesDir.create(recursive: true);
    }
    return gamesDir.path;
  }

  static Future<List<Game>> loadAll() async {
    final dirPath = await _dir;
    final dir = Directory(dirPath);
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
    final games = <Game>[];
    for (final file in files) {
      try {
        final json = jsonDecode(await file.readAsString());
        games.add(Game.fromJson(json as Map<String, dynamic>));
      } catch (_) {}
    }
    games.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return games;
  }

  static Future<void> save(Game game) async {
    final dirPath = await _dir;
    final file = File('$dirPath/${game.id}.json');
    await file.writeAsString(jsonEncode(game.toJson()));
  }

  static Future<void> delete(Game game) async {
    final dirPath = await _dir;
    final file = File('$dirPath/${game.id}.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<String> exportAll() async {
    final games = await loadAll();
    return jsonEncode(games.map((g) => g.toJson()).toList());
  }

  static Future<void> importData(String jsonString) async {
    final list = jsonDecode(jsonString) as List<dynamic>;
    for (final item in list) {
      final game = Game.fromJson(item as Map<String, dynamic>);
      await save(game);
    }
  }
}
