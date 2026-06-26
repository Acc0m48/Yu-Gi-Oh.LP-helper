import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final void Function(String) onInput;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const NumericKeypad({
    super.key,
    required this.onInput,
    required this.onAdd,
    required this.onSubtract,
    required this.onDelete,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(children: ['7', '8', '9'].map((v) => Expanded(child: _keyButton(v))).toList()),
          Row(children: ['4', '5', '6'].map((v) => Expanded(child: _keyButton(v))).toList()),
          Row(children: ['1', '2', '3'].map((v) => Expanded(child: _keyButton(v))).toList()),
          Row(
            children: [
              Expanded(child: _keyButton('0')),
              Expanded(child: _keyButton('00')),
              Expanded(child: _operationButton('-', onSubtract)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _operationButton('+', onAdd)),
              Expanded(child: _actionButton('删除', Colors.orange, onDelete)),
              Expanded(child: _actionButton('清零', Colors.red, onClear)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyButton(String label) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () => onInput(label),
          style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  Widget _operationButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: label == '+' ? Colors.green : Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
