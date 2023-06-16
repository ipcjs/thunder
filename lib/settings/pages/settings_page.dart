import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:go_router/go_router.dart';

class SettingTopic {
  final String title;
  final IconData icon;
  final String path;

  SettingTopic({required this.title, required this.icon, required this.path});
}

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final List<SettingTopic> topics = [
    SettingTopic(title: 'General', icon: Icons.settings, path: '/settings/general'),
    // SettingTopic(title: 'Appearance', icon: Icons.text_fields, path: '/settings/appearance'),
    // SettingTopic(title: 'Developer', icon: Icons.developer_mode, path: '/settings/developer'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70.0,
        centerTitle: false,
        title: AutoSizeText('Settings', style: theme.textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        child: ListView(
          shrinkWrap: true,
          children: topics
              .map((topic) => ListTile(
                    title: Text(topic.title),
                    leading: Icon(topic.icon),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => GoRouter.of(context).push(topic.path),
                  ))
              .toList(),
        ),
      ),
    );
  }
}