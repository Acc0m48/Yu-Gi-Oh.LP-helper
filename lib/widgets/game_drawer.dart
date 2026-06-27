import 'package:flutter/material.dart';
import '../models/game.dart';

class GameDrawer extends StatelessWidget {
  final Game? currentGame;
  final List<Game> games;
  final VoidCallback onCreateGame;
  final ValueChanged<Game> onSwitchGame;
  final ValueChanged<Game> onDeleteGame;
  final VoidCallback onExportData;
  final VoidCallback onImportData;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleTheme;

  const GameDrawer({
    super.key,
    required this.currentGame,
    required this.games,
    required this.onCreateGame,
    required this.onSwitchGame,
    required this.onDeleteGame,
    required this.onExportData,
    required this.onImportData,
    required this.onOpenSettings,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
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
                          currentGame?.name ?? '未选择对局',
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
                      onCreateGame();
                    },
                  ),
                  const Divider(),
                ],
              ),
            ),
            Expanded(
              child: games.isEmpty
                  ? const Center(child: Text('暂无对局', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                clipBehavior: Clip.hardEdge,
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        final isActive = currentGame?.id == game.id;
                        final dateStr = '${game.createdAt.month}/${game.createdAt.day} ${game.createdAt.hour}:${game.createdAt.minute.toString().padLeft(2, '0')}';
                        return ListTile(
                          selected: isActive,
                          selectedTileColor: Colors.indigo.shade50,
                          title: Text(game.name, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                          leading: Icon(isActive ? Icons.games : Icons.games_outlined),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') onDeleteGame(game);
                            },
                            itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('删除'))],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            onSwitchGame(game);
                          },
                        );
                      },
                    ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('导出数据'),
              onTap: () { Navigator.pop(context); onExportData(); },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('导入数据'),
              onTap: () { Navigator.pop(context); onImportData(); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('设置'),
              onTap: () { Navigator.pop(context); onOpenSettings(); },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('深色主题', style: TextStyle(fontSize: 14)),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (_) => onToggleTheme(),
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
                        const TextSpan(text: 'LP助手 v1.0.2\n', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const TextSpan(text: '游戏王桌游辅助工具\n', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const TextSpan(text: 'Flutter 3.32 · Dart 3.8\n', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const TextSpan(text: '\n', style: TextStyle(fontSize: 4)),
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
