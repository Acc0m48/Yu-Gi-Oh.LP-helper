import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedDiceDialog extends StatefulWidget {
  const AnimatedDiceDialog({super.key});

  @override
  State<AnimatedDiceDialog> createState() => _AnimatedDiceDialogState();
}

class _AnimatedDiceDialogState extends State<AnimatedDiceDialog>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  int? _result;
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _roll() {
    setState(() => _rolling = true);
    _ctrl.forward(from: 0).then((_) => setState(() {
          _result = (DateTime.now().microsecondsSinceEpoch % 6) + 1;
          _rolling = false;
        }));
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
              scale: _rolling
                  ? 1.0 +
                      0.2 *
                          (_ctrl.value < 0.5
                              ? _ctrl.value * 2
                              : 2 - _ctrl.value * 2)
                  : 1.0,
              child: Text(
                _rolling
                    ? '${(DateTime.now().microsecondsSinceEpoch % 6) + 1}'
                    : '${_result ?? '?'}',
                style: TextStyle(
                  fontSize: _result != null ? 56 : 48,
                  fontWeight: FontWeight.bold,
                  color: _result != null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _rolling ? null : _roll, child: const Text('投掷')),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭')),
      ],
    );
  }
}

class AnimatedCoinDialog extends StatefulWidget {
  const AnimatedCoinDialog({super.key});

  @override
  State<AnimatedCoinDialog> createState() => _AnimatedCoinDialogState();
}

class _AnimatedCoinDialogState extends State<AnimatedCoinDialog>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  String? _result;
  bool _flipping = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() => _flipping = true);
    _ctrl.forward(from: 0).then((_) => setState(() {
          _result = DateTime.now().microsecondsSinceEpoch % 2 == 0
              ? '正面'
              : '反面';
          _flipping = false;
        }));
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
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_flipping ? _ctrl.value * 4 * pi : 0.0),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _result != null
                        ? (_result == '正面'
                            ? Colors.amber.shade300
                            : Colors.grey.shade400)
                        : Colors.amber.shade200,
                    border:
                        Border.all(color: Colors.amber.shade700, width: 3),
                  ),
                  child: Center(
                    child: _result != null
                        ? Icon(
                            _result == '正面'
                                ? Icons.star
                                : Icons.circle_outlined,
                            size: 36,
                            color: Colors.white,
                          )
                        : const Icon(Icons.token,
                            size: 36, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _flipping ? null : _flip,
            child: const Text('抛硬币')),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭')),
      ],
    );
  }
}
