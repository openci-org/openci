import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/cicd_log/cicd_logs_page.dart';
import 'package:dashboard/extensions/async_value_extensions.dart';
import 'package:dashboard/extensions/circular_progress_indicator_extensions.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/secret_manager/secret_manager_page.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DashboardRouteGateway extends ConsumerWidget {
  const DashboardRouteGateway({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const CircularProgressIndicator.adaptive().withScaffoldCenter(),
      error: asyncErrorWidget,
      data: (user) {
        if (user == null) {
          return const AuthPage();
        }

        final configAsync = ref.watch(selfHostedConfigProvider);
        final selectedTeamIdAsync = ref.watch(selectedTeamIdProvider);
        final teamAsync = ref.watch(selectedTeamProvider);

        return (configAsync, selectedTeamIdAsync, teamAsync).when(
          loading: () =>
              const CircularProgressIndicator.adaptive().withScaffoldCenter(),
          error: asyncErrorWidget,
          data: (_, selectedTeamId, team) {
            if (selectedTeamId == null) {
              FirebaseAuth.instance.signOut();
              throw Exception("No team selected");
            }

            return DashboardRoot(
              key: ValueKey(selectedTeamId),
              workspaceId: selectedTeamId,
              workspaceName: team.name,
              onSwitchTeam: () => showTeamFlowModal(context),
            );
          },
        );
      },
    );
  }
}

class DashboardRoot extends HookWidget {
  const DashboardRoot({
    super.key,
    this.workspaceId = '',
    this.workspaceName = 'OpenCI team',
    this.onSwitchTeam,
  });

  final String workspaceId;
  final String workspaceName;
  final VoidCallback? onSwitchTeam;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.value,
        onDestinationSelected: (index) {
          selectedIndex.value = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'CI/CDログ',
          ),
          NavigationDestination(
            icon: Icon(Icons.key_outlined),
            selectedIcon: Icon(Icons.key_rounded),
            label: 'シークレット',
          ),
          NavigationDestination(
            icon: Icon(Icons.rocket_launch_outlined),
            selectedIcon: Icon(Icons.rocket_launch_rounded),
            label: 'ストアリリース',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: '設定',
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex.value,
          children: [
            const CicdLogsPage(),
            const SecretManagerPage(),
            const StoreReleasePage(),
            SettingsPage(onSwitchTeam: onSwitchTeam),
          ],
        ),
      ),
    );
  }
}
