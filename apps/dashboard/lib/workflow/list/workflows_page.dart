import 'dart:async';

import 'package:dashboard/github/repository_aliases.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/breakpoint.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/list/create_workflow_page.dart';
import 'package:dashboard/workflow/list/github_repository_provider.dart';
import 'package:dashboard/workflow/list/selected_branch_provider.dart';
import 'package:dashboard/workflow/list/selected_repository_provider.dart';
import 'package:dashboard/workflow/list/workflow_file_provider.dart';
import 'package:dashboard/workflow/list/workflow_suggestions_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WorkflowsPage extends ConsumerWidget {
  const WorkflowsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakpoint = Breakpoint.fromWidth(MediaQuery.sizeOf(context).width);
    final showDesktopCreateButton = breakpoint == Breakpoint.desktop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CI/CD設定'),
        leading: IconButton(
          tooltip: 'カンバンに戻る',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/workspace'),
        ),
        actions: [
          IconButton(
            tooltip: 'CI/CD設定を同期',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => unawaited(_syncWorkflows(context, ref)),
          ),
          if (showDesktopCreateButton) ...[
            const SizedBox(width: 4),
            _CreateWorkflowToolbarButton(
              onPressed: () =>
                  unawaited(_openWorkflowEditorWithTargetPicker(context, ref)),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: const WorkflowsBody(),
      floatingActionButton: showDesktopCreateButton
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  unawaited(_openWorkflowEditorWithTargetPicker(context, ref)),
              icon: const Icon(Icons.add_rounded),
              label: const Text('CI/CD設定を作成'),
            ),
    );
  }
}

class _CreateWorkflowToolbarButton extends StatelessWidget {
  const _CreateWorkflowToolbarButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 17),
      label: const Text('CI/CD設定を作成'),
      style: FilledButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.accentOnAccent,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.only(left: 10, right: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }
}

class WorkflowsBody extends ConsumerWidget {
  const WorkflowsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final workflowFilesAsync = ref.watch(workflowFilesProvider);
    final selectedTeamId = ref.watch(selectedTeamIdProvider).value;

    return userAsync.when(
      loading: () => const _WorkflowPageLoadingView(),
      error: asyncErrorWidget,
      data: (user) {
        if (selectedTeamId == null) {
          return const _WorkflowPageLoadingView();
        }
        final workflowTargetsAsync = ref.watch(
          _workflowTargetsProvider(selectedTeamId),
        );
        final repositoriesAsync = ref.watch(gitHubRepositoriesProvider);
        final selectedRepository = ref.watch(selectedRepositoryProvider).value;
        final selectedBranch = ref.watch(selectedBranchProvider).value;
        final workflowTarget = _preferredWorkflowTarget(
          selectedRepository,
          selectedBranch,
          workflowTargetsAsync.value,
          repositoriesAsync.value,
        );
        final workflowTargets = _workflowTargetOptions(
          workflowTargetsAsync.value,
          repositoriesAsync.value,
        );
        return workflowFilesAsync.when(
          loading: () => const _WorkflowPageLoadingView(),
          error: asyncErrorWidget,
          data: (files) {
            if (files.isEmpty) {
              return _EmptyWorkflowsView(
                teamId: selectedTeamId,
                initialTarget: workflowTarget,
                targets: workflowTargets,
                onCreateTemplate: (template, target) => _openWorkflowEditor(
                  context,
                  ref,
                  repositoryOverride: target.repository,
                  branchOverride: target.branch,
                  initialYaml: template.yaml,
                  initialFileName: template.fileName,
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: files.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final file = files[index];
                return _WorkflowListItemFrame(
                  child: _WorkflowFileTile(
                    file: file,
                    repository: file.repository,
                    branch: file.branch,
                    onTap: () => _openWorkflowEditor(
                      context,
                      ref,
                      existingFile: file,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _WorkflowPageLoadingView extends StatelessWidget {
  const _WorkflowPageLoadingView();

  static const _files = [
    WorkflowFile(
      name: 'flutter-ci-cd.yaml',
      path: '.openci/flutter-ci-cd.yaml',
      content: '',
      repository: 'openci-org/openci',
      branch: 'develop',
    ),
    WorkflowFile(
      name: 'deploy.yaml',
      path: '.openci/deploy.yaml',
      content: '',
      repository: 'openci-org/dashboard',
      branch: 'main',
    ),
    WorkflowFile(
      name: 'release.yaml',
      path: '.openci/release.yaml',
      content: '',
      repository: 'openci-org/worker',
      branch: 'main',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _WorkflowLoadingStatusCard(),
                const SizedBox(height: 14),
                Text(
                  'CI/CD設定一覧',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Skeletonizer(
                  child: Column(
                    children: [
                      for (final file in _files) ...[
                        _WorkflowListItemFrame(
                          child: _WorkflowFileTile(
                            file: file,
                            repository: file.repository,
                            branch: file.branch,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkflowLoadingStatusCard extends StatelessWidget {
  const _WorkflowLoadingStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Padding(
              padding: EdgeInsets.all(11),
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CI/CD設定を読み込んでいます',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '選択中の repository から .openci workflow を確認しています。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _workflowTargetsProvider = FutureProvider.autoDispose
    .family<List<_WorkflowTarget>, String>((
      ref,
      teamId,
    ) async {
      final reposAsync = ref.watch(gitHubRepositoriesProvider);
      final repos = reposAsync.value ?? const [];
      if (repos.isEmpty) return const <_WorkflowTarget>[];

      final seen = <String>{};
      final targets = <_WorkflowTarget>[];
      for (final repo in repos) {
        final repository = canonicalRepositoryFullName(repo.fullName);
        if (repository.isEmpty || !seen.add(repository)) continue;
        targets.add(
          _WorkflowTarget(
            repository: repository,
            branch: repo.defaultBranch,
          ),
        );
      }
      targets.sort((a, b) => a.repository.compareTo(b.repository));
      return targets;
    });

class _WorkflowTarget {
  const _WorkflowTarget({
    required this.repository,
    this.branch,
  });

  final String repository;
  final String? branch;
}

_WorkflowTarget? _preferredWorkflowTarget(
  String? selectedRepository,
  String? selectedBranch,
  List<_WorkflowTarget>? targets,
  List<GitHubRepo>? repositories,
) {
  if (selectedRepository != null && selectedRepository.isNotEmpty) {
    final repository = _matchingRepository(repositories, selectedRepository);
    return _WorkflowTarget(
      repository: repository?.fullName ?? selectedRepository,
      branch: _effectiveWorkflowBranch(selectedBranch, repository),
    );
  }

  final target = targets?.firstOrNull;
  if (target == null) return null;
  final repository = _matchingRepository(repositories, target.repository);
  return _WorkflowTarget(
    repository: repository?.fullName ?? target.repository,
    branch: _effectiveWorkflowBranch(target.branch, repository),
  );
}

List<_WorkflowTarget> _workflowTargetOptions(
  List<_WorkflowTarget>? targets,
  List<GitHubRepo>? repositories,
) {
  final options = <_WorkflowTarget>[];
  final seen = <String>{};

  for (final target in targets ?? const <_WorkflowTarget>[]) {
    final repository = _matchingRepository(repositories, target.repository);
    final option = _WorkflowTarget(
      repository: repository?.fullName ?? target.repository,
      branch: _effectiveWorkflowBranch(target.branch, repository) ?? 'main',
    );
    if (seen.add(option.repository)) {
      options.add(option);
    }
  }

  if (options.isEmpty) {
    for (final repository in repositories ?? const <GitHubRepo>[]) {
      final option = _WorkflowTarget(
        repository: repository.fullName,
        branch: repository.defaultBranch,
      );
      if (seen.add(option.repository)) {
        options.add(option);
      }
    }
  }

  options.sort((a, b) => a.repository.compareTo(b.repository));
  return options;
}

String? _effectiveWorkflowBranch(String? branch, GitHubRepo? repository) {
  final value = branch?.trim();
  if (value == null || value.isEmpty || value == 'HEAD') {
    return repository?.defaultBranch;
  }
  return value;
}

GitHubRepo? _matchingRepository(
  List<GitHubRepo>? repositories,
  String repository,
) {
  if (repositories == null || repositories.isEmpty) return null;
  final aliases = repositoryFullNameAliases(repository).toSet();
  for (final candidate in repositories) {
    if (aliases.contains(candidate.fullName) ||
        aliases.contains(canonicalRepositoryFullName(candidate.fullName))) {
      return candidate;
    }
  }
  return null;
}

class _WorkflowListItemFrame extends StatelessWidget {
  const _WorkflowListItemFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: child,
      ),
    );
  }
}

Future<void> _syncWorkflows(BuildContext context, WidgetRef ref) async {
  ref.invalidate(workflowFilesProvider);
  if (context.mounted) {
    context.showSnackBarMessage('CI/CD設定を再読み込みしました');
  }
}

Future<void> _openWorkflowEditorWithTargetPicker(
  BuildContext context,
  WidgetRef ref,
) async {
  final user = ref.read(userProvider).value;
  final selectedTeamId = ref.read(selectedTeamIdProvider).value;
  if (user == null || selectedTeamId == null) {
    context.showSnackBarMessage('Repository と branch を選択してください');
    return;
  }

  final targets = _workflowTargetOptions(
    ref.read(_workflowTargetsProvider(selectedTeamId)).value,
    ref.read(gitHubRepositoriesProvider).value,
  );
  final selectedRepository = ref.read(selectedRepositoryProvider).value;
  final selectedBranch = ref.read(selectedBranchProvider).value;
  final preferredTarget =
      _preferredWorkflowTarget(
        selectedRepository,
        selectedBranch,
        ref.read(_workflowTargetsProvider(selectedTeamId)).value,
        ref.read(gitHubRepositoriesProvider).value,
      ) ??
      targets.firstOrNull;

  final target = targets.length > 1
      ? await _showWorkflowTargetPicker(
          context,
          targets: targets,
          selectedTarget: preferredTarget,
        )
      : preferredTarget;
  if (!context.mounted || target == null) return;

  unawaited(
    ref.read(selectedRepositoryProvider.notifier).save(target.repository),
  );
  if (target.branch != null) {
    unawaited(ref.read(selectedBranchProvider.notifier).save(target.branch!));
  }

  _openWorkflowEditor(
    context,
    ref,
    repositoryOverride: target.repository,
    branchOverride: target.branch,
  );
}

void _openWorkflowEditor(
  BuildContext context,
  WidgetRef ref, {
  WorkflowFile? existingFile,
  String? repositoryOverride,
  String? branchOverride,
  String? initialYaml,
  String? initialFileName,
}) {
  final user = ref.read(userProvider).value;
  final selectedTeamId = ref.read(selectedTeamIdProvider).value;
  final selectedRepository = ref.read(selectedRepositoryProvider).value;
  final selectedBranch = ref.read(selectedBranchProvider).value;
  final repository =
      existingFile?.repository ?? repositoryOverride ?? selectedRepository;
  final branch =
      existingFile?.branch ?? branchOverride ?? selectedBranch ?? 'main';

  if (user == null || repository == null || selectedTeamId == null) {
    context.showSnackBarMessage('Repository と branch を選択してください');
    return;
  }

  unawaited(ref.read(selectedRepositoryProvider.notifier).save(repository));
  unawaited(ref.read(selectedBranchProvider.notifier).save(branch));

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CreateWorkflowPage(
        repository: repository,
        branch: branch,
        teamId: selectedTeamId,
        existingFile: existingFile,
        initialYaml: initialYaml,
        initialFileName: initialFileName,
      ),
    ),
  );
}

Future<_WorkflowTarget?> _showWorkflowTargetPicker(
  BuildContext context, {
  required List<_WorkflowTarget> targets,
  required _WorkflowTarget? selectedTarget,
}) {
  return showModalBottomSheet<_WorkflowTarget>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'セットアップする repository',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'CI/CD workflow を作成する対象を選んでください。',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  shrinkWrap: true,
                  itemCount: targets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final target = targets[index];
                    final selected =
                        selectedTarget?.repository == target.repository;
                    return _WorkflowTargetTile(
                      target: target,
                      selected: selected,
                      onTap: () => Navigator.of(context).pop(target),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _WorkflowFileTile extends ConsumerWidget {
  const _WorkflowFileTile({
    required this.file,
    required this.repository,
    required this.branch,
    required this.onTap,
  });

  final WorkflowFile file;
  final String repository;
  final String branch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    final details = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$repository · $branch · ${file.path}',
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.schema_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              details,
              SizedBox(width: compact ? 4 : 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowTargetTile extends StatelessWidget {
  const _WorkflowTargetTile({
    required this.target,
    required this.selected,
    required this.onTap,
  });

  final _WorkflowTarget target;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.folder_outlined,
                  size: 20,
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.repository,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target.branch ?? 'main',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWorkflowsView extends ConsumerStatefulWidget {
  const _EmptyWorkflowsView({
    required this.teamId,
    required this.initialTarget,
    required this.targets,
    required this.onCreateTemplate,
  });

  final String teamId;
  final _WorkflowTarget? initialTarget;
  final List<_WorkflowTarget> targets;
  final void Function(_WorkflowTemplate template, _WorkflowTarget target)
  onCreateTemplate;

  @override
  ConsumerState<_EmptyWorkflowsView> createState() =>
      _EmptyWorkflowsViewState();
}

class _EmptyWorkflowsViewState extends ConsumerState<_EmptyWorkflowsView> {
  bool _suggestionsAllowed = false;
  _WorkflowTarget? _selectedTarget;

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.initialTarget ?? widget.targets.firstOrNull;
  }

  @override
  void didUpdateWidget(covariant _EmptyWorkflowsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedTarget = _selectedTarget;
    final stillAvailable =
        selectedTarget != null &&
        widget.targets.any(
          (target) => target.repository == selectedTarget.repository,
        );
    if (!stillAvailable) {
      _selectedTarget = widget.initialTarget ?? widget.targets.firstOrNull;
      _suggestionsAllowed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTarget = _selectedTarget;
    final repository = selectedTarget?.repository;
    final branch = selectedTarget?.branch ?? 'main';
    final suggestionRequest = repository == null
        ? null
        : WorkflowSuggestionRequest(
            teamId: widget.teamId,
            repository: repository,
            branch: branch,
          );
    final suggestionsAsync = _suggestionsAllowed && suggestionRequest != null
        ? ref.watch(workflowSuggestionsProvider(suggestionRequest))
        : null;
    final isLoadingSuggestions = suggestionsAsync?.isLoading == true;
    final suggestedTemplates = suggestionsAsync?.value?.suggestions
        .map(_WorkflowTemplate.fromSuggestion)
        .toList();
    final templates =
        !isLoadingSuggestions && suggestedTemplates?.isNotEmpty == true
        ? suggestedTemplates!
        : _workflowTemplates;
    final isShowingSuggestions = suggestedTemplates?.isNotEmpty == true;
    final repositoryLabel = repository ?? '連携済みの GitHub repo';
    final analysisSummary = suggestionsAsync?.value?.analysisSummary;
    final detectedProjectType = suggestionsAsync?.value?.detectedProjectType;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WorkflowIntroCard(
                  repositoryLabel: repositoryLabel,
                  branch: branch,
                ),
                const SizedBox(height: 14),
                _WorkflowTargetSelectorCard(
                  target: selectedTarget,
                  targetCount: widget.targets.length,
                  onPressed: widget.targets.length <= 1
                      ? null
                      : () => unawaited(_selectTarget(context)),
                ),
                const SizedBox(height: 14),
                _WorkflowSuggestionConsentCard(
                  repository: repository,
                  isAllowed: _suggestionsAllowed,
                  isLoading: suggestionsAsync?.isLoading == true,
                  error: suggestionsAsync?.hasError == true,
                  onAllow: repository == null
                      ? null
                      : () {
                          setState(() {
                            _suggestionsAllowed = true;
                          });
                        },
                  onRetry: suggestionRequest == null
                      ? null
                      : () => ref.invalidate(
                          workflowSuggestionsProvider(suggestionRequest),
                        ),
                ),
                if (analysisSummary != null && analysisSummary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _WorkflowAnalysisCard(
                    detectedProjectType: detectedProjectType ?? '',
                    analysisSummary: analysisSummary,
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  isLoadingSuggestions
                      ? '提案を準備中'
                      : isShowingSuggestions
                      ? '提案から始める'
                      : 'テンプレートから始める',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                if (isLoadingSuggestions)
                  const _WorkflowSuggestionLoadingPanel()
                else
                  for (final template in templates) ...[
                    _WorkflowTemplateCard(
                      template: template,
                      isSuggestion: isShowingSuggestions,
                      onPressed: selectedTarget == null
                          ? () => unawaited(_selectTarget(context))
                          : () => widget.onCreateTemplate(
                              template,
                              selectedTarget,
                            ),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTarget(BuildContext context) async {
    final target = await _showWorkflowTargetPicker(
      context,
      targets: widget.targets,
      selectedTarget: _selectedTarget,
    );
    if (!mounted || target == null) return;
    setState(() {
      _selectedTarget = target;
      _suggestionsAllowed = false;
    });
  }
}

class _WorkflowTargetSelectorCard extends StatelessWidget {
  const _WorkflowTargetSelectorCard({
    required this.target,
    required this.targetCount,
    required this.onPressed,
  });

  final _WorkflowTarget? target;
  final int targetCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final target = this.target;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.folder_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'セットアップ対象',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  target?.repository ?? 'Repository を選択してください',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (target != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'branch: ${target.branch ?? 'main'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(
              targetCount > 1 ? Icons.swap_horiz_rounded : Icons.check_rounded,
              size: 18,
            ),
            label: Text(targetCount > 1 ? '変更' : '選択済み'),
          ),
        ],
      ),
    );
  }
}

class _WorkflowSuggestionLoadingPanel extends StatelessWidget {
  const _WorkflowSuggestionLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'リポジトリの構成を確認しています',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'manifest とディレクトリ構成から、合いそうなテンプレートを選んでいます。',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Skeletonizer(
            child: Column(
              children: [
                _WorkflowSuggestionLoadingRow(
                  title: 'Flutter の基本チェック',
                  description: '依存関係の取得、静的解析、テスト',
                ),
                SizedBox(height: 10),
                _WorkflowSuggestionLoadingRow(
                  title: 'Node.js の基本チェック',
                  description: 'install、lint、test、build',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowSuggestionLoadingRow extends StatelessWidget {
  const _WorkflowSuggestionLoadingRow({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowIntroCard extends StatelessWidget {
  const _WorkflowIntroCard({
    required this.repositoryLabel,
    required this.branch,
  });

  final String repositoryLabel;
  final String branch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'この repo で何を自動化しますか？',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CI/CD設定は、push や PR をきっかけにテスト、ビルド、デプロイを自動で実行する手順です。'
            '$repositoryLabel ($branch) ですぐ使える CI/CD のたたき台を選べます。',
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _WorkflowTermChip(label: 'Trigger', description: 'いつ実行するか'),
              _WorkflowTermChip(label: 'Job', description: '実行する作業'),
              _WorkflowTermChip(label: 'Step', description: '実際のコマンド'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkflowTermChip extends StatelessWidget {
  const _WorkflowTermChip({
    required this.label,
    required this.description,
  });

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label = $description',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF475569),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkflowSuggestionConsentCard extends StatelessWidget {
  const _WorkflowSuggestionConsentCard({
    required this.repository,
    required this.isAllowed,
    required this.isLoading,
    required this.error,
    required this.onAllow,
    required this.onRetry,
  });

  final String? repository;
  final bool isAllowed;
  final bool isLoading;
  final bool error;
  final VoidCallback? onAllow;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final canRun = repository != null && repository!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ファイル構成からテンプレートを提案できます',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  canRun
                      ? '$repository の manifest やディレクトリ構成を確認し、OpenCI向けのCI/CD候補を選びます。'
                      : 'Repository が選択されると、ファイル構成に合わせたテンプレートを提案できます。',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ファイル構成を確認中...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  )
                else if (error)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'テンプレート提案に失敗しました。標準テンプレートはそのまま使えます。',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('再実行'),
                      ),
                    ],
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: isAllowed ? onRetry : onAllow,
                    icon: Icon(
                      isAllowed
                          ? Icons.refresh_rounded
                          : Icons.account_tree_rounded,
                    ),
                    label: Text(isAllowed ? 'もう一度確認する' : 'ファイル構成から提案する'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowAnalysisCard extends StatelessWidget {
  const _WorkflowAnalysisCard({
    required this.detectedProjectType,
    required this.analysisSummary,
  });

  final String detectedProjectType;
  final String analysisSummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detectedProjectType.isNotEmpty) ...[
            Text(
              detectedProjectType,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            analysisSummary,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowTemplateCard extends StatelessWidget {
  const _WorkflowTemplateCard({
    required this.template,
    required this.isSuggestion,
    required this.onPressed,
  });

  final _WorkflowTemplate template;
  final bool isSuggestion;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: template.iconBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(template.icon, color: template.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSuggestion) ...[
                          const _WorkflowSuggestionBadge(),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          template.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          template.description,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final step in template.steps)
                    Chip(
                      label: Text(step),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (template.requiredSecrets.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final secret in template.requiredSecrets)
                      Chip(
                        avatar: const Icon(Icons.key_rounded, size: 14),
                        label: Text(secret),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFFFFBEB),
                        side: const BorderSide(color: Color(0xFFFDE68A)),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onPressed,
                  icon: Icon(
                    isSuggestion
                        ? Icons.arrow_forward_rounded
                        : Icons.add_rounded,
                  ),
                  label: Text(isSuggestion ? '作成画面へ' : 'このまま作成'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowSuggestionBadge extends StatelessWidget {
  const _WorkflowSuggestionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E8FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: const Text(
        'コードベースからの提案',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6D28D9),
        ),
      ),
    );
  }
}

class _WorkflowTemplate {
  const _WorkflowTemplate({
    required this.title,
    required this.description,
    required this.fileName,
    required this.steps,
    required this.yaml,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.requiredSecrets = const [],
  });

  factory _WorkflowTemplate.fromSuggestion(WorkflowSuggestion suggestion) {
    return _WorkflowTemplate(
      title: suggestion.title,
      description: suggestion.description,
      fileName: suggestion.fileName,
      steps: suggestion.steps,
      yaml: suggestion.yaml,
      requiredSecrets: suggestion.requiredSecrets,
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFF7C3AED),
      iconBackground: const Color(0xFFF5E8FF),
    );
  }

  final String title;
  final String description;
  final String fileName;
  final List<String> steps;
  final String yaml;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final List<String> requiredSecrets;
}

const _workflowTemplates = [
  _WorkflowTemplate(
    title: 'Flutter / Dart の PR チェック',
    description: 'PR や push のたびに依存関係、静的解析、テストを実行します。まず失敗に気づける CI を作るならこれです。',
    fileName: 'flutter-pr-check.yaml',
    steps: ['flutter pub get', 'flutter analyze', 'flutter test'],
    icon: Icons.phone_iphone_rounded,
    iconColor: Color(0xFF0284C7),
    iconBackground: Color(0xFFE0F2FE),
    yaml: '''
name: Flutter PR checks

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop

jobs:
  checks:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Install dependencies
        run: flutter pub get
      - name: Analyze
        run: flutter analyze
      - name: Test
        run: flutter test
''',
  ),
  _WorkflowTemplate(
    title: 'Web / Firebase デプロイ前チェック',
    description: 'main に入る前に Flutter Web のビルドまで確認します。デプロイは確認後に足せる安全な土台です。',
    fileName: 'web-build-check.yaml',
    steps: ['flutter analyze', 'flutter test', 'flutter build web'],
    icon: Icons.public_rounded,
    iconColor: Color(0xFF16A34A),
    iconBackground: Color(0xFFDCFCE7),
    yaml: '''
name: Web build check

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build-web:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Install dependencies
        run: flutter pub get
      - name: Analyze
        run: flutter analyze
      - name: Test
        run: flutter test
      - name: Build web
        run: flutter build web
''',
  ),
  _WorkflowTemplate(
    title: 'Node / Firebase Functions のチェック',
    description:
        'Functions や Web フロントの Node プロジェクト向けに、install、lint、test、build をまとめて確認します。',
    fileName: 'node-functions-check.yaml',
    steps: ['npm ci', 'npm run lint', 'npm test', 'npm run build'],
    icon: Icons.cloud_queue_rounded,
    iconColor: Color(0xFFEA580C),
    iconBackground: Color(0xFFFFEDD5),
    yaml: '''
name: Node checks

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop

jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - name: Install dependencies
        run: npm ci
      - name: Lint
        run: npm run lint --if-present
      - name: Test
        run: npm test --if-present
      - name: Build
        run: npm run build --if-present
''',
  ),
];
