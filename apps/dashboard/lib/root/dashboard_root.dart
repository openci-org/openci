import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/app_distributions_page.dart';
import 'package:dashboard/cicd_log/cicd_logs_page.dart';
import 'package:dashboard/extensions/async_value_extensions.dart';
import 'package:dashboard/extensions/circular_progress_indicator_extensions.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum CompactBoardDestination {
  runs,
  variables,
  storeRelease,
  distributions,
  settings,
}

const boardNavigationDestinations = [
  CompactBoardDestination.runs,
  CompactBoardDestination.variables,
  CompactBoardDestination.storeRelease,
  CompactBoardDestination.distributions,
  CompactBoardDestination.settings,
];

extension CompactBoardDestinationLabel on CompactBoardDestination {
  String get label => switch (this) {
    CompactBoardDestination.runs => 'CI/CDログ',
    CompactBoardDestination.variables => 'シークレット',
    CompactBoardDestination.storeRelease => 'ストアリリース',
    CompactBoardDestination.distributions => 'アプリ配信',
    CompactBoardDestination.settings => '設定',
  };

  IconData get icon => switch (this) {
    CompactBoardDestination.runs => Icons.history_rounded,
    CompactBoardDestination.variables => Icons.key_rounded,
    CompactBoardDestination.storeRelease => Icons.rocket_launch_outlined,
    CompactBoardDestination.distributions => Icons.install_mobile_rounded,
    CompactBoardDestination.settings => Icons.settings_outlined,
  };

  IconData get selectedIcon => switch (this) {
    CompactBoardDestination.runs => Icons.history_rounded,
    CompactBoardDestination.variables => Icons.key_rounded,
    CompactBoardDestination.storeRelease => Icons.rocket_launch_rounded,
    CompactBoardDestination.distributions => Icons.install_mobile_rounded,
    CompactBoardDestination.settings => Icons.settings_rounded,
  };
}

class CompactDestinationBody extends StatelessWidget {
  const CompactDestinationBody({
    super.key,
    required this.destination,
    this.onSwitchTeam,
  });

  final CompactBoardDestination destination;
  final VoidCallback? onSwitchTeam;

  @override
  Widget build(BuildContext context) {
    return switch (destination) {
      CompactBoardDestination.runs => const CicdLogsPage(),
      CompactBoardDestination.variables => const VariablesBody(),
      CompactBoardDestination.storeRelease => const StoreReleaseBody(),
      CompactBoardDestination.distributions => const AppDistributionsBody(),
      CompactBoardDestination.settings => SettingsPage(
        onSwitchTeam: onSwitchTeam,
      ),
    };
  }
}

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
        final teamAsync = ref.watch(teamStateProvider);

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

class DashboardRoot extends StatefulWidget {
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
  State<DashboardRoot> createState() => _DashboardRootState();
}

class _DashboardRootState extends State<DashboardRoot> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  CompactBoardDestination _compactDestination = CompactBoardDestination.runs;

  void _selectCompactDestination(CompactBoardDestination destination) {
    if (_compactDestination == destination) {
      return;
    }
    setState(() => _compactDestination = destination);
  }

  @override
  Widget build(BuildContext context) {
    void onRunsTap() => _selectCompactDestination(CompactBoardDestination.runs);
    void onVariablesTap() =>
        _selectCompactDestination(CompactBoardDestination.variables);
    void onStoreReleaseTap() =>
        _selectCompactDestination(CompactBoardDestination.storeRelease);
    void onDistributionsTap() =>
        _selectCompactDestination(CompactBoardDestination.distributions);
    void onSettingsTap() =>
        _selectCompactDestination(CompactBoardDestination.settings);

    final content = SafeArea(
      child: CompactDestinationBody(
        destination: _compactDestination,
        onSwitchTeam: widget.onSwitchTeam,
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _compactDestination.label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      drawer: DashboardDrawer(
        workspaceName: widget.workspaceName,
        selectedDestination: _compactDestination,
        onRunsTap: onRunsTap,
        onVariablesTap: onVariablesTap,
        onStoreReleaseTap: onStoreReleaseTap,
        onDistributionsTap: onDistributionsTap,
        onSettingsTap: onSettingsTap,
      ),
      body: content,
    );
  }
}

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({
    super.key,
    required this.workspaceName,
    required this.selectedDestination,
    required this.onRunsTap,
    required this.onVariablesTap,
    required this.onStoreReleaseTap,
    required this.onDistributionsTap,
    required this.onSettingsTap,
  });

  final String workspaceName;
  final CompactBoardDestination selectedDestination;
  final VoidCallback onRunsTap;
  final VoidCallback onVariablesTap;
  final VoidCallback onStoreReleaseTap;
  final VoidCallback onDistributionsTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    void closeDrawer() => Navigator.of(context).pop();
    void runAfterClose(VoidCallback action) {
      closeDrawer();
      action();
    }

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OpenCI',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workspaceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Text(
                'ナビゲーション',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _CompactDrawerTile(
              icon: Icons.history_rounded,
              label: 'CI/CDログ',
              selected: selectedDestination == CompactBoardDestination.runs,
              onTap: () => runAfterClose(onRunsTap),
            ),
            _CompactDrawerTile(
              icon: Icons.key_rounded,
              label: 'シークレット',
              selected:
                  selectedDestination == CompactBoardDestination.variables,
              onTap: () => runAfterClose(onVariablesTap),
            ),
            _CompactDrawerTile(
              icon: Icons.rocket_launch_outlined,
              label: 'ストアリリース',
              selected:
                  selectedDestination == CompactBoardDestination.storeRelease,
              onTap: () => runAfterClose(onStoreReleaseTap),
            ),
            _CompactDrawerTile(
              icon: Icons.install_mobile_rounded,
              label: 'アプリ配信',
              selected:
                  selectedDestination == CompactBoardDestination.distributions,
              onTap: () => runAfterClose(onDistributionsTap),
            ),
            _CompactDrawerTile(
              icon: Icons.settings_outlined,
              label: '設定',
              selected: selectedDestination == CompactBoardDestination.settings,
              onTap: () => runAfterClose(onSettingsTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactDrawerTile extends StatelessWidget {
  const _CompactDrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2563EB) : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        selected: selected,
        selectedTileColor: const Color(0xFFEFF6FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: color),
        title: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
