import 'package:dashboard/build_logs/app_distributions_page.dart';
import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:dashboard/workers/worker_status_page.dart';
import 'package:dashboard/workflow/list/workflows_page.dart';
import 'package:flutter/material.dart';
import 'issue_board_ima_app_shell.dart';

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
      CompactBoardDestination.issueBoard => const SizedBox.shrink(),
      CompactBoardDestination.runs => const LogsBody(),
      CompactBoardDestination.workers => const WorkerStatusBody(),
      CompactBoardDestination.workflows => const WorkflowsBody(),
      CompactBoardDestination.variables => const VariablesBody(),
      CompactBoardDestination.storeRelease => const StoreReleaseBody(),
      CompactBoardDestination.distributions => const AppDistributionsBody(),
      CompactBoardDestination.settings => SettingsPage(
        onSwitchTeam: onSwitchTeam,
      ),
    };
  }
}

class DesktopBoardNavigationRail extends StatelessWidget {
  const DesktopBoardNavigationRail({
    super.key,
    required this.selectedDestination,
    required this.extended,
    required this.onCollapsedChanged,
    required this.onDestinationSelected,
  });

  final CompactBoardDestination selectedDestination;
  final bool extended;
  final ValueChanged<bool> onCollapsedChanged;
  final ValueChanged<CompactBoardDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = boardNavigationDestinations.indexOf(
      selectedDestination,
    );

    return SizedBox(
      width: extended ? 216 : 80,
      child: NavigationRail(
        backgroundColor: const Color(0xFFF8FAFC),
        extended: extended,
        minWidth: extended ? 80 : 72,
        minExtendedWidth: 216,
        groupAlignment: -1,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        labelType: extended ? null : NavigationRailLabelType.none,
        leading: _DesktopRailHeader(
          extended: extended,
          onCollapsedChanged: onCollapsedChanged,
        ),
        destinations: [
          for (final destination in boardNavigationDestinations)
            NavigationRailDestination(
              icon: _RailIcon(
                icon: destination.icon,
                tooltip: destination.label,
              ),
              selectedIcon: _RailIcon(
                icon: destination.selectedIcon,
                tooltip: destination.label,
              ),
              label: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onDestinationSelected: (index) {
          onDestinationSelected(boardNavigationDestinations[index]);
        },
      ),
    );
  }
}

class _DesktopRailHeader extends StatelessWidget {
  const _DesktopRailHeader({
    required this.extended,
    required this.onCollapsedChanged,
  });

  final bool extended;
  final ValueChanged<bool> onCollapsedChanged;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              tooltip: 'ナビゲーションを展開',
              onPressed: () => onCollapsedChanged(false),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'OpenCI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'ナビゲーションを折りたたむ',
            onPressed: () => onCollapsedChanged(true),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({
    required this.icon,
    required this.tooltip,
  });

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Icon(icon),
    );
  }
}
