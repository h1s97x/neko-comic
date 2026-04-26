import 'package:flutter/material.dart';

/// Settings page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.appearance),
            title: const Text('Appearance'),
            subtitle: const Text('Theme, font size'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Storage'),
            subtitle: const Text('Cache, download location'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync'),
            subtitle: const Text('WebDAV sync settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'NekoComic',
                applicationVersion: '1.0.0',
                applicationLegalese: 'A modern comic reader',
              );
            },
          ),
        ],
      ),
    );
  }
}
