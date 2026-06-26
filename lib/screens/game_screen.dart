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
  final TextEditingController _memoCtrl = TextEditingController();

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
    final note = _memoCtrl.text.trim();
    if (note.isEmpty) return;
    widget.memos.insert(0, TurnRecord(
      turnNumber: widget.turn,
      phase: _selectedPhase,
      note: note,
    ));
    _memoCtrl.clear();
    widget.onDataChanged();
    setState(() {});
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
    final r = (DateTime.now().microsecondsSinceEpoch % 6) + 1;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎲 骰子', textAlign: TextAlign.center),
        content: SizedBox(
          height: 80,
          child: Center(
            child: Text('$r', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定'))],
      ),
    );
  }

  void _flipCoin() {
    final r = DateTime.now().microsecondsSinceEpoch % 2 == 0 ? '正面' : '反面';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🪙 硬币', textAlign: TextAlign.center),
        content: SizedBox(
          height: 80,
          child: Center(
            child: Text(r, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定'))],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Wrap(
            spacing: 6,
            children: _phases.map((p) => ChoiceChip(
              label: Text(p, style: const TextStyle(fontSize: 11)),
              selected: _selectedPhase == p,
              selectedColor: Colors.indigo.shade100,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() => _selectedPhase = p),
            )).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _toolBtn(Icons.casino, '骰子', Colors.purple, _rollDice),
              const SizedBox(width: 12),
              _toolBtn(Icons.token, '硬币', Colors.amber.shade700, _flipCoin),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
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
                color: Colors.blue,
                onPressed: _addMemo,
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
        color: Colors.indigo.shade50,
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
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cp.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
              Text('▶ $otherName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                '等待中',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
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
          foregroundColor: Colors.white,
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
    return GestureDetector(
      onTap: () => _openLpSheet(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isCurrent ? Colors.indigo.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? Colors.indigo : Colors.grey.shade300,
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
                    color: isCurrent ? Colors.indigo : Colors.grey.shade700,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('当前', style: TextStyle(fontSize: 10, color: Colors.white)),
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
            Text('LP', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
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
            color: item.delta! >= 0 ? Colors.green.shade50 : Colors.red.shade50,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: item.delta! >= 0 ? Colors.green : Colors.red,
                child: Text('$sign${item.delta}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(
                p.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${item.prevLp} → ${item.newLp}  $time',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          );
        } else {
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.indigo.shade100,
                child: Text('${item.turnNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              title: Text(item.note!, style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                item.phase!.isNotEmpty ? '回合${item.turnNumber} · ${item.phase} · $time' : '回合${item.turnNumber} · $time',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                onPressed: () {
                  widget.memos.removeWhere((m) =>
                      m.timestamp == item.timestamp && m.note == item.note);
                  widget.onDataChanged();
                  setState(() {});
                },
              ),
            ),
          );
        }
      },
    );
  }
}

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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onSelectPlayer(0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.playerIndex == 0 ? Colors.indigo.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.playerIndex == 0 ? Colors.indigo : Colors.grey.shade300,
                            width: widget.playerIndex == 0 ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(widget.players[0].name, style: const TextStyle(fontSize: 13)),
                            Text('${widget.players[0].lp}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.players[0].lp > 0 ? Colors.green : Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onSelectPlayer(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.playerIndex == 1 ? Colors.indigo.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.playerIndex == 1 ? Colors.indigo : Colors.grey.shade300,
                            width: widget.playerIndex == 1 ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(widget.players[1].name, style: const TextStyle(fontSize: 13)),
                            Text('${widget.players[1].lp}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.players[1].lp > 0 ? Colors.green : Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
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
