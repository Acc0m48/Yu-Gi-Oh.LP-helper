import 'package:flutter/material.dart';
import '../services/game_storage.dart';
import '../theme.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSaved;
  final ValueChanged<AppSettings> onThemeChanged;

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
  late int _brightnessMode;
  late TextEditingController _cLightSeed, _cLightBg, _cDarkSeed, _cDarkBg, _cLpPos, _cLpNeg;

  @override
  void initState() {
    super.initState();
    _lpCtrl = TextEditingController(text: '${widget.settings.defaultLp}');
    _p1Ctrl = TextEditingController(text: widget.settings.defaultP1Name);
    _p2Ctrl = TextEditingController(text: widget.settings.defaultP2Name);
    _dirCtrl = TextEditingController(text: widget.settings.exportDir);
    _themeIndex = widget.settings.themeIndex;
    _brightnessMode = widget.settings.brightnessMode;
    _cLightSeed = TextEditingController(text: '${widget.settings.cLightSeed.toRadixString(16).padLeft(8, '0').toUpperCase()}');
    _cLightBg = TextEditingController(text: '${widget.settings.cLightBg.toRadixString(16).padLeft(8, '0').toUpperCase()}');
    _cDarkSeed = TextEditingController(text: '${widget.settings.cDarkSeed.toRadixString(16).padLeft(8, '0').toUpperCase()}');
    _cDarkBg = TextEditingController(text: '${widget.settings.cDarkBg.toRadixString(16).padLeft(8, '0').toUpperCase()}');
    _cLpPos = TextEditingController(text: '${widget.settings.cLpPos.toRadixString(16).padLeft(8, '0').toUpperCase()}');
    _cLpNeg = TextEditingController(text: '${widget.settings.cLpNeg.toRadixString(16).padLeft(8, '0').toUpperCase()}');
  }

  @override
  void dispose() {
    _lpCtrl.dispose(); _p1Ctrl.dispose(); _p2Ctrl.dispose(); _dirCtrl.dispose();
    _cLightSeed.dispose(); _cLightBg.dispose(); _cDarkSeed.dispose(); _cDarkBg.dispose();
    _cLpPos.dispose(); _cLpNeg.dispose();
    super.dispose();
  }

  int _parseHex(String s) => int.tryParse(s.replaceAll('#', '').replaceAll('0x', ''), radix: 16) ?? 0xFF000000;

  void _applyTheme() {
    widget.settings.themeIndex = _themeIndex;
    widget.settings.brightnessMode = _brightnessMode;
    if (_themeIndex >= presets.length) {
      widget.settings.cLightSeed = _parseHex(_cLightSeed.text);
      widget.settings.cLightBg = _parseHex(_cLightBg.text);
      widget.settings.cDarkSeed = _parseHex(_cDarkSeed.text);
      widget.settings.cDarkBg = _parseHex(_cDarkBg.text);
      widget.settings.cLpPos = _parseHex(_cLpPos.text);
      widget.settings.cLpNeg = _parseHex(_cLpNeg.text);
    }
    GameStorage.saveSettings(widget.settings);
    widget.onThemeChanged(widget.settings);
  }

  Future<void> _save() async {
    widget.settings.defaultLp = int.tryParse(_lpCtrl.text) ?? 8000;
    widget.settings.defaultP1Name = _p1Ctrl.text.trim().isEmpty ? '依' : _p1Ctrl.text.trim();
    widget.settings.defaultP2Name = _p2Ctrl.text.trim().isEmpty ? '尔' : _p2Ctrl.text.trim();
    widget.settings.exportDir = _dirCtrl.text.trim();
    _applyTheme();
    widget.onSaved(widget.settings);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = _themeIndex >= presets.length;
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _lpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '默认初始LP', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: _p1Ctrl, decoration: const InputDecoration(labelText: '默认玩家1名', border: OutlineInputBorder()))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _p2Ctrl, decoration: const InputDecoration(labelText: '默认玩家2名', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 16),
          TextField(controller: _dirCtrl, decoration: const InputDecoration(labelText: '导出目录（留空=剪贴板）', hintText: '/storage/emulated/0/Download', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          Row(children: [
            const Text('色系', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('自动', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: 1, label: Icon(Icons.light_mode, size: 16)),
                ButtonSegment(value: 2, label: Icon(Icons.dark_mode, size: 16)),
              ],
              selected: {_brightnessMode},
              onSelectionChanged: (v) => setState(() { _brightnessMode = v.first; _applyTheme(); }),
              style: ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length + 1,
              itemBuilder: (_, i) {
                final isSel = i == _themeIndex;
                final p = i < presets.length ? presets[i] : customPresetFrom(
                  lightSeed: _parseHex(_cLightSeed.text), lightBg: _parseHex(_cLightBg.text),
                  darkSeed: _parseHex(_cDarkSeed.text), darkBg: _parseHex(_cDarkBg.text),
                  lpPos: _parseHex(_cLpPos.text), lpNeg: _parseHex(_cLpNeg.text),
                );
                final colors = i < presets.length ? p.previewColors : [Color(_parseHex(_cLightBg.text)), Color(_parseHex(_cLightSeed.text)), Color(_parseHex(_cDarkSeed.text)), Color(_parseHex(_cDarkBg.text))];
                return GestureDetector(
                  onTap: () => setState(() { _themeIndex = i; _applyTheme(); }),
                  child: Container(
                    width: 80, margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? Theme.of(context).colorScheme.primary : Colors.grey.shade300, width: isSel ? 2.5 : 1)),
                    child: Column(children: [
                      Expanded(child: Column(children: List.generate(4, (j) => Expanded(child: Container(decoration: BoxDecoration(color: colors[j], borderRadius: j == 0 ? const BorderRadius.vertical(top: Radius.circular(9)) : j == 3 ? const BorderRadius.vertical(bottom: Radius.circular(9)) : null))))),),
                      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: isSel ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade100, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9))), child: Text(p.name, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal))),
                    ]),
                  ),
                );
              },
            ),
          ),
          if (isCustom) ...[
            const SizedBox(height: 16),
            const Text('自定义颜色 (ARGB十六进制)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _hexField(_cLightBg, '浅色背景')),
              const SizedBox(width: 8),
              Expanded(child: _hexField(_cLightSeed, '浅色主调')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _hexField(_cDarkBg, '深色背景')),
              const SizedBox(width: 8),
              Expanded(child: _hexField(_cDarkSeed, '深色主调')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _hexField(_cLpPos, 'LP增加色')),
              const SizedBox(width: 8),
              Expanded(child: _hexField(_cLpNeg, 'LP扣减色')),
            ]),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => setState(() => _applyTheme()), child: const Text('预览自定义')),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('保存设置'), style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48))),
        ],
      ),
    );
  }

  Widget _hexField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, hintText: 'FFD96C4A', border: const OutlineInputBorder(), isDense: true, prefixText: '#'),
      onChanged: (_) => setState(() {}),
    );
  }
}
