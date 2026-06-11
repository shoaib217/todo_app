import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Theme mode'),
              subtitle: const Text('Choose light, dark, or system theme'),
              trailing: DropdownButton<ThemeMode>(
                value: themeMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Suggested settings for better experience',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSuggestionTile(
            icon: Icons.notifications,
            title: 'Reminder notifications',
            subtitle: 'Enable task reminders and due date alerts.',
          ),
          const SizedBox(height: 10),
          _buildSuggestionTile(
            icon: Icons.label_outline,
            title: 'Task categories',
            subtitle: 'Add labels or categories for better task organization.',
          ),
          const SizedBox(height: 10),
          _buildSuggestionTile(
            icon: Icons.sort,
            title: 'Sort & filter',
            subtitle: 'Sort tasks by due date, priority, or completion status.',
          ),
          const SizedBox(height: 10),
          _buildSuggestionTile(
            icon: Icons.backup,
            title: 'Backup & restore',
            subtitle: 'Save tasks locally or restore them after reinstall.',
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
