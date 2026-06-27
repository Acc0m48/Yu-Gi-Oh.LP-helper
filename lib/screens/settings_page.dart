import 'package:flutter/material.dart';
import '../services/game_storage.dart';
import '../theme.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSaved;
  final ValueChanged<int> onThemeChanged;

  const SettingsPage({super.key, required this.settings, required this.onSaved, required this.onThemeChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _lpCtrl;
  late TextEditingController _p1Ctrl;
  late TextEditingController _p2Ctrl;
  late TextEditingController _dirCtrl;
  late int _themeIndex;

  @override
  void initState() {
    super.initState();
    _lpCtrl = TextEditingController(text: '${widget.settings.defaultLp}');
    _p1Ctrl = TextEditingController(text: widget.settings.defaultP1Name);
    _p2Ctrl = TextEditingController(text: widget.settings.defaultP2Name);
    _dirCtrl = TextEditingController(text: widget.settings.exportDir);
    _themeIndex = widget.settings.themeIndex;
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
    widget.settings.themeIndex = _themeIndex;
    await GameStorage.saveSettings(widget.settings);
    widget.onThemeChanged(_themeIndex);
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
          const SizedBox(height: 24),
          const Text('色系', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length,
              itemBuilder: (_, i) {
                final p = presets[i];
                final sel = i == _themeIndex;
                return GestureDetector(
                  onTap: () => setState(() => _themeIndex = i),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? Theme.of(context).colorScheme.primary : Colors.grey.shade300, width: sel ? 2.5 : 1),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            children: List.generate(4, (j) => Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: p.previewColors[j],
                                  borderRadius: j == 0
                                      ? const BorderRadius.vertical(top: Radius.circular(9))
                                      : j == 3
                                          ? const BorderRadius.vertical(bottom: Radius.circular(9))
                                          : null,
                                ),
                              ),
                            )),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: sel ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                          ),
                          child: Text(p.name, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
