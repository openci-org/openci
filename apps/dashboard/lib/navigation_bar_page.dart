import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/environment_variables/environment_variables_page.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/secret_manager/secret_manager_page.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/workflow/list/workflow_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';

class NavigationBarPage extends HookWidget {
  const NavigationBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPageIndex = useState(0);
    final navT = t.nav;
    final locale = TranslationProvider.of(context).flutterLocale;

    final pages = [
      WorkflowListPage(key: ValueKey('workflow_$locale')),
      SecretManagerPage(key: ValueKey('secrets_$locale')),
      EnvironmentVariablesPage(key: ValueKey('envVars_$locale')),
      LogsPage(key: ValueKey('logs_$locale')),
      SettingsPage(key: ValueKey('settings_$locale')),
    ];

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: currentPageIndex.value,
        onDestinationSelected: (int index) => currentPageIndex.value = index,
        destinations: [
          NavigationDestination(
            selectedIcon: Icon(Icons.account_tree),
            icon: Icon(Symbols.account_tree_rounded),
            label: navT.workflows,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.key),
            icon: Icon(Symbols.key_rounded),
            label: navT.secrets,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.data_object),
            icon: Icon(Symbols.data_object_rounded),
            label: navT.envVars,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.article),
            icon: Icon(Symbols.article_rounded),
            label: navT.logs,
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: navT.settings,
          ),
        ],
      ),
      body: pages[currentPageIndex.value],
    );
  }
}
