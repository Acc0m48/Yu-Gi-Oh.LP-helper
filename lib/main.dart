import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/game_storage.dart';
import 'models/game.dart';
import 'models/player.dart';
import 'screens/game_screen.dart';
import 'screens/settings_page.dart';
import 'screens/start_game_dialogs.dart';
import 'widgets/game_drawer.dart';
import 'theme.dart';

void main() {
  runApp(const LpApp());
}

class LpApp extends StatefulWidget {
  const LpApp({super.key});

  @override
  State<LpApp> createState() => _LpAppState();

  static _LpAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_LpAppState>();
}

class _LpAppState extends State<LpApp> {
  int _themeIndex = 0;
  int _brightnessMode = 0;
  int _cLightSeed = 0xFFD96C4A, _cLightBg = 0xFFF4E0D0;
  int _cDarkSeed = 0xFFFFB347, _cDarkBg = 0xFF3B2D26;
  int _cLpPos = 0xFFFF8C42, _cLpNeg = 0xFFD96C4A;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final s = await GameStorage.loadSettings();
    setState(() {
      _themeIndex = s.themeIndex;
      _brightnessMode = s.brightnessMode;
      _cLightSeed = s.cLightSeed; _cLightBg = s.cLightBg;
      _cDarkSeed = s.cDarkSeed; _cDarkBg = s.cDarkBg;
      _cLpPos = s.cLpPos; _cLpNeg = s.cLpNeg;
    });
  }

  void applySettings(AppSettings s) {
    setState(() {
      _themeIndex = s.themeIndex;
      _brightnessMode = s.brightnessMode;
      _cLightSeed = s.cLightSeed; _cLightBg = s.cLightBg;
      _cDarkSeed = s.cDarkSeed; _cDarkBg = s.cDarkBg;
      _cLpPos = s.cLpPos; _cLpNeg = s.cLpNeg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _themeIndex < presets.length
        ? presets[_themeIndex]
        : customPresetFrom(lightSeed: _cLightSeed, lightBg: _cLightBg, darkSeed: _cDarkSeed, darkBg: _cDarkBg, lpPos: _cLpPos, lpNeg: _cLpNeg);
    final mode = _brightnessMode == 1 ? ThemeMode.light : _brightnessMode == 2 ? ThemeMode.dark : ThemeMode.system;
    return MaterialApp(
      title: 'LP助手',
      debugShowCheckedModeBanner: false,
      theme: buildPresetLight(p),
      darkTheme: buildPresetDark(p),
      themeMode: mode,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Game> _games = [];
  Game? _currentGame;
  AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final games = await GameStorage.loadAll();
    final settings = await GameStorage.loadSettings();
    setState(() {
      _games = games;
      _settings = settings;
      if (_currentGame == null && _games.isNotEmpty) {
        _currentGame = _games.first;
      } else if (_currentGame != null) {
        final idx = _games.indexWhere((g) => g.id == _currentGame!.id);
        _currentGame = idx >= 0 ? _games[idx] : (_games.isNotEmpty ? _games.first : null);
      }
    });
  }

  Future<void> _save() async {
    if (_currentGame == null) return;
    await GameStorage.save(_currentGame!);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          settings: _settings,
          onSaved: (s) {
            LpApp.of(context)?.applySettings(s);
            setState(() => _settings = s);
          },
          onThemeChanged: (s) => LpApp.of(context)?.applySettings(s),
        ),
      ),
    );
  }

  void _createGame() {
    final nameCtrl = TextEditingController();
    final p1Ctrl = TextEditingController(text: _settings.defaultP1Name);
    final p2Ctrl = TextEditingController(text: _settings.defaultP2Name);
    final lpCtrl = TextEditingController(text: '${_settings.defaultLp}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('新建对局'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '对局名称',
                  hintText: '输入对局名称...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: p1Ctrl,
                      decoration: const InputDecoration(
                        labelText: '玩家1',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: p2Ctrl,
                      decoration: const InputDecoration(
                        labelText: '玩家2',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '初始LP',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim().isEmpty ? '对局' : nameCtrl.text.trim();
                final now = DateTime.now();
                final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                final lp = int.tryParse(lpCtrl.text) ?? _settings.defaultLp;
                final p1Name = p1Ctrl.text.trim().isEmpty ? _settings.defaultP1Name : p1Ctrl.text.trim();
                final p2Name = p2Ctrl.text.trim().isEmpty ? _settings.defaultP2Name : p2Ctrl.text.trim();
                final game = Game(
                  id: now.millisecondsSinceEpoch.toString(),
                  name: '$name $dateStr',
                  players: [
                    Player(id: '1', name: p1Name, lp: lp),
                    Player(id: '2', name: p2Name, lp: lp),
                  ],
                  initialLp: lp,
                );
                setState(() {
                  _games.insert(0, game);
                  _currentGame = game;
                });
                GameStorage.save(game);
                Navigator.pop(ctx);
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    StartGameDialogs.showStartGameDialog(
      context,
      players: _currentGame!.players,
      onFirstPlayerSelected: (firstPlayerIndex) {
        _currentGame!.firstPlayerIndex = firstPlayerIndex;
        _currentGame!.currentPlayerIndex = firstPlayerIndex;
        _currentGame!.turn = 1;
        _currentGame!.gameStarted = true;
        _save();
        setState(() {});
      },
    );
  }

  void _switchGame(Game game) async {
    await _save();
    setState(() => _currentGame = game);
  }

  Future<void> _deleteGame(Game game) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除对局「${game.name}」吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await GameStorage.delete(game);
    setState(() {
      _games.removeWhere((g) => g.id == game.id);
      if (_currentGame?.id == game.id) {
        _currentGame = _games.isNotEmpty ? _games.first : null;
      }
    });
  }

  Future<void> _exportData() async {
    if (_settings.exportDir.isNotEmpty) {
      try {
        await GameStorage.exportToFile(_settings.exportDir);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到 ${_settings.exportDir}')),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出失败，请检查目录路径')),
        );
      }
    } else {
      final json = await GameStorage.exportAll();
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数据已复制到剪贴板')),
      );
    }
  }

  Future<void> _importData() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入数据'),
        content: TextField(
          controller: ctrl, maxLines: 5,
          decoration: const InputDecoration(labelText: '粘贴JSON数据或输入文件路径', hintText: '粘贴JSON或输入完整文件路径...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('导入')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        if (result.startsWith('{') || result.startsWith('[')) {
          await GameStorage.importData(result);
        } else {
          await GameStorage.importFromFile(result);
        }
        await _loadAll();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导入成功')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导入失败，请检查数据格式')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _currentGame;
    return Scaffold(
      appBar: AppBar(
        title: Text(game?.name ?? 'LP助手', overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: game != null && !game.gameStarted
            ? [
                ElevatedButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('开始对局', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                const SizedBox(width: 6),
              ]
            : null,
      ),
      drawer: GameDrawer(
        currentGame: _currentGame,
        games: _games,
        onCreateGame: _createGame,
        onSwitchGame: _switchGame,
        onDeleteGame: _deleteGame,
        onExportData: _exportData,
        onImportData: _importData,
        onOpenSettings: _openSettings,
      ),
      body: game == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.games_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('点击左上角菜单新建对局', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : !game.gameStarted
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_esports, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        '${game.players[0].name} vs ${game.players[1].name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '起始LP: ${game.initialLp}',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      const Text('点击右上角「开始对局」决定先攻', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : GameScreen(
                  players: game.players,
                  currentPlayerIndex: game.currentPlayerIndex,
                  turn: game.turn,
                  initialLp: game.initialLp,
                  memos: game.memos,
                  onTurnChanged: (t) {
                    game.turn = t;
                    _save();
                    setState(() {});
                  },
                  onCurrentPlayerChanged: (pi) {
                    game.currentPlayerIndex = pi;
                    _save();
                    setState(() {});
                  },
                  onDataChanged: () {
                    _save();
                    setState(() {});
                  },
                ),
    );
  }
}
