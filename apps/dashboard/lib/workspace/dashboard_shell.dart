import 'package:dashboard/build_logs/app_distributions_page.dart';
import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:dashboard/workers/worker_status_page.dart';
import 'package:dashboard/workflow/list/workflows_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const compactBoardBreakpoint = 640.0;

enum CompactBoardDestination {
  runs,
  workers,
  workflows,
  variables,
  storeRelease,
  distributions,
  settings,
}

const boardNavigationDestinations = [
  CompactBoardDestination.runs,
  CompactBoardDestination.workers,
  CompactBoardDestination.workflows,
  CompactBoardDestination.variables,
  CompactBoardDestination.storeRelease,
  CompactBoardDestination.distributions,
  CompactBoardDestination.settings,
];

extension CompactBoardDestinationLabel on CompactBoardDestination {
  String get label => switch (this) {
    CompactBoardDestination.runs => 'CI/CDログ',
    CompactBoardDestination.workers => 'ワーカー',
    CompactBoardDestination.workflows => 'CI/CD設定',
    CompactBoardDestination.variables => 'シークレット',
    CompactBoardDestination.storeRelease => 'ストアリリース',
    CompactBoardDestination.distributions => 'アプリ配信',
    CompactBoardDestination.settings => '設定',
  };

  IconData get icon => switch (this) {
    CompactBoardDestination.runs => Icons.history_rounded,
    CompactBoardDestination.workers => Icons.dns_outlined,
    CompactBoardDestination.workflows => Icons.schema_rounded,
    CompactBoardDestination.variables => Icons.key_rounded,
    CompactBoardDestination.storeRelease => Icons.rocket_launch_outlined,
    CompactBoardDestination.distributions => Icons.install_mobile_rounded,
    CompactBoardDestination.settings => Icons.settings_outlined,
  };

  IconData get selectedIcon => switch (this) {
    CompactBoardDestination.runs => Icons.history_rounded,
    CompactBoardDestination.workers => Icons.dns_rounded,
    CompactBoardDestination.workflows => Icons.schema_rounded,
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

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    this.workspaceId = '',
    this.workspaceName = 'OpenCI team',
    this.onSwitchTeam,
  });

  final String workspaceId;
  final String workspaceName;
  final VoidCallback? onSwitchTeam;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  CompactBoardDestination _compactDestination = CompactBoardDestination.runs;
  bool _isDesktopRailCollapsed = false;

  void _selectCompactDestination(CompactBoardDestination destination) {
    if (_compactDestination == destination) {
      return;
    }
    setState(() => _compactDestination = destination);
  }

  @override
  Widget build(BuildContext context) {
    final isCompactLayout =
        MediaQuery.sizeOf(context).width < compactBoardBreakpoint;

    void onRunsTap() => _selectCompactDestination(CompactBoardDestination.runs);
    void onWorkersTap() => _selectCompactDestination(CompactBoardDestination.workers);
    void onWorkflowsTap() => _selectCompactDestination(CompactBoardDestination.workflows);
    void onVariablesTap() => _selectCompactDestination(CompactBoardDestination.variables);
    void onStoreReleaseTap() => _selectCompactDestination(CompactBoardDestination.storeRelease);
    void onDistributionsTap() => _selectCompactDestination(CompactBoardDestination.distributions);
    void onSettingsTap() => _selectCompactDestination(CompactBoardDestination.settings);

    final content = SafeArea(
      child: CompactDestinationBody(
        destination: _compactDestination,
        onSwitchTeam: widget.onSwitchTeam,
      ),
    );

    return _DashboardShortcuts(
      onToggleNavigation: () {
        if (isCompactLayout) {
          return;
        }
        setState(
          () => _isDesktopRailCollapsed = !_isDesktopRailCollapsed,
        );
      },
      onDestinationSelected: _selectCompactDestination,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: isCompactLayout
            ? AppBar(
                title: Text(
                  _compactDestination.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                backgroundColor: const Color(0xFFF4F7FB),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                scrolledUnderElevation: 0,
              )
            : null,
        drawer: isCompactLayout
            ? DashboardDrawer(
                workspaceName: widget.workspaceName,
                selectedDestination: _compactDestination,
                onRunsTap: onRunsTap,
                onWorkersTap: onWorkersTap,
                onWorkflowsTap: onWorkflowsTap,
                onVariablesTap: onVariablesTap,
                onStoreReleaseTap: onStoreReleaseTap,
                onDistributionsTap: onDistributionsTap,
                onSettingsTap: onSettingsTap,
              )
            : null,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (isCompactLayout) {
              return content;
            }

            return Row(
              children: [
                DesktopBoardNavigationRail(
                  selectedDestination: _compactDestination,
                  extended:
                      constraints.maxWidth >= 960 && !_isDesktopRailCollapsed,
                  onCollapsedChanged: (collapsed) =>
                      setState(() => _isDesktopRailCollapsed = collapsed),
                  onDestinationSelected: _selectCompactDestination,
                ),
                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
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

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({
    super.key,
    required this.workspaceName,
    required this.selectedDestination,
    required this.onRunsTap,
    required this.onWorkersTap,
    required this.onWorkflowsTap,
    required this.onVariablesTap,
    required this.onStoreReleaseTap,
    required this.onDistributionsTap,
    required this.onSettingsTap,
  });

  final String workspaceName;
  final CompactBoardDestination selectedDestination;
  final VoidCallback onRunsTap;
  final VoidCallback onWorkersTap;
  final VoidCallback onWorkflowsTap;
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
              icon: Icons.dns_outlined,
              label: 'ワーカー',
              selected: selectedDestination == CompactBoardDestination.workers,
              onTap: () => runAfterClose(onWorkersTap),
            ),
            _CompactDrawerTile(
              icon: Icons.schema_rounded,
              label: 'CI/CD設定',
              selected: selectedDestination == CompactBoardDestination.workflows,
              onTap: () => runAfterClose(onWorkflowsTap),
            ),
            _CompactDrawerTile(
              icon: Icons.key_rounded,
              label: 'シークレット',
              selected: selectedDestination == CompactBoardDestination.variables,
              onTap: () => runAfterClose(onVariablesTap),
            ),
            _CompactDrawerTile(
              icon: Icons.rocket_launch_outlined,
              label: 'ストアリリース',
              selected: selectedDestination == CompactBoardDestination.storeRelease,
              onTap: () => runAfterClose(onStoreReleaseTap),
            ),
            _CompactDrawerTile(
              icon: Icons.install_mobile_rounded,
              label: 'アプリ配信',
              selected: selectedDestination == CompactBoardDestination.distributions,
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
    final color = selected
        ? const Color(0xFF2563EB)
        : const Color(0xFF0F172A);

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

class _DashboardShortcuts extends StatefulWidget {
  const _DashboardShortcuts({
    required this.onToggleNavigation,
    required this.onDestinationSelected,
    required this.child,
  });

  final VoidCallback onToggleNavigation;
  final ValueChanged<CompactBoardDestination> onDestinationSelected;
  final Widget child;

  @override
  State<_DashboardShortcuts> createState() => _DashboardShortcutsState();
}

class _DashboardShortcutsState extends State<_DashboardShortcuts> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () =>
          widget.onDestinationSelected(CompactBoardDestination.runs),
      const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () =>
          widget.onDestinationSelected(CompactBoardDestination.workers),
      const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () =>
          widget.onDestinationSelected(CompactBoardDestination.workflows),
      const SingleActivator(LogicalKeyboardKey.digit4, meta: true): () =>
          widget.onDestinationSelected(CompactBoardDestination.variables),
      const SingleActivator(LogicalKeyboardKey.digit5, meta: true): () =>
          widget.onDestinationSelected(CompactBoardDestination.storeRelease),
      const SingleActivator(LogicalKeyboardKey.digit6, meta: true): () =>
          widget.onDestinationSelected(CompactBoardDestination.distributions),
      const SingleActivator(LogicalKeyboardKey.digit7, meta: true): () =>
          widget.onDestinationSelected(CompactBoardDestination.settings),
    };

    if (!kIsWeb) {
      bindings.addAll({
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            widget.onToggleNavigation,
      });
    }

    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_hasTextInputFocus()) {
              _focusNode.requestFocus();
            }
          },
          child: widget.child,
        ),
      ),
    );
  }

  bool _hasTextInputFocus() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) {
      return false;
    }
    return context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }
}
