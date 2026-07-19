import 'package:dashboard/build_logs/app_distributions_page.dart';
import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      CompactBoardDestination.runs => const LogsBody(),
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

    return _DashboardShortcuts(
      onDestinationSelected: _selectCompactDestination,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          title: Text(
            _compactDestination.label,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          backgroundColor: const Color(0xFFF4F7FB),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
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
      ),
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

class _DashboardShortcuts extends StatefulWidget {
  const _DashboardShortcuts({
    required this.onDestinationSelected,
    required this.child,
  });

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
          widget.onDestinationSelected(CompactBoardDestination.variables),
      const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () =>
          widget.onDestinationSelected(CompactBoardDestination.storeRelease),
      const SingleActivator(LogicalKeyboardKey.digit4, meta: true): () =>
          widget.onDestinationSelected(CompactBoardDestination.distributions),
      const SingleActivator(LogicalKeyboardKey.digit5, meta: true): () =>
          widget.onDestinationSelected(CompactBoardDestination.settings),
    };

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
