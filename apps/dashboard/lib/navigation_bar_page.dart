import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/environment_variables/environment_variables_page.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/secret_manager/secret_manager_page.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/github_connection_banner.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/github_connection_provider.dart';
import 'package:dashboard/workflow/list/workflow_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class NavigationBarPage extends HookConsumerWidget {
  const NavigationBarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPageIndex = useState(0);
    final navT = t.nav;
    final locale = TranslationProvider.of(context).flutterLocale;
    final teamState = ref.watch(teamStateProvider);

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
      body: teamState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (team) {
          final isGitHubConnected = ref.watch(isGitHubConnectedProvider);
          if (isGitHubConnected) {
            return pages[currentPageIndex.value];
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => const SwitchTeamBottomSheet(),
                        );
                      },
                      icon: const Icon(Icons.swap_horiz),
                      label: Text(
                        team.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GitHubConnectionBanner(
                      onConnectPressed: () async {
                        final url = Uri.parse(
                          'https://github.com/apps/openci-org/installations/new',
                        ).replace(queryParameters: {'state': team.id});
                        await url_launcher.launchUrl(url);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
