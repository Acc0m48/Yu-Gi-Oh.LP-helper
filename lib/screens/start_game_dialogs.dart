import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';

class DiceDialog extends StatefulWidget {
  final List<Player> players;
  final ValueChanged<int> onConfirm;

  const DiceDialog({super.key, required this.players, required this.onConfirm});

  @override
  State<DiceDialog> createState() => _DiceDialogState();
}

class _DiceDialogState extends State<DiceDialog> with TickerProviderStateMixin {
  int? _r1;
  int? _r2;
  String? _error;
  int? _animating;
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

class CoinDialog extends StatefulWidget {
  final List<Player> players;
  final ValueChanged<int> onConfirm;

  const CoinDialog({super.key, required this.players, required this.onConfirm});

  @override
  State<CoinDialog> createState() => _CoinDialogState();
}

class _CoinDialogState extends State<CoinDialog> with TickerProviderStateMixin {
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

class StartGameDialogs {
  static Widget _startOption(BuildContext ctx, String title, IconData icon, String desc, VoidCallback onTap) {
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

  static void showDiceDialog(
    BuildContext context, {
    required List<Player> players,
    required ValueChanged<int> onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => DiceDialog(
        players: players,
        onConfirm: (firstPlayerIndex) {
          Navigator.pop(ctx);
          onConfirm(firstPlayerIndex);
        },
      ),
    );
  }

  static void showCoinDialog(
    BuildContext context, {
    required List<Player> players,
    required ValueChanged<int> onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => CoinDialog(
        players: players,
        onConfirm: (firstPlayerIndex) {
          Navigator.pop(ctx);
          onConfirm(firstPlayerIndex);
        },
      ),
    );
  }

  static void showCustomDialog(
    BuildContext context, {
    required List<Player> players,
    required ValueChanged<int> onConfirm,
  }) {
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
                  Navigator.pop(ctx);
                  onConfirm(0);
                },
                child: Text('${players[0].name} 先攻', style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onConfirm(1);
                },
                child: Text('${players[1].name} 先攻', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消'))],
      ),
    );
  }

  static void showStartGameDialog(
    BuildContext context, {
    required List<Player> players,
    required ValueChanged<int> onFirstPlayerSelected,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('决定先攻', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _startOption(ctx, '骰子', Icons.casino, '双方各掷一次骰子，点数大者先攻', () {
              Navigator.pop(ctx);
              showDiceDialog(context, players: players, onConfirm: onFirstPlayerSelected);
            }),
            const SizedBox(height: 8),
            _startOption(ctx, '硬币', Icons.token, '选择一方抛硬币，猜正/反面', () {
              Navigator.pop(ctx);
              showCoinDialog(context, players: players, onConfirm: onFirstPlayerSelected);
            }),
            const SizedBox(height: 8),
            _startOption(ctx, '自定', Icons.touch_app, '手动选择先攻玩家', () {
              Navigator.pop(ctx);
              showCustomDialog(context, players: players, onConfirm: onFirstPlayerSelected);
            }),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消'))],
      ),
    );
  }
}
