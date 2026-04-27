import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../stores/app_store.dart';

/// Settings page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = context.watch<AppStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(_getThemeModeText(appStore.themeMode)),
            onTap: () => _showThemeDialog(context, appStore),
          ),
          const Divider(),

          // Reading
          _SectionHeader(title: 'Reading'),
          ListTile(
            leading: const Icon(Icons.view_carousel),
            title: const Text('Default Reading Layout'),
            subtitle: Text(appStore.defaultLayout.name),
            onTap: () => _showLayoutDialog(context, appStore),
          ),
          const Divider(),

          // Data
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Settings'),
            onTap: () {
              // Navigate to sync settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Cache Management'),
            subtitle: const Text('Clear cached images'),
            onTap: () {
              // Show cache management
            },
          ),
          const Divider(),

          // Sources
          _SectionHeader(title: 'Sources'),
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('Manage Sources'),
            subtitle: Text('${appStore.sources.length} sources'),
            onTap: () {
              // Navigate to source management
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Source'),
            onTap: () {
              // Add new source
            },
          ),
          const Divider(),

          // About
          _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source Code'),
            subtitle: const Text('View on GitHub'),
            onTap: () {
              // Open GitHub
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context, AppStore appStore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: appStore.themeMode,
              onChanged: (value) {
                appStore.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: appStore.themeMode,
              onChanged: (value) {
                appStore.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: appStore.themeMode,
              onChanged: (value) {
                appStore.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLayoutDialog(BuildContext context, AppStore appStore) {
    // TODO: Implement layout selection dialog
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
