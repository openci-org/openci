import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:dashboard/workflow/list/workflow_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';

const tabPageList = [
  WorkflowListPage(),
  VariablesPage(),
  LogsPage(),
  SettingsPage(),
];

class NavigationBarPage extends HookWidget {
  const NavigationBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPageIndex = useState(0);
    final t = context.t;
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: currentPageIndex.value,
        onDestinationSelected: (int index) => currentPageIndex.value = index,
        destinations: [
          NavigationDestination(
            selectedIcon: Icon(Symbols.bolt_rounded, fill: 1),
            icon: Icon(Symbols.bolt_rounded),
            label: t.navigation.workflows,
          ),
          NavigationDestination(
            selectedIcon: Icon(Symbols.passkey_rounded, fill: 1),
            icon: Icon(Symbols.passkey_rounded),
            label: t.navigation.variables,
          ),
          NavigationDestination(
            selectedIcon: Icon(Symbols.terminal_rounded, fill: 1),
            icon: Icon(Symbols.terminal_rounded),
            label: t.navigation.logs,
          ),
          NavigationDestination(
            selectedIcon: Icon(Symbols.settings_rounded, fill: 1),
            icon: Icon(Symbols.settings_rounded),
            label: t.navigation.settings,
          ),
        ],
      ),
      body: tabPageList[currentPageIndex.value],
    );
  }
}
