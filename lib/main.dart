import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/game_storage.dart';
import 'models/game.dart';
import 'models/player.dart';
import 'screens/game_screen.dart';
import 'screens/settings_page.dart';

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
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LP助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
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
          onSaved: (s) => setState(() => _settings = s),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('决定先攻', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _startOption(ctx, '骰子', Icons.casino, '双方各掷一次骰子，点数大者先攻', () {
              Navigator.pop(ctx);
              _startByDice();
            }),
            const SizedBox(height: 8),
            _startOption(ctx, '硬币', Icons.token, '选择一方抛硬币，猜正/反面', () {
              Navigator.pop(ctx);
              _startByCoin();
            }),
            const SizedBox(height: 8),
            _startOption(ctx, '自定', Icons.touch_app, '手动选择先攻玩家', () {
              Navigator.pop(ctx);
              _startByCustom();
            }),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消'))],
      ),
    );
  }

  Widget _startOption(BuildContext ctx, String title, IconData icon, String desc, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(12)),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _startByDice() {
    showDialog(
      context: context,
      builder: (ctx) => _DiceDialog(
        players: _currentGame!.players,
        onConfirm: (firstPlayerIndex) {
          _currentGame!.firstPlayerIndex = firstPlayerIndex;
          _currentGame!.currentPlayerIndex = firstPlayerIndex;
          _currentGame!.turn = 1;
          _currentGame!.gameStarted = true;
          _save();
          Navigator.pop(ctx);
          setState(() {});
        },
      ),
    );
  }

  void _startByCoin() {
    showDialog(
      context: context,
      builder: (ctx) => _CoinDialog(
        players: _currentGame!.players,
        onConfirm: (firstPlayerIndex) {
          _currentGame!.firstPlayerIndex = firstPlayerIndex;
          _currentGame!.currentPlayerIndex = firstPlayerIndex;
          _currentGame!.turn = 1;
          _currentGame!.gameStarted = true;
          _save();
          Navigator.pop(ctx);
          setState(() {});
        },
      ),
    );
  }

  void _startByCustom() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择先攻玩家'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _currentGame!.firstPlayerIndex = 0;
                  _currentGame!.currentPlayerIndex = 0;
                  _currentGame!.turn = 1;
                  _currentGame!.gameStarted = true;
                  _save();
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: Text('${_currentGame!.players[0].name} 先攻', style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _currentGame!.firstPlayerIndex = 1;
                  _currentGame!.currentPlayerIndex = 1;
                  _currentGame!.turn = 1;
                  _currentGame!.gameStarted = true;
                  _save();
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: Text('${_currentGame!.players[1].name} 先攻', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消'))],
      ),
    );
  }

  void _switchGame(Game game) async {
    await _save();
    setState(() => _currentGame = game);
  }

  Future<void> _deleteGame(Game game) async {
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
        title: Text(game?.name ?? 'LP助手'),
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
      drawer: _buildDrawer(),
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

  Widget _buildDrawer() {
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Material(
              color: cs.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DrawerHeader(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('LP助手', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          _currentGame?.name ?? '未选择对局',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_circle),
                    title: const Text('新建对局'),
                    onTap: () {
                      Navigator.pop(context);
                      _createGame();
                    },
                  ),
                  const Divider(),
                ],
              ),
            ),
            Expanded(
              child: _games.isEmpty
                  ? const Center(child: Text('暂无对局', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                clipBehavior: Clip.hardEdge,
                      itemCount: _games.length,
                      itemBuilder: (context, index) {
                        final game = _games[index];
                        final isActive = _currentGame?.id == game.id;
                        final dateStr = '${game.createdAt.month}/${game.createdAt.day} ${game.createdAt.hour}:${game.createdAt.minute.toString().padLeft(2, '0')}';
                        return ListTile(
                          selected: isActive,
                          selectedTileColor: Colors.indigo.shade50,
                          title: Text(game.name, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                          leading: Icon(isActive ? Icons.games : Icons.games_outlined),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') _deleteGame(game);
                            },
                            itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('删除'))],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _switchGame(game);
                          },
                        );
                      },
                    ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('导出数据'),
              onTap: () { Navigator.pop(context); _exportData(); },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('导入数据'),
              onTap: () { Navigator.pop(context); _importData(); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('设置'),
              onTap: () { Navigator.pop(context); _openSettings(); },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('深色主题', style: TextStyle(fontSize: 14)),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (_) => LpApp.of(context)?.toggleTheme(),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('关于', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'LP助手 v1.0.1\n', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const TextSpan(text: '游戏王桌游辅助工具\n', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const TextSpan(text: 'Flutter 3.32 · Dart 3.8\n', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        TextSpan(text: '\n', style: TextStyle(fontSize: 4)),
                        const TextSpan(text: '本应用由 AI 辅助开发\n', style: TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w500)),
                        TextSpan(text: 'OpenCode + DeepSeek\n', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        TextSpan(text: '2026 LP Helper', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DiceDialog extends StatefulWidget {
  final List<Player> players;
  final ValueChanged<int> onConfirm;

  const _DiceDialog({required this.players, required this.onConfirm});

  @override
  State<_DiceDialog> createState() => _DiceDialogState();
}

class _DiceDialogState extends State<_DiceDialog> with TickerProviderStateMixin {
  int? _r1;
  int? _r2;
  String? _error;
  int? _animating; // 0 or 1 to indicate which player is animating
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000));
    _spinAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _roll(int playerIndex) {
    setState(() {
      _animating = playerIndex;
      _error = null;
    });
    _spinCtrl.forward(from: 0).then((_) {
      final r = (DateTime.now().microsecondsSinceEpoch % 6) + 1;
      setState(() {
        if (playerIndex == 0) _r1 = r;
        if (playerIndex == 1) _r2 = r;
        _animating = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('骰子决定先攻', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _dicePlayer(widget.players[0].name, _r1, _animating == 0, () => _roll(0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dicePlayer(widget.players[1].name, _r2, _animating == 1, () => _roll(1)),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        if (_r1 != null || _r2 != null)
          TextButton(
            onPressed: _animating == null ? () => setState(() { _r1 = null; _r2 = null; _error = null; }) : null,
            child: const Text('重来'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: (_r1 != null && _r2 != null && _animating == null) ? () {
            if (_r1 == _r2) {
              setState(() => _error = '点数相同，请重新投掷');
            } else {
              widget.onConfirm(_r1! > _r2! ? 0 : 1);
            }
          } : null,
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _dicePlayer(String name, int? result, bool isAnimating, VoidCallback onRoll) {
    return Column(
      children: [
        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: (_animating == null && _r1 == null) || (_animating == null && _r2 == null) ? onRoll : null,
          child: AnimatedBuilder(
            animation: _spinAnim,
            builder: (context, child) {
              final angle = (isAnimating ? _spinAnim.value * 2 * 3.14159 : 0).toDouble();
              return Transform.scale(
                scale: isAnimating ? 1.0 + 0.15 * (_spinAnim.value < 0.5 ? _spinAnim.value : 1 - _spinAnim.value) * 2 : 1.0,
                child: Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isAnimating
                          ? Colors.indigo.shade100
                          : (result != null ? Colors.indigo : Colors.grey.shade100),
                      border: Border.all(color: Colors.indigo.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isAnimating
                          ? [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 12)]
                          : null,
                    ),
                    child: Center(
                      child: isAnimating
                          ? Text(
                              '${(DateTime.now().microsecondsSinceEpoch % 6) + 1}',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.indigo),
                            )
                          : Text(
                              result != null ? '$result' : '?',
                              style: TextStyle(
                                fontSize: result != null ? 36 : 28,
                                fontWeight: FontWeight.bold,
                                color: result != null ? Colors.white : Colors.grey,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _animating == null && (
              (result == null && _r1 == null) || 
              (result == null && _r2 == null)
            ) ? onRoll : null,
          child: const Text('投掷'),
        ),
      ],
    );
  }
}

class _CoinDialog extends StatefulWidget {
  final List<Player> players;
  final ValueChanged<int> onConfirm;

  const _CoinDialog({required this.players, required this.onConfirm});

  @override
  State<_CoinDialog> createState() => _CoinDialogState();
}

class _CoinDialogState extends State<_CoinDialog> with TickerProviderStateMixin {
  int? _guessPlayer;
  String? _result;
  bool _isAnimating = false;
  late AnimationController _coinCtrl;

  @override
  void initState() {
    super.initState();
    _coinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 7500));
  }

  @override
  void dispose() {
    _coinCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() => _isAnimating = true);
    _coinCtrl.forward(from: 0).then((_) {
      final isHeads = DateTime.now().microsecondsSinceEpoch % 2 == 0;
      final pName = widget.players[_guessPlayer!].name;
      setState(() {
        _result = isHeads ? '$pName 抛得正面，先攻!' : '$pName 抛得反面，后攻';
        _isAnimating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('硬币决定先攻', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('选择一方抛硬币'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text(widget.players[0].name),
                selected: _guessPlayer == 0,
                onSelected: (_result == null && !_isAnimating) ? (_) => setState(() => _guessPlayer = 0) : null,
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: Text(widget.players[1].name),
                selected: _guessPlayer == 1,
                onSelected: (_result == null && !_isAnimating) ? (_) => setState(() => _guessPlayer = 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _coinCtrl,
            builder: (context, child) {
              final angle = _isAnimating ? _coinCtrl.value * 4 * pi : 0.0;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(angle),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAnimating
                        ? (_coinCtrl.value < 0.5 ? Colors.amber.shade400 : Colors.amber.shade600)
                        : (_result != null
                            ? (_result!.contains('正面') ? Colors.amber.shade300 : Colors.grey.shade400)
                            : Colors.amber.shade200),
                    border: Border.all(color: Colors.amber.shade700, width: 3),
                    boxShadow: _isAnimating
                        ? [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 16)]
                        : null,
                  ),
                  child: Center(
                    child: _isAnimating
                        ? Text(
                            _coinCtrl.value < 0.5 ? '正' : '反',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        : _result != null
                            ? Icon(
                                _result!.contains('正面') ? Icons.star : Icons.circle_outlined,
                                size: 36,
                                color: Colors.white,
                              )
                            : const Icon(Icons.token, size: 36, color: Colors.white),
                  ),
                ),
              );
            },
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            Text(_result!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
      actions: [
        if (_result != null || _guessPlayer != null)
          TextButton(
            onPressed: _isAnimating ? null : () => setState(() { _result = null; _guessPlayer = null; }),
            child: const Text('重来'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        if (_result == null)
          TextButton(
            onPressed: (_guessPlayer != null && !_isAnimating) ? _flip : null,
            child: const Text('抛硬币'),
          )
        else
          TextButton(
            onPressed: () {
              widget.onConfirm(_result!.contains('正面') ? _guessPlayer! : (1 - _guessPlayer!));
            },
            child: const Text('确定'),
          ),
      ],
    );
  }
}
