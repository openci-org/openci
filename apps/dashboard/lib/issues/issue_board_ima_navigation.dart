part of 'issue_board_ima_page.dart';

class _CompactDestinationBody extends StatelessWidget {
  const _CompactDestinationBody({
    required this.destination,
    this.onSwitchTeam,
  });

  final _CompactBoardDestination destination;
  final VoidCallback? onSwitchTeam;

  @override
  Widget build(BuildContext context) {
    return switch (destination) {
      _CompactBoardDestination.issueBoard => const SizedBox.shrink(),
      _CompactBoardDestination.runs => const LogsBody(),
      _CompactBoardDestination.workers => const WorkerStatusBody(),
      _CompactBoardDestination.workflows => const WorkflowsBody(),
      _CompactBoardDestination.variables => const VariablesBody(),
      _CompactBoardDestination.storeRelease => const StoreReleaseBody(),
      _CompactBoardDestination.settings => SettingsPage(
        onSwitchTeam: onSwitchTeam,
      ),
    };
  }
}

class _DesktopBoardNavigationRail extends StatelessWidget {
  const _DesktopBoardNavigationRail({
    required this.selectedDestination,
    required this.extended,
    required this.onCollapsedChanged,
    required this.onDestinationSelected,
  });

  final _CompactBoardDestination selectedDestination;
  final bool extended;
  final ValueChanged<bool> onCollapsedChanged;
  final ValueChanged<_CompactBoardDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _boardNavigationDestinations.indexOf(
      selectedDestination,
    );

    return SizedBox(
      width: extended ? 216 : 80,
      child: NavigationRail(
        backgroundColor: const Color(0xFFF8FAFC),
        extended: extended,
        minWidth: 80,
        minExtendedWidth: 216,
        groupAlignment: -1,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        labelType: extended ? null : NavigationRailLabelType.all,
        leading: _DesktopRailHeader(
          extended: extended,
          onCollapsedChanged: onCollapsedChanged,
        ),
        destinations: [
          for (final destination in _boardNavigationDestinations)
            NavigationRailDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: Text(destination.label),
            ),
        ],
        onDestinationSelected: (index) {
          onDestinationSelected(_boardNavigationDestinations[index]);
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
            const _OpenCiMark(),
            const SizedBox(height: 12),
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
          const _OpenCiMark(),
          const SizedBox(width: 12),
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

class _OpenCiMark extends StatelessWidget {
  const _OpenCiMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Text(
        'OC',
        style: TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
