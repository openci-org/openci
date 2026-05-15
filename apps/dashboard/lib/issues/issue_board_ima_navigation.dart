part of 'issue_board_ima_page.dart';

class _CompactDestinationBody extends StatelessWidget {
  const _CompactDestinationBody({required this.destination});

  final _CompactBoardDestination destination;

  @override
  Widget build(BuildContext context) {
    return switch (destination) {
      _CompactBoardDestination.issueBoard => const SizedBox.shrink(),
      _CompactBoardDestination.runs => const LogsBody(),
      _CompactBoardDestination.workers => const WorkerStatusBody(),
      _CompactBoardDestination.workflows => const WorkflowsBody(),
      _CompactBoardDestination.variables => const VariablesBody(),
      _CompactBoardDestination.storeRelease => const StoreReleaseBody(),
    };
  }
}

class _DesktopBoardNavigationRail extends StatelessWidget {
  const _DesktopBoardNavigationRail({
    required this.selectedDestination,
    required this.workspaceName,
    required this.extended,
    required this.onSignOut,
    required this.onCollapsedChanged,
    required this.onDestinationSelected,
    this.onSwitchTeam,
  });

  final _CompactBoardDestination selectedDestination;
  final String workspaceName;
  final bool extended;
  final Future<void> Function() onSignOut;
  final ValueChanged<bool> onCollapsedChanged;
  final ValueChanged<_CompactBoardDestination> onDestinationSelected;
  final VoidCallback? onSwitchTeam;

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
        trailing: _DesktopRailAccountSection(
          extended: extended,
          workspaceName: workspaceName,
          onSwitchTeam: onSwitchTeam,
          onSignOut: onSignOut,
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
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _DesktopRailAccountSection extends StatelessWidget {
  const _DesktopRailAccountSection({
    required this.extended,
    required this.workspaceName,
    required this.onSignOut,
    this.onSwitchTeam,
  });

  final bool extended;
  final String workspaceName;
  final Future<void> Function() onSignOut;
  final VoidCallback? onSwitchTeam;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DesktopRailBuildInfo(extended: false),
            if (_railBuildUpdatedAt != null) const SizedBox(height: 4),
            if (onSwitchTeam != null) ...[
              IconButton(
                tooltip: workspaceName,
                onPressed: onSwitchTeam,
                icon: const Icon(Icons.groups_2_outlined),
              ),
              const SizedBox(height: 4),
            ],
            IconButton(
              tooltip: 'サインアウト',
              onPressed: () => unawaited(onSignOut()),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DesktopRailBuildInfo(extended: true),
          if (_railBuildUpdatedAt != null) const SizedBox(height: 10),
          if (onSwitchTeam != null) ...[
            _DesktopRailActionTile(
              icon: Icons.groups_2_outlined,
              label: workspaceName,
              onTap: onSwitchTeam!,
            ),
            const SizedBox(height: 8),
          ],
          _DesktopRailActionTile(
            icon: Icons.logout_rounded,
            label: 'サインアウト',
            onTap: () => unawaited(onSignOut()),
          ),
        ],
      ),
    );
  }
}

class _DesktopRailBuildInfo extends StatelessWidget {
  const _DesktopRailBuildInfo({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final updatedAt = _railBuildUpdatedAt;
    if (updatedAt == null) {
      return const SizedBox.shrink();
    }

    final fullText = _formatRailBuildUpdatedText(updatedAt);
    if (!extended) {
      return Tooltip(
        message: '最終更新: $fullText',
        child: _AnimatedRailInk(
          borderRadius: BorderRadius.circular(12),
          onTap: () => unawaited(_launchUrlExternal(_openCiRepositoryUrl)),
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Icon(
              Icons.update_rounded,
              size: 20,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      );
    }

    return _AnimatedRailInk(
      borderRadius: BorderRadius.circular(16),
      onTap: () => unawaited(_launchUrlExternal(_openCiRepositoryUrl)),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.update_rounded,
                size: 17,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '最終更新',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fullText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRailInk extends StatefulWidget {
  const _AnimatedRailInk({
    required this.borderRadius,
    required this.onTap,
    required this.child,
  });

  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_AnimatedRailInk> createState() => _AnimatedRailInkState();
}

class _AnimatedRailInkState extends State<_AnimatedRailInk> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: widget.borderRadius,
        mouseCursor: SystemMouseCursors.click,
        onTap: widget.onTap,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF2563EB).withValues(alpha: 0.14);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF2563EB).withValues(alpha: 0.08);
          }
          return null;
        }),
        child: widget.child,
      ),
    );
  }
}

String _formatRailBuildUpdatedText(DateTime updatedAt) {
  final formattedDate = DateFormat('MM/dd HH:mm').format(updatedAt);
  final sha = _railBuildSha;
  final shaSuffix = sha.isEmpty ? '' : ' ($sha)';
  return '$formattedDate$shaSuffix';
}

DateTime? get _railBuildUpdatedAt {
  final updatedAt = BuildInfo.updatedAt;
  if (updatedAt != null) {
    return updatedAt;
  }

  return kDebugMode
      ? DateTime.now().subtract(const Duration(minutes: 42))
      : null;
}

String get _railBuildSha {
  if (BuildInfo.sha.isNotEmpty) {
    return BuildInfo.sha;
  }

  return kDebugMode ? 'mock' : '';
}

class _DesktopRailActionTile extends StatelessWidget {
  const _DesktopRailActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF475569)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
