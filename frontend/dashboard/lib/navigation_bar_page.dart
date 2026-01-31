import 'package:dashboard/logs/logs_page.dart';
import 'package:dashboard/secret_manager/secret_manager_page.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/workflow/editor/workflow_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';

const tabPageList = [
  WorkflowEditorPage(),
  SecretManagerPage(),
  LogsPage(),
  SettingsPage(),
];

class NavigationBarPage extends HookWidget {
  const NavigationBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPageIndex = useState(0);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: currentPageIndex.value,
        onDestinationSelected: (int index) => currentPageIndex.value = index,
        destinations: [
          NavigationDestination(
            selectedIcon: Icon(Icons.add),
            icon: Icon(Symbols.add_2_rounded),
            label: 'Create',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.key),
            icon: Icon(Symbols.key_rounded),
            label: 'Secret Manager',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.article),
            icon: Icon(Symbols.article_rounded),
            label: 'Logs',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
      body: tabPageList[currentPageIndex.value],
    );
  }
}
