import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BuildLogsDetailPage extends HookConsumerWidget {
  const BuildLogsDetailPage({super.key, required this.buildJob});
  final BuildJob buildJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowNameAsync = ref.watch(
      workflowNameProvider(buildJob.workflowId),
    );

    final statusColor = switch (buildJob.status) {
      'success' => Colors.green,
      'failure' => Colors.red,
      'in_progress' => Colors.blue,
      'queued' => Colors.orange,
      'cancelled' => Colors.grey,
      _ => Colors.grey,
    };

    final statusIcon = switch (buildJob.status) {
      'success' => Icons.check_circle,
      'failure' => Icons.cancel,
      'queued' => Icons.schedule,
      'cancelled' => Icons.block,
      _ => Icons.help_outline,
    };

    final statusLabel = switch (buildJob.status) {
      'success' => 'Passed',
      'failure' => 'Failed',
      'in_progress' => 'Running',
      'queued' => 'Queued',
      'cancelled' => 'Cancelled',
      _ => buildJob.status,
    };

    final canCancel =
        buildJob.status == 'queued' || buildJob.status == 'in_progress';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          color: Colors.white70,
          onPressed: () => Navigator.pop(context),
        ),
        title: workflowNameAsync.when(
          data: (name) => Text(
            name ?? '${buildJob.owner}/${buildJob.repo}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          loading: () => Container(
            width: 120,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          error: asyncErrorWidget,
        ),
        actions: [
          if (canCancel)
            IconButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Build'),
                    content: const Text(
                      'Are you sure you want to cancel this build?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel Build'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                try {
                  if (!context.mounted) return;
                  context.showSnackBarMessage('Cancelling build...');
                  await ref
                      .read(buildJobsProvider.notifier)
                      .cancelBuildJob(buildJob.id);
                  if (context.mounted) {
                    context.showSnackBarMessage('Build cancelled');
                  }
                } catch (e) {
                  if (context.mounted) {
                    context.showSnackBarMessage('Failed to cancel: $e');
                  }
                }
              },
              icon: Icon(
                Icons.cancel_outlined,
                size: 20,
                color: Colors.grey[400],
              ),
              tooltip: 'Cancel',
            ),
          IconButton(
            onPressed: () async {
              try {
                context.showSnackBarMessage('Retrying build job...');
                await ref
                    .read(buildJobsProvider.notifier)
                    .retryBuildJob(buildJob.id);
                if (context.mounted) {
                  context.showSnackBarMessage('Build job queued successfully');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showSnackBarMessage('Failed to retry: $e');
                }
              }
            },
            icon: Icon(
              Icons.replay,
              size: 20,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            tooltip: 'Retry',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (buildJob.status == 'in_progress')
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: statusColor,
                              ),
                            )
                          else
                            Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${buildJob.owner}/${buildJob.repo}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (buildJob.branch != null)
                      _DetailGitChip(
                        icon: FontAwesomeIcons.codeBranch,
                        label: buildJob.branch!,
                        color: Colors.purple[300]!,
                      ),
                    if (buildJob.pullRequestNumber != null)
                      _DetailGitChip(
                        icon: FontAwesomeIcons.codePullRequest,
                        label: '#${buildJob.pullRequestNumber}',
                        color: Colors.green[300]!,
                      ),
                    if (buildJob.tagName != null)
                      _DetailGitChip(
                        icon: FontAwesomeIcons.tag,
                        label: buildJob.tagName!,
                        color: Colors.amber[300]!,
                      ),
                    if (buildJob.commitSha != null)
                      _DetailGitChip(
                        icon: FontAwesomeIcons.codeCommit,
                        label: buildJob.commitSha!.substring(0, 7),
                        color: Colors.blueGrey[300]!,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: buildJob.latestRunId != null
                ? _DetailLogsView(
                    buildJob: buildJob,
                    runId: buildJob.latestRunId!,
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Waiting for run to start...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailGitChip extends StatelessWidget {
  const _DetailGitChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureSummaryBanner extends StatelessWidget {
  const _FailureSummaryBanner({
    required this.errorLogs,
    required this.buildJob,
  });

  final List<BuildLog> errorLogs;
  final BuildJob buildJob;

  String _buildSummary() {
    if (errorLogs.isEmpty) return 'Build failed with unknown error.';
    final firstError = errorLogs.first.message;
    final lines = firstError.split('\n');
    return lines.first;
  }

  String _buildDetail() {
    if (errorLogs.isEmpty) return '';
    final firstError = errorLogs.first.message;
    final lines = firstError.split('\n');
    if (lines.length <= 1) return '';
    return lines.skip(1).where((l) => l.trim().isNotEmpty).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final summary = _buildSummary();
    final detail = _buildDetail();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.12),
            Colors.red.withValues(alpha: 0.04),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error_rounded,
                      size: 16,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Failure Summary',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B6B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFFFFADAD),
                          height: 1.4,
                        ),
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            detail,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Color(0xFFCDD9E5),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SizedBox(
              height: 34,
              child: FilledButton.icon(
                onPressed: () => _showAIFixSheet(context),
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: const Text(
                  'Fix with AI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF238636),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAIFixSheet(BuildContext context) {
    showAIFixSheet(
      context: context,
      buildJob: buildJob,
      errorLogs: errorLogs,
    );
  }
}

void showAIFixSheet({
  required BuildContext context,
  required BuildJob buildJob,
  List<BuildLog> errorLogs = const [],
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF161B22),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _AIFixSheet(
      errorLogs: errorLogs,
      buildJob: buildJob,
    ),
  );
}

class _AIFixSheet extends HookWidget {
  const _AIFixSheet({
    required this.errorLogs,
    required this.buildJob,
  });

  final List<BuildLog> errorLogs;
  final BuildJob buildJob;

  static const _mockDiffLines = [
    _DiffLine(
      type: _DiffLineType.context,
      text: '  Future<AuthState> refreshToken() async {',
    ),
    _DiffLine(type: _DiffLineType.context, text: '    try {'),
    _DiffLine(
      type: _DiffLineType.removal,
      text: "      final token = await _storage.read('token');",
    ),
    _DiffLine(
      type: _DiffLineType.removal,
      text: '      if (token == null) return AuthState.unauthenticated;',
    ),
    _DiffLine(
      type: _DiffLineType.addition,
      text: "      final token = await _storage.read('refresh_token');",
    ),
    _DiffLine(
      type: _DiffLineType.addition,
      text: '      if (token == null) {',
    ),
    _DiffLine(
      type: _DiffLineType.addition,
      text: "        _logger.warning('No refresh token found');",
    ),
    _DiffLine(
      type: _DiffLineType.addition,
      text: '        return AuthState.unauthenticated;',
    ),
    _DiffLine(
      type: _DiffLineType.addition,
      text: '      }',
    ),
    _DiffLine(type: _DiffLineType.context, text: ''),
    _DiffLine(
      type: _DiffLineType.removal,
      text: '      final response = await _api.refresh(token);',
    ),
    _DiffLine(
      type: _DiffLineType.addition,
      text: '      final response = await _api.refresh(',
    ),
    _DiffLine(
      type: _DiffLineType.addition,
      text: '        refreshToken: token,',
    ),
    _DiffLine(
      type: _DiffLineType.addition,
      text: "        grantType: 'refresh_token',",
    ),
    _DiffLine(
      type: _DiffLineType.addition,
      text: '      );',
    ),
    _DiffLine(
      type: _DiffLineType.context,
      text: "      await _storage.write('token', response.accessToken);",
    ),
    _DiffLine(
      type: _DiffLineType.addition,
      text:
          "      await _storage.write('refresh_token', response.refreshToken);",
    ),
    _DiffLine(
      type: _DiffLineType.context,
      text: '      return AuthState.authenticated;',
    ),
    _DiffLine(type: _DiffLineType.context, text: '    } catch (e) {'),
  ];

  @override
  Widget build(BuildContext context) {
    final fixMode = useState<String?>(null);
    final sheetState = useState('select');

    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildHeader(sheetState.value),
              const SizedBox(height: 20),
              if (sheetState.value == 'select')
                _buildSelectState(context, fixMode, sheetState),
              if (sheetState.value == 'processing')
                _buildProcessingState(sheetState),
              if (sheetState.value == 'result')
                _buildResultState(context, fixMode.value),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String state) {
    final (icon, title, subtitle) = switch (state) {
      'processing' => (
        Icons.auto_fix_high_rounded,
        'Analyzing...',
        'AI is generating a fix',
      ),
      'result' => (
        Icons.check_circle_rounded,
        'Fix Generated',
        'Review the changes below',
      ),
      _ => (
        Icons.auto_fix_high_rounded,
        'Fix with AI',
        'Analyze error & generate a fix',
      ),
    };

    final gradientColors = state == 'result'
        ? const [Color(0xFF238636), Color(0xFF2EA043)]
        : const [Color(0xFF238636), Color(0xFF2EA043)];

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: state == 'processing'
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, size: 18, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8B949E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectState(
    BuildContext context,
    ValueNotifier<String?> fixMode,
    ValueNotifier<String> sheetState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bug_report_rounded,
                    size: 14,
                    color: Color(0xFFFF6B6B),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Error Context',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                errorLogs.map((l) => l.message).join('\n'),
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFFCDD9E5),
                  height: 1.4,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'How would you like to apply the fix?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFFCDD9E5),
          ),
        ),
        const SizedBox(height: 10),
        _FixOptionTile(
          icon: FontAwesomeIcons.codeBranch,
          title: 'Push to branch',
          subtitle: buildJob.branch != null
              ? 'Commit fix directly to ${buildJob.branch}'
              : 'Commit fix directly to the source branch',
          isSelected: fixMode.value == 'push',
          onTap: () => fixMode.value = 'push',
        ),
        const SizedBox(height: 8),
        _FixOptionTile(
          icon: FontAwesomeIcons.codePullRequest,
          title: 'Create Pull Request',
          subtitle: 'Create a new branch with the fix & open a PR',
          isSelected: fixMode.value == 'pr',
          onTap: () => fixMode.value = 'pr',
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            onPressed: fixMode.value == null
                ? null
                : () => sheetState.value = 'processing',
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF238636),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFF238636,
              ).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              fixMode.value == 'pr'
                  ? 'Generate Fix & Create PR'
                  : 'Generate Fix & Push',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState(ValueNotifier<String> sheetState) {
    return _ProcessingSteps(
      onComplete: () => sheetState.value = 'result',
    );
  }

  Widget _buildResultState(BuildContext context, String? fixMode) {
    final removals = _mockDiffLines
        .where((l) => l.type == _DiffLineType.removal)
        .length;
    final additions = _mockDiffLines
        .where((l) => l.type == _DiffLineType.addition)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: Color(0xFF8B949E),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'lib/auth/auth_provider.dart',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFFCDD9E5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '+$additions',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFF3FB950),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '-$removals',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in _mockDiffLines)
                        _DiffLineWidget(line: line),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF238636).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF238636).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_fix_high_rounded,
                size: 14,
                color: Color(0xFF3FB950),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fixed token refresh by using refresh_token key '
                  'and passing grantType parameter.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B949E),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.showSnackBarMessage(
                      fixMode == 'pr'
                          ? 'Pull request #48 created with AI fix'
                          : 'Fix pushed to ${buildJob.branch ?? "branch"}',
                    );
                  },
                  icon: Icon(
                    fixMode == 'pr'
                        ? Icons.merge_type_rounded
                        : Icons.upload_rounded,
                    size: 16,
                  ),
                  label: Text(
                    fixMode == 'pr' ? 'Create PR' : 'Push to Branch',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF238636),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _DiffLineType { addition, removal, context }

class _DiffLine {
  const _DiffLine({required this.type, required this.text});
  final _DiffLineType type;
  final String text;
}

class _DiffLineWidget extends StatelessWidget {
  const _DiffLineWidget({required this.line});
  final _DiffLine line;

  @override
  Widget build(BuildContext context) {
    final (prefix, bgColor, textColor) = switch (line.type) {
      _DiffLineType.addition => (
        '+',
        const Color(0xFF3FB950).withValues(alpha: 0.08),
        const Color(0xFF3FB950),
      ),
      _DiffLineType.removal => (
        '-',
        const Color(0xFFFF6B6B).withValues(alpha: 0.08),
        const Color(0xFFFF6B6B),
      ),
      _DiffLineType.context => (
        ' ',
        Colors.transparent,
        const Color(0xFF8B949E),
      ),
    };

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Text(
        '$prefix ${line.text}',
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: textColor,
          height: 1.6,
        ),
      ),
    );
  }
}

class _ProcessingSteps extends HookWidget {
  const _ProcessingSteps({required this.onComplete});
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final currentStep = useState(0);

    useEffect(() {
      Future<void> runSteps() async {
        for (var i = 0; i < 4; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          if (!context.mounted) return;
          currentStep.value = i + 1;
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!context.mounted) return;
        onComplete();
      }

      runSteps();
      return null;
    }, const []);

    const steps = [
      'Analyzing error logs...',
      'Identifying root cause...',
      'Generating code fix...',
      'Validating changes...',
    ];

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _ProcessingStepRow(
            label: steps[i],
            state: i < currentStep.value
                ? 'done'
                : i == currentStep.value
                ? 'active'
                : 'pending',
          ),
          if (i < steps.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ProcessingStepRow extends StatelessWidget {
  const _ProcessingStepRow({
    required this.label,
    required this.state,
  });

  final String label;
  final String state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Center(
              child: switch (state) {
                'done' => const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Color(0xFF3FB950),
                ),
                'active' => const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF58A6FF),
                  ),
                ),
                _ => Icon(
                  Icons.circle_outlined,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              },
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: switch (state) {
                'done' => const Color(0xFF3FB950),
                'active' => const Color(0xFF58A6FF),
                _ => Colors.white.withValues(alpha: 0.3),
              },
              fontWeight: state == 'active' ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _FixOptionTile extends StatelessWidget {
  const _FixOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xFF238636)
        : Colors.white.withValues(alpha: 0.08);
    final bgColor = isSelected
        ? const Color(0xFF238636).withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.02);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              FaIcon(
                icon,
                size: 14,
                color: isSelected
                    ? const Color(0xFF3FB950)
                    : const Color(0xFF8B949E),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF3FB950)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B949E),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Color(0xFF3FB950),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLogsView extends ConsumerWidget {
  const _DetailLogsView({
    required this.buildJob,
    required this.runId,
  });

  final BuildJob buildJob;
  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(buildLogsProvider(buildJob.id, runId));

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Waiting for logs...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        final errorLogs = logs.where((l) => l.level == 'error').toList();
        final lineNumWidth = '${logs.length}'.length;
        final isFailed = buildJob.status == 'failure';

        return Column(
          children: [
            if (isFailed && errorLogs.isNotEmpty)
              _FailureSummaryBanner(
                errorLogs: errorLogs,
                buildJob: buildJob,
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.terminal,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${logs.length} lines',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.3),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        final allLogs = logs.map((l) => l.message).join('\n');
                        Clipboard.setData(ClipboardData(text: allLogs));
                        if (context.mounted) {
                          context.showSnackBarMessage(
                            'Logs copied to clipboard',
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.3),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _LogLine(
                      log: log,
                      lineNumber: index + 1,
                      lineNumWidth: lineNumWidth,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _logFontSize = 12.0;
const _logLineHeight = 1.5;
const _monoStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: _logFontSize,
  height: _logLineHeight,
);

class _LogLine extends HookWidget {
  const _LogLine({
    required this.log,
    required this.lineNumber,
    required this.lineNumWidth,
  });

  final BuildLog log;
  final int lineNumber;
  final int lineNumWidth;

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);
    final lines = log.message.split('\n');
    final isMultiLine = lines.length > 1;

    final levelColor = switch (log.level) {
      'error' => const Color(0xFFFF6B6B),
      'warning' => const Color(0xFFFFB347),
      'success' => const Color(0xFF69DB7C),
      _ => const Color(0xFF8B949E),
    };

    final levelIndicator = switch (log.level) {
      'error' => '✕',
      'warning' => '▲',
      'success' => '✓',
      _ => '·',
    };

    if (!isMultiLine) {
      return _buildSingleLine(levelColor, levelIndicator);
    }

    return _buildMultiLine(levelColor, levelIndicator, lines, isExpanded);
  }

  Widget _buildSingleLine(Color color, String indicator) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lineNum(),
          _separator(),
          _indicator(color, indicator),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              log.message,
              style: _monoStyle.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLine(
    Color color,
    String indicator,
    List<String> lines,
    ValueNotifier<bool> isExpanded,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(
              alpha: isExpanded.value ? 0.15 : 0.08,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => isExpanded.value = !isExpanded.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      _lineNum(),
                      _separator(),
                      _indicator(color, indicator),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lines.first,
                          style: _monoStyle.copyWith(color: color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded.value
                                  ? Icons.unfold_less_rounded
                                  : Icons.unfold_more_rounded,
                              size: 12,
                              color: color,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${lines.length}',
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded.value)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  border: Border(
                    top: BorderSide(
                      color: color.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  log.message,
                  style: _monoStyle.copyWith(color: color),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _lineNum() {
    return SizedBox(
      width: lineNumWidth * 8.0 + 4,
      child: Text(
        '$lineNumber'.padLeft(lineNumWidth),
        style: _monoStyle.copyWith(
          color: Colors.white.withValues(alpha: 0.15),
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '│',
        style: _monoStyle.copyWith(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }

  Widget _indicator(Color color, String text) {
    return SizedBox(
      width: 14,
      child: Text(
        text,
        style: _monoStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
