import 'package:flutter/material.dart';
import '../services/game_storage.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSaved;

  const SettingsPage({super.key, required this.settings, required this.onSaved});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _lpCtrl;
  late TextEditingController _p1Ctrl;
  late TextEditingController _p2Ctrl;
  late TextEditingController _dirCtrl;

  @override
  void initState() {
    super.initState();
    _lpCtrl = TextEditingController(text: '${widget.settings.defaultLp}');
    _p1Ctrl = TextEditingController(text: widget.settings.defaultP1Name);
    _p2Ctrl = TextEditingController(text: widget.settings.defaultP2Name);
    _dirCtrl = TextEditingController(text: widget.settings.exportDir);
  }

  @override
  void dispose() {
    _lpCtrl.dispose();
    _p1Ctrl.dispose();
    _p2Ctrl.dispose();
    _dirCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.settings.defaultLp = int.tryParse(_lpCtrl.text) ?? 8000;
    widget.settings.defaultP1Name = _p1Ctrl.text.trim().isEmpty ? '依' : _p1Ctrl.text.trim();
    widget.settings.defaultP2Name = _p2Ctrl.text.trim().isEmpty ? '尔' : _p2Ctrl.text.trim();
    widget.settings.exportDir = _dirCtrl.text.trim();
    await GameStorage.saveSettings(widget.settings);
    widget.onSaved(widget.settings);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _lpCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '默认初始LP', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(controller: _p1Ctrl, decoration: const InputDecoration(labelText: '默认玩家1名', border: OutlineInputBorder()))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _p2Ctrl, decoration: const InputDecoration(labelText: '默认玩家2名', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dirCtrl,
            decoration: const InputDecoration(labelText: '导出目录（留空=剪贴板）', hintText: '/storage/emulated/0/Download', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('保存设置'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
        ],
      ),
    );
  }
}
