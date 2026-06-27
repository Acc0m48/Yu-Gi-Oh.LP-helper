import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/game.dart';

class AppSettings {
  int defaultLp;
  String defaultP1Name;
  String defaultP2Name;
  String exportDir;
  int themeIndex;
  int brightnessMode; // 0=system, 1=light, 2=dark

  // Custom theme colors
  int cLightSeed;
  int cLightBg;
  int cDarkSeed;
  int cDarkBg;
  int cLpPos;
  int cLpNeg;

  AppSettings({
    this.defaultLp = 8000,
    this.defaultP1Name = '依',
    this.defaultP2Name = '尔',
    this.exportDir = '',
    this.themeIndex = 0,
    this.brightnessMode = 0,
    this.cLightSeed = 0xFFD96C4A,
    this.cLightBg = 0xFFF4E0D0,
    this.cDarkSeed = 0xFFFFB347,
    this.cDarkBg = 0xFF3B2D26,
    this.cLpPos = 0xFFFF8C42,
    this.cLpNeg = 0xFFD96C4A,
  });

  Map<String, dynamic> toJson() => {
    'defaultLp': defaultLp,
    'defaultP1Name': defaultP1Name,
    'defaultP2Name': defaultP2Name,
    'exportDir': exportDir,
    'themeIndex': themeIndex,
    'brightnessMode': brightnessMode,
    'cLightSeed': cLightSeed,
    'cLightBg': cLightBg,
    'cDarkSeed': cDarkSeed,
    'cDarkBg': cDarkBg,
    'cLpPos': cLpPos,
    'cLpNeg': cLpNeg,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    defaultLp: json['defaultLp'] as int? ?? 8000,
    defaultP1Name: json['defaultP1Name'] as String? ?? '依',
    defaultP2Name: json['defaultP2Name'] as String? ?? '尔',
    exportDir: json['exportDir'] as String? ?? '',
    themeIndex: json['themeIndex'] as int? ?? 0,
    brightnessMode: json['brightnessMode'] as int? ?? 0,
    cLightSeed: json['cLightSeed'] as int? ?? 0xFFD96C4A,
    cLightBg: json['cLightBg'] as int? ?? 0xFFF4E0D0,
    cDarkSeed: json['cDarkSeed'] as int? ?? 0xFFFFB347,
    cDarkBg: json['cDarkBg'] as int? ?? 0xFF3B2D26,
    cLpPos: json['cLpPos'] as int? ?? 0xFFFF8C42,
    cLpNeg: json['cLpNeg'] as int? ?? 0xFFD96C4A,
  );
}

class GameStorage {
  static Future<String> get _dir async {
    final dir = await getApplicationDocumentsDirectory();
    final gamesDir = Directory('${dir.path}/games');
    if (!await gamesDir.exists()) await gamesDir.create(recursive: true);
    return gamesDir.path;
  }

  static Future<File> get _settingsFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/lp_settings.json');
  }

  static Future<AppSettings> loadSettings() async {
    try {
      final f = await _settingsFile;
      if (await f.exists()) {
        final json = jsonDecode(await f.readAsString());
        return AppSettings.fromJson(json as Map<String, dynamic>);
      }
    } catch (_) {}
    return AppSettings();
  }

  static Future<void> saveSettings(AppSettings s) async {
    final f = await _settingsFile;
    await f.writeAsString(jsonEncode(s.toJson()));
  }

  static String? get exportDirectory => null;

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
    if (await file.exists()) await file.delete();
  }

  static Future<String> exportAll() async {
    final games = await loadAll();
    return jsonEncode(games.map((g) => g.toJson()).toList());
  }

  static Future<void> exportToFile(String dirPath) async {
    final json = await exportAll();
    final now = DateTime.now();
    final name = 'LP_export_${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}.json';
    final file = File('$dirPath/$name');
    await file.writeAsString(json);
  }

  static Future<void> importData(String jsonString) async {
    final list = jsonDecode(jsonString) as List<dynamic>;
    for (final item in list) {
      final game = Game.fromJson(item as Map<String, dynamic>);
      await save(game);
    }
  }

  static Future<void> importFromFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      await importData(jsonString);
    }
  }
}
