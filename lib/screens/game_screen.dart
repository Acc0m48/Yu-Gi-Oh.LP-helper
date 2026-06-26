import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/lp_history.dart';
import '../models/turn_record.dart';
import '../widgets/numeric_keypad.dart';

const _phases = ['抽卡阶段', '准备阶段', '主要阶段1', '战斗阶段', '主要阶段2', '结束阶段'];

class FeedItem {
  final DateTime timestamp;
  final int? playerIndex;
  final int? delta;
  final int? prevLp;
  final int? newLp;
  final int? turnNumber;
  final String? phase;
  final String? note;

  const FeedItem({
    required this.timestamp,
    this.playerIndex,
    this.delta,
    this.prevLp,
    this.newLp,
    this.turnNumber,
    this.phase,
    this.note,
  });
}

class GameScreen extends StatefulWidget {
  final List<Player> players;
  final int currentPlayerIndex;
  final int turn;
  final List<LpHistory> lpHistory;
  final List<TurnRecord> memos;
  final ValueChanged<int> onTurnChanged;
  final ValueChanged<int> onCurrentPlayerChanged;
  final VoidCallback onDataChanged;

  const GameScreen({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    required this.turn,
    required this.lpHistory,
    required this.memos,
    required this.onTurnChanged,
    required this.onCurrentPlayerChanged,
    required this.onDataChanged,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _selectedPlayerIndex = 0;
  String _selectedPhase = _phases[0];
  final Set<String> _selectedTags = {};
  final TextEditingController _memoCtrl = TextEditingController();

  List<String> get _presetTags => [
    widget.players[0].name,
    widget.players[1].name,
    '自肃',
    '效果',
    '召唤',
    '攻击',
    '连锁',
    '伤害',
    '特殊召唤',
    '区域位置',
  ];

  void _applyLpChange(int amount, bool isAdd) {
    setState(() {
      final player = widget.players[_selectedPlayerIndex];
      final prev = player.lp;
      if (isAdd) {
        player.lp += amount;
      } else {
        player.lp -= amount;
      }
      widget.lpHistory.add(LpHistory(
        playerIndex: _selectedPlayerIndex,
        previousLp: prev,
        newLp: player.lp,
      ));
    });
    widget.onDataChanged();
  }

  void _payHalf() {
    final half = (widget.players[_selectedPlayerIndex].lp / 2).ceil();
    _applyLpChange(half, false);
  }

  void _pay500() => _applyLpChange(500, false);
  void _pay1000() => _applyLpChange(1000, false);

  void _undo() {
    if (widget.lpHistory.isEmpty) return;
    setState(() {
      final last = widget.lpHistory.removeLast();
      widget.players[last.playerIndex].lp = last.previousLp;
    });
    widget.onDataChanged();
  }

  void _addMemo() {
    final raw = _memoCtrl.text.trim();
    if (raw.isEmpty) return;
    var note = raw;
    if (_selectedTags.isNotEmpty) {
      final tagsStr = _selectedTags.map((t) => '[$t]').join(' ');
      note = '$tagsStr $raw';
    }
    widget.memos.insert(0, TurnRecord(
      turnNumber: widget.turn,
      phase: _selectedPhase,
      note: note,
    ));
    _memoCtrl.clear();
    setState(() => _selectedTags.clear());
    widget.onDataChanged();
    setState(() {});
  }

  void _editMemo(TurnRecord record) {
    final ctrl = TextEditingController(text: record.note);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑记录'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '修改记录内容...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              record.note = ctrl.text.trim();
              widget.onDataChanged();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _openFieldDialog() {
    showDialog(
      context: context,
      builder: (_) => _FieldTagDialog(
        playerName: widget.players[widget.currentPlayerIndex].name,
        onConfirm: (text) {
          setState(() => _selectedTags.add(text));
        },
      ),
    );
  }

  void _openLpSheet(int playerIndex) {
    _selectedPlayerIndex = playerIndex;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _LpDialog(
        players: widget.players,
        playerIndex: playerIndex,
        lpHistory: widget.lpHistory,
        onApply: _applyLpChange,
        onPayHalf: _payHalf,
        onPay500: _pay500,
        onPay1000: _pay1000,
        onSelectPlayer: (i) {
          Navigator.pop(ctx);
          _openLpSheet(i);
        },
      ),
    );
  }

  void _rollDice() {
    showDialog(
      context: context,
      builder: (_) => _AnimatedDiceDialog(),
    );
  }

  void _flipCoin() {
    showDialog(
      context: context,
      builder: (_) => _AnimatedCoinDialog(),
    );
  }

  void _advanceTurn() {
    widget.onTurnChanged(widget.turn + 1);
    widget.onCurrentPlayerChanged(1 - widget.currentPlayerIndex);
  }

  void _retreatTurn() {
    if (widget.turn > 1) {
      widget.onTurnChanged(widget.turn - 1);
      widget.onCurrentPlayerChanged(1 - widget.currentPlayerIndex);
    }
  }

  List<FeedItem> _buildFeed() {
    final items = <FeedItem>[];
    for (final m in widget.memos) {
      items.add(FeedItem(
        timestamp: m.timestamp,
        turnNumber: m.turnNumber,
        phase: m.phase,
        note: m.note,
      ));
    }
    for (final h in widget.lpHistory) {
      items.add(FeedItem(
        timestamp: h.timestamp,
        playerIndex: h.playerIndex,
        delta: h.delta,
        prevLp: h.previousLp,
        newLp: h.newLp,
      ));
    }
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final feed = _buildFeed();
    final cp = widget.players[widget.currentPlayerIndex];
    return Column(
      children: [
        _buildTurnBar(cp),
        _buildDualPlayer(),
        if (widget.lpHistory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _undo,
                  icon: const Icon(Icons.undo, size: 16),
                  label: Text('撤销 (${widget.lpHistory.length})', style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            children: _phases.map((p) => ChoiceChip(
              label: Text(p, style: const TextStyle(fontSize: 11)),
              selected: _selectedPhase == p,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() => _selectedPhase = p),
            )).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            children: _presetTags.map((tag) {
              final isFieldTag = tag == '区域位置';
              return InputChip(
                avatar: isFieldTag ? const Icon(Icons.grid_view, size: 14) : null,
                label: Text(tag, style: TextStyle(
                  fontSize: 11,
                  fontWeight: isFieldTag ? FontWeight.bold : FontWeight.normal,
                )),
                selected: _selectedTags.contains(tag),
                visualDensity: VisualDensity.compact,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
                backgroundColor: isFieldTag ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : null,
                side: isFieldTag ? BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)) : null,
              onSelected: (v) {
                if (v) {
                  if (tag == '区域位置') {
                    if (_selectedTags.contains(tag)) {
                      _openFieldDialog();
                    } else {
                      _openFieldDialog();
                    }
                    return;
                  }
                  setState(() => _selectedTags.add(tag));
                } else {
                  if (tag == '区域位置') {
                    setState(() => _selectedTags.removeWhere((t) => t.startsWith(widget.players[0].name) || t.startsWith(widget.players[1].name) || tag == t));
                  } else {
                    setState(() => _selectedTags.remove(tag));
                  }
                }
              },
            );
          }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              _toolBtn(Icons.casino, '骰子', Theme.of(context).colorScheme.tertiary, _rollDice),
              const SizedBox(width: 8),
              _toolBtn(Icons.token, '硬币', Theme.of(context).colorScheme.secondary, _flipCoin),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              if (_selectedTags.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: _selectedTags.map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _selectedTags.remove(t)),
                    )).toList(),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _memoCtrl,
                      decoration: const InputDecoration(
                        hintText: '记录事件...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      ),
                      onSubmitted: (_) => _addMemo(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.send, size: 22),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _addMemo,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _buildFeedList(feed)),
      ],
    );
  }

  Widget _buildTurnBar(Player cp) {
    final otherPi = 1 - widget.currentPlayerIndex;
    final otherName = widget.players[otherPi].name;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconBtn(Icons.skip_previous, Colors.orange, _retreatTurn),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cp.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '第${widget.turn}回合',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 12),
          _iconBtn(Icons.skip_next, Colors.green, _advanceTurn),
          const SizedBox(width: 20),
          Column(
            children: [
              Text('▶ $otherName', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              const SizedBox(height: 4),
              Text('等待中', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))),
            ],
          ),
          const SizedBox(width: 8),
          _iconBtn(Icons.refresh, Colors.red, () {
            widget.onTurnChanged(1);
            widget.onCurrentPlayerChanged(0);
          }),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildDualPlayer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(child: _playerCard(0)),
          const SizedBox(width: 8),
          Expanded(child: _playerCard(1)),
        ],
      ),
    );
  }

  Widget _playerCard(int index) {
    final player = widget.players[index];
    final isCurrent = index == widget.currentPlayerIndex;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _openLpSheet(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isCurrent ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? cs.primary : cs.outline,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? cs.primary : cs.onSurface,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('当前', style: TextStyle(fontSize: 10, color: cs.onPrimary)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${player.lp}',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: player.lp > 0 ? Colors.green : Colors.red,
              ),
            ),
            Text('LP', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.3))),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedList(List<FeedItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无记录', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final time = '${item.timestamp.hour.toString().padLeft(2, '0')}:'
            '${item.timestamp.minute.toString().padLeft(2, '0')}';
        if (item.playerIndex != null) {
          final p = widget.players[item.playerIndex!];
          final sign = item.delta! >= 0 ? '+' : '';
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            color: item.delta! >= 0 ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: item.delta! >= 0 ? Colors.green : Colors.red,
                child: Text('$sign${item.delta}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text('${item.prevLp} → ${item.newLp}  $time', style: const TextStyle(fontSize: 11)),
            ),
          );
        }
        // Memo item
        final memo = widget.memos.firstWhere(
          (m) => m.timestamp == item.timestamp && m.note == item.note,
          orElse: () => TurnRecord(turnNumber: 0, note: ''),
        );
        if (memo.turnNumber == 0) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${item.turnNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            title: Text(item.note!, style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              item.phase!.isNotEmpty ? '回合${item.turnNumber} · ${item.phase} · $time' : '回合${item.turnNumber} · $time',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: () => _editMemo(memo),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: () {
                    widget.memos.removeWhere((m) => m.timestamp == item.timestamp && m.note == item.note);
                    widget.onDataChanged();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// === Animated Dice Dialog ===
class _AnimatedDiceDialog extends StatefulWidget {
  @override
  State<_AnimatedDiceDialog> createState() => _AnimatedDiceDialogState();
}

class _AnimatedDiceDialogState extends State<_AnimatedDiceDialog> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  int? _result;
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _roll() {
    setState(() => _rolling = true);
    _ctrl.forward(from: 0).then((_) {
      setState(() {
        _result = (DateTime.now().microsecondsSinceEpoch % 6) + 1;
        _rolling = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('骰子', textAlign: TextAlign.center),
      content: SizedBox(
        height: 100,
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Transform.scale(
              scale: _rolling ? 1.0 + 0.2 * (_ctrl.value < 0.5 ? _ctrl.value * 2 : 2 - _ctrl.value * 2) : 1.0,
              child: Text(
                _rolling ? '${(DateTime.now().microsecondsSinceEpoch % 6) + 1}' : '${_result ?? '?'}',
                style: TextStyle(
                  fontSize: _result != null ? 56 : 48,
                  fontWeight: FontWeight.bold,
                  color: _result != null ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _rolling ? null : _roll, child: const Text('投掷')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
      ],
    );
  }
}

// === Animated Coin Dialog ===
class _AnimatedCoinDialog extends StatefulWidget {
  @override
  State<_AnimatedCoinDialog> createState() => _AnimatedCoinDialogState();
}

class _AnimatedCoinDialogState extends State<_AnimatedCoinDialog> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  String? _result;
  bool _flipping = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() => _flipping = true);
    _ctrl.forward(from: 0).then((_) {
      setState(() {
        _result = DateTime.now().microsecondsSinceEpoch % 2 == 0 ? '正面' : '反面';
        _flipping = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('硬币', textAlign: TextAlign.center),
      content: SizedBox(
        height: 120,
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) {
              final angle = _flipping ? _ctrl.value * 4 * pi : 0.0;
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
                    color: _result != null
                        ? (_result == '正面' ? Colors.amber.shade300 : Colors.grey.shade400)
                        : Colors.amber.shade200,
                    border: Border.all(color: Colors.amber.shade700, width: 3),
                  ),
                  child: Center(
                    child: _result != null
                        ? Icon(
                            _result == '正面' ? Icons.star : Icons.circle_outlined,
                            size: 36,
                            color: Colors.white,
                          )
                        : const Icon(Icons.token, size: 36, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _flipping ? null : _flip, child: const Text('抛硬币')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
      ],
    );
  }
}

// === LP Bottom Sheet Dialog ===
class _LpDialog extends StatefulWidget {
  final List<Player> players;
  final int playerIndex;
  final List<LpHistory> lpHistory;
  final void Function(int amount, bool isAdd) onApply;
  final VoidCallback onPayHalf;
  final VoidCallback onPay500;
  final VoidCallback onPay1000;
  final ValueChanged<int> onSelectPlayer;

  const _LpDialog({
    required this.players,
    required this.playerIndex,
    required this.lpHistory,
    required this.onApply,
    required this.onPayHalf,
    required this.onPay500,
    required this.onPay1000,
    required this.onSelectPlayer,
  });

  @override
  State<_LpDialog> createState() => _LpDialogState();
}

class _LpDialogState extends State<_LpDialog> {
  String _buffer = '';
  bool _isAdd = true;

  void _onInput(String v) {
    if (_buffer.length < 6) setState(() => _buffer += v);
  }

  void _apply() {
    final amount = int.tryParse(_buffer) ?? 0;
    if (amount == 0) return;
    widget.onApply(amount, _isAdd);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: _playerChip(0)),
                  const SizedBox(width: 8),
                  Expanded(child: _playerChip(1)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(_isAdd ? '+' : '-', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _isAdd ? Colors.green : Colors.blue)),
                  const Spacer(),
                  Text(_buffer.isEmpty ? '0' : _buffer, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _smallBtn('一半', Colors.orange, () { widget.onPayHalf(); Navigator.pop(context); }),
                _smallBtn('500', Colors.deepOrange, () { widget.onPay500(); Navigator.pop(context); }),
                _smallBtn('1000', Colors.red, () { widget.onPay1000(); Navigator.pop(context); }),
              ],
            ),
            NumericKeypad(
              onInput: _onInput,
              onAdd: () { _isAdd = true; _apply(); },
              onSubtract: () { _isAdd = false; _apply(); },
              onDelete: () { if (_buffer.isNotEmpty) setState(() => _buffer = _buffer.substring(0, _buffer.length - 1)); },
              onClear: () => setState(() => _buffer = ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerChip(int index) {
    final p = widget.players[index];
    final sel = index == widget.playerIndex;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => widget.onSelectPlayer(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: sel ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? cs.primary : cs.outline, width: sel ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(p.name, style: const TextStyle(fontSize: 13)),
            Text('${p.lp}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: p.lp > 0 ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _smallBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}

// === Field Zone Selection Dialog ===
class _FieldTagDialog extends StatefulWidget {
  final String playerName;
  final ValueChanged<String> onConfirm;

  const _FieldTagDialog({required this.playerName, required this.onConfirm});

  @override
  State<_FieldTagDialog> createState() => _FieldTagDialogState();
}

class _FieldTagDialogState extends State<_FieldTagDialog> {
  String _text = '';
  final _ctrl = TextEditingController();

  final _zones = {
    '额外怪兽区': ['左', '右'],
    '主要怪兽区': ['1', '2', '3', '4', '5'],
    '魔法·陷阱区': ['1', '2', '3', '4', '5'],
    '场地区': [''],
    '墓地': [''],
    '额外卡组': [''],
    '卡组': [''],
    '手牌': [''],
    '除外状态': [''],
  };

  void _tapZone(String zone, String pos) {
    final label = pos.isEmpty ? zone : '$zone$pos';
    setState(() {
      if (_text.isEmpty) {
        _text = label;
      } else {
        _text += '、$label';
      }
    });
    _ctrl.text = '$widget.playerName的$zone$pos';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('选择区域位置', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Extra Monster Zone
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _zoneBox('额外怪兽区', '左', '额外怪兽区 左', cs.primary),
                const SizedBox(width: 8),
                _zoneBox('额外怪兽区', '右', '额外怪兽区 右', cs.primary),
              ],
            ),
            const SizedBox(height: 6),
            // Main Monster Zone (row of 5)
            Row(
              children: List.generate(5, (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
                  child: _zoneBox('主要怪兽区', '${i + 1}', '怪兽${i + 1}', cs.secondary),
                ),
              )),
            ),
            const SizedBox(height: 6),
            // Spell/Trap Zone (row of 5)
            Row(
              children: List.generate(5, (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
                  child: _zoneBox('魔法·陷阱区', '${i + 1}', '魔陷${i + 1}', _isPendulum(i) ? Colors.purple.shade300 : cs.tertiary),
                ),
              )),
            ),
            const SizedBox(height: 6),
            // Other zones
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _zoneBox('场地区', '', '场地区', Colors.green.shade300),
                _zoneBox('额外卡组', '', '额外卡组', Colors.orange.shade300),
                _zoneBox('卡组', '', '卡组', Colors.blueGrey.shade300),
                _zoneBox('墓地', '', '墓地', Colors.grey.shade400),
                _zoneBox('手牌', '', '手牌', Colors.amber.shade200),
                _zoneBox('除外状态', '', '除外状态', Colors.red.shade200),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                labelText: '位置描述',
                hintText: '${widget.playerName}的...',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () { _ctrl.clear(); setState(() => _text = ''); }, child: const Text('清空')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            if (_ctrl.text.trim().isNotEmpty) {
              widget.onConfirm(_ctrl.text.trim());
              Navigator.pop(context);
            }
          },
          child: const Text('确认'),
        ),
      ],
    );
  }

  bool _isPendulum(int i) => i == 0 || i == 4;

  Widget _zoneBox(String zoneName, String pos, String display, Color color) {
    final isFieldOrGrave = zoneName.length > 3 && !zoneName.contains(RegExp(r'\d'));
    return GestureDetector(
      onTap: () => _tapZone(zoneName, pos),
      child: Container(
        width: isFieldOrGrave ? null : double.infinity,
        constraints: BoxConstraints(
          minWidth: isFieldOrGrave ? 60 : 0,
          minHeight: 40,
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Center(
          child: Text(display, style: TextStyle(fontSize: 10, color: color.computeLuminance() > 0.6 ? Colors.black87 : color)),
        ),
      ),
    );
  }
}
