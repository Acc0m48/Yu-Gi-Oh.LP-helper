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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9']
              .map((v) => _keyButton(v))
              .toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6']
              .map((v) => _keyButton(v))
              .toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3']
              .map((v) => _keyButton(v))
              .toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _keyButton('0'),
            _keyButton('00'),
            _operationButton('-', onSubtract),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _operationButton('+', onAdd),
            _actionButton('删除', Colors.orange, onDelete),
            _actionButton('清零', Colors.red, onClear),
          ],
        ),
      ],
    );
  }

  Widget _keyButton(String label) {
    return SizedBox(
      width: 70,
      height: 56,
      child: ElevatedButton(
        onPressed: () => onInput(label),
        child: Text(label, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _operationButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: 70,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: label == '+' ? Colors.green : Colors.blue,
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 70,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
