import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_logs_provider.dart';
import 'package:dashboard/build_logs/cicd_fix_provider.dart';
import 'package:dashboard/build_logs/synced_spinner.dart';
import 'package:dashboard/firebase/firestore.dart' show BuildJobStatus;
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/function_error_message.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum _ActionState { idle, loading, done }

void _showMaterialDefaultSnackBar(BuildContext context, String message) {
  showResponsiveSnackBar(
    context,
    content: Text(message),
  );
}

class BuildLogsDetailPage extends HookConsumerWidget {
  const BuildLogsDetailPage({
    super.key,
    required this.buildJob,
    this.showBackButton = true,
  });

  final BuildJob buildJob;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowName = buildJob.workflowName;
    final workflowJobKey = buildJob.workflowJobKey;
    final jobKey = (workflowJobKey != null && workflowJobKey.isNotEmpty)
        ? workflowJobKey
        : buildJob.jobKey;
    final matrixLabel = buildJob.matrixLabel;
    final detailT = t.buildLogs.detail;
    final retryState = useState(_ActionState.idle);

    final statusColor = switch (buildJob.status) {
      BuildJobStatus.SUCCESS => const Color(0xFF3FB950),
      BuildJobStatus.FAILURE => const Color(0xFFF85149),
      BuildJobStatus.IN_PROGRESS => const Color(0xFF58A6FF),
      BuildJobStatus.QUEUED => const Color(0xFFBC8CFF),
      BuildJobStatus.CANCELLED => const Color(0xFFD29922),
      BuildJobStatus.WAITING => const Color(0xFFD29922),
      BuildJobStatus.SKIPPED => AppColors.of(context).textTertiary,
      BuildJobStatus.TIMED_OUT => const Color(0xFFF85149),
    };

    final statusIcon = switch (buildJob.status) {
      BuildJobStatus.SUCCESS => Icons.check_circle_rounded,
      BuildJobStatus.FAILURE => Icons.cancel_rounded,
      BuildJobStatus.IN_PROGRESS => Icons.help_outline_rounded,
      BuildJobStatus.QUEUED => Icons.schedule_rounded,
      BuildJobStatus.CANCELLED => Icons.block_rounded,
      BuildJobStatus.WAITING => Icons.adjust_rounded,
      BuildJobStatus.SKIPPED => Icons.skip_next_rounded,
      BuildJobStatus.TIMED_OUT => Icons.timer_off_rounded,
    };

    final statusLabel = switch (buildJob.status) {
      BuildJobStatus.SUCCESS => t.buildLogs.status.success,
      BuildJobStatus.FAILURE => t.buildLogs.status.failed,
      BuildJobStatus.IN_PROGRESS => t.buildLogs.status.inProgress,
      BuildJobStatus.QUEUED => t.buildLogs.status.queued,
      BuildJobStatus.CANCELLED => t.buildLogs.status.cancelled,
      BuildJobStatus.WAITING => 'Waiting',
      BuildJobStatus.SKIPPED => 'Skipped',
      BuildJobStatus.TIMED_OUT => 'Timed out',
    };

    final canCancel =
        buildJob.status == BuildJobStatus.QUEUED ||
        buildJob.status == BuildJobStatus.IN_PROGRESS;

    return SyncedSpinnerScope(
      child: Scaffold(
        backgroundColor: AppColors.of(context).scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.of(context).surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: showBackButton,
          leading: showBackButton
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppColors.of(context).textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          titleSpacing: showBackButton ? null : 16,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workflowName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.of(context).textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if ((jobKey?.isNotEmpty ?? false) ||
                  (matrixLabel?.isNotEmpty ?? false))
                Text(
                  [
                    if (jobKey?.isNotEmpty ?? false) jobKey!,
                    if (matrixLabel?.isNotEmpty ?? false) matrixLabel!,
                  ].join(' / '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
            ],
          ),
          actions: [
            if (canCancel)
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.of(context).surfaceHover,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.of(context).border,
                        ),
                      ),
                      title: Text(
                        detailT.cancelBuild,
                        style: TextStyle(
                          color: AppColors.of(context).textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text(
                        detailT.cancelConfirm,
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            detailT.cancelNo,
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF85149),
                          ),
                          child: Text(detailT.cancelBuild),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  try {
                    if (!context.mounted) return;
                    context.showSnackBarMessage(detailT.cancelling);
                    await ref
                        .read(buildJobsProvider.notifier)
                        .cancelBuildJob(buildJob.id);
                    if (context.mounted) {
                      context.showSnackBarMessage(detailT.buildCancelled);
                    }
                  } on FirebaseFunctionsException catch (e, s) {
                    final errorMessage = await FunctionErrorMessage.capture(
                      e,
                      stackTrace: s,
                    );
                    if (context.mounted) {
                      context.showSnackBarMessage(errorMessage.message);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.showSnackBarMessage(
                        detailT.failedToCancel(error: e.toString()),
                      );
                    }
                  }
                },
                icon: Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: const Color(0xFFD29922).withValues(alpha: 0.7),
                ),
                tooltip: t.common.cancel,
              ),
            IconButton(
              onPressed: retryState.value != _ActionState.idle
                  ? null
                  : () async {
                      retryState.value = _ActionState.loading;
                      try {
                        if (context.mounted) {
                          _showMaterialDefaultSnackBar(
                            context,
                            detailT.retrySuccess,
                          );
                        }
                        await ref
                            .read(buildJobsProvider.notifier)
                            .retryBuildJob(buildJob.id);
                        retryState.value = _ActionState.done;
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (context.mounted) {
                            retryState.value = _ActionState.idle;
                          }
                        });
                      } on FirebaseFunctionsException catch (e, s) {
                        final errorMessage = await FunctionErrorMessage.capture(
                          e,
                          stackTrace: s,
                        );
                        if (context.mounted) {
                          retryState.value = _ActionState.idle;
                        }
                        if (context.mounted) {
                          _showMaterialDefaultSnackBar(
                            context,
                            errorMessage.message,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          retryState.value = _ActionState.idle;
                        }
                        if (context.mounted) {
                          _showMaterialDefaultSnackBar(
                            context,
                            detailT.failedToRetry(error: e.toString()),
                          );
                        }
                      }
                    },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: switch (retryState.value) {
                  _ActionState.loading => SizedBox(
                    key: const ValueKey('retry-loading'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ),
                  _ActionState.done => const Icon(
                    Icons.check_rounded,
                    key: ValueKey('retry-check'),
                    size: 18,
                    color: Color(0xFF3FB950),
                  ),
                  _ActionState.idle => Icon(
                    Icons.replay_rounded,
                    key: const ValueKey('retry-icon'),
                    size: 18,
                    color: AppColors.of(context).textSecondary,
                  ),
                },
              ),
              tooltip: '再実行',
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: AppColors.of(context).divider,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status bar ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.of(context).surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.of(context).divider,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (buildJob.status == BuildJobStatus.IN_PROGRESS)
                              SyncedSpinner(
                                size: 14,
                                strokeWidth: 1.5,
                                color: statusColor,
                              )
                            else
                              Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${buildJob.owner}/${buildJob.repo}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.of(context).textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (buildJob.branch != null)
                        _DetailGitChip(
                          icon: FontAwesomeIcons.codeBranch,
                          label: buildJob.branch!,
                          color: const Color(0xFFBC8CFF),
                        ),
                      if (buildJob.pullRequestNumber != null)
                        _DetailGitChip(
                          icon: FontAwesomeIcons.codePullRequest,
                          label: '#${buildJob.pullRequestNumber}',
                          color: const Color(0xFF3FB950),
                        ),
                      if (buildJob.tagName != null)
                        _DetailGitChip(
                          icon: FontAwesomeIcons.tag,
                          label: buildJob.tagName!,
                          color: const Color(0xFFD29922),
                        ),
                      if (buildJob.commitSha != null)
                        _DetailGitChip(
                          icon: FontAwesomeIcons.codeCommit,
                          label: buildJob.commitSha!.substring(0, 7),
                          color: AppColors.of(context).textTertiary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // ── AI CI/CD Fix entry point ───────────────────────────────────
            Consumer(
              builder: (context, ref, _) {
                final aiEnabled =
                    ref.watch(teamStateProvider).value?.aiEnabled ?? true;
                final canSuggestFix =
                    buildJob.status == BuildJobStatus.FAILURE ||
                    buildJob.status == BuildJobStatus.TIMED_OUT;
                if (!aiEnabled || !canSuggestFix) {
                  return const SizedBox.shrink();
                }
                final fixAsync = ref.watch(ciCdFixRequestProvider(buildJob.id));
                return _AiCiCdFixCard(
                  buildJob: buildJob,
                  fixRequest: fixAsync.asData?.value,
                );
              },
            ),
            // ── AI Failure Summary ─────────────────────────────────────────
            Consumer(
              builder: (context, ref, _) {
                final aiEnabled =
                    ref.watch(teamStateProvider).value?.aiEnabled ?? true;
                if (!aiEnabled) return const SizedBox.shrink();
                if (buildJob.status != BuildJobStatus.FAILURE ||
                    buildJob.failureSummaryStatus == null) {
                  return const SizedBox.shrink();
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: _FailureSummaryCard(
                    status: buildJob.failureSummaryStatus!,
                    summary: buildJob.failureSummary,
                    model: buildJob.failureSummaryModel,
                    durationMs: buildJob.failureSummaryDurationMs,
                  ),
                );
              },
            ),
            // ── Log content ───────────────────────────────────────────────
            Expanded(
              child: buildJob.latestRunId != null
                  ? _DetailLogsView(
                      buildJobId: buildJob.id,
                      runId: buildJob.latestRunId!,
                      buildStatus: buildJob.status,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.of(context).borderSubtle,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.hourglass_empty_rounded,
                              size: 28,
                              color: AppColors.of(context).border,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            detailT.noRuns,
                            style: TextStyle(
                              color: AppColors.of(context).textTertiary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiCiCdFixCard extends HookConsumerWidget {
  const _AiCiCdFixCard({
    required this.buildJob,
    required this.fixRequest,
  });

  final BuildJob buildJob;
  final CiCdFixRequest? fixRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStarting = useState(false);
    final detailT = t.buildLogs.detail;
    const accentColor = Color(0xFF58A6FF);
    final fix = fixRequest;
    final isWorking = isStarting.value || (fix?.status.isWorking ?? false);
    final hasPreview = fix?.status.hasPreview ?? false;
    final isFailed = fix?.status == CiCdFixStatus.failed;
    final targetParts = [
      if ((fix?.repository ?? '').isNotEmpty)
        fix!.repository
      else
        '${buildJob.owner}/${buildJob.repo}',
      if ((fix?.branch ?? buildJob.branch)?.isNotEmpty == true)
        (fix?.branch ?? buildJob.branch)!,
      if ((fix?.workflowPath ?? buildJob.workflowFileName)?.isNotEmpty == true)
        (fix?.workflowPath ?? buildJob.workflowFileName)!,
      if ((fix?.jobKey ?? buildJob.jobKey)?.isNotEmpty == true)
        (fix?.jobKey ?? buildJob.jobKey)!,
    ];
    final title = switch (fix?.status) {
      CiCdFixStatus.queued ||
      CiCdFixStatus.collectingContext ||
      CiCdFixStatus.generatingFix => 'CI/CD設定を修正中',
      CiCdFixStatus.ready => 'CI/CD修正案ができました',
      CiCdFixStatus.failed => 'CI/CD修正に失敗しました',
      CiCdFixStatus.committed => 'このブランチにコミット済み',
      CiCdFixStatus.prCreated => '修正PRを作成済み',
      _ => detailT.aiFixTitle,
    };
    final description = switch (fix?.status) {
      CiCdFixStatus.queued => '修正リクエストを受け付けました。ログとCI/CD設定を読み込みます。',
      CiCdFixStatus.collectingContext => '対象ブランチからCI/CD設定と失敗ログを集めています。',
      CiCdFixStatus.generatingFix => '修正案の差分を生成しています。',
      CiCdFixStatus.ready =>
        '${fix?.files.length ?? 0}ファイルの修正案をレビューできます。内容を確認してから反映してください。',
      CiCdFixStatus.failed => fix?.error ?? '修正案を生成できませんでした。もう一度依頼できます。',
      CiCdFixStatus.committed =>
        '修正は ${fix?.branch ?? '対象ブランチ'} に反映済みです。必要ならログを再実行してください。',
      CiCdFixStatus.prCreated => '修正PRを作成しました。GitHubでレビューしてマージできます。',
      _ => detailT.aiFixDescription,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        border: Border(
          bottom: BorderSide(color: AppColors.of(context).divider),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 520;
            final content = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isWorking
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor.withValues(alpha: 0.9),
                          ),
                        )
                      : Icon(
                          Icons.auto_fix_high_rounded,
                          size: 18,
                          color: accentColor.withValues(alpha: 0.9),
                        ),
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        targetParts.join(' / '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.of(context).textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final action = FilledButton.icon(
              onPressed: isWorking
                  ? null
                  : hasPreview
                  ? () => _showAiCiCdFixPreviewDialog(context, buildJob, fix!)
                  : () async {
                      isStarting.value = true;
                      try {
                        await ref
                            .read(ciCdFixActionsProvider)
                            .start(buildJob.id);
                        if (context.mounted) {
                          context.showSnackBarMessage('CI/CD修正を依頼しました');
                        }
                      } on FirebaseFunctionsException catch (e, s) {
                        final errorMessage = await FunctionErrorMessage.capture(
                          e,
                          stackTrace: s,
                        );
                        if (context.mounted) {
                          final message =
                              e.code == 'not-found' &&
                                  errorMessage.message == 'NOT FOUND'
                              ? 'CI/CD修正用のFunctionsがまだデプロイされていません'
                              : errorMessage.message;
                          context.showSnackBarMessage(message);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          context.showSnackBarMessage(e.toString());
                        }
                      } finally {
                        if (context.mounted) {
                          isStarting.value = false;
                        }
                      }
                    },
              icon: isWorking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      hasPreview
                          ? Icons.rate_review_rounded
                          : isFailed
                          ? Icons.refresh_rounded
                          : Icons.arrow_forward_rounded,
                      size: 16,
                    ),
              label: Text(
                isWorking
                    ? '修正中...'
                    : hasPreview
                    ? '修正案を見る'
                    : isFailed
                    ? 'もう一度依頼'
                    : detailT.aiFixButton,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  const SizedBox(height: 12),
                  action,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 14),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> _showAiCiCdFixPreviewDialog(
  BuildContext context,
  BuildJob buildJob,
  CiCdFixRequest fixRequest,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AiCiCdFixReviewDialog(
      buildJob: buildJob,
      fixRequest: fixRequest,
    ),
  );
}

class _AiCiCdFixReviewDialog extends StatelessWidget {
  const _AiCiCdFixReviewDialog({
    required this.buildJob,
    required this.fixRequest,
  });

  final BuildJob buildJob;
  final CiCdFixRequest fixRequest;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      backgroundColor: AppColors.of(context).surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.of(context).border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
        child: Column(
          children: [
            _AiFixReviewHeader(buildJob: buildJob, fixRequest: fixRequest),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 760;
                  final details = _AiFixReviewDetails(
                    buildJob: buildJob,
                    fixRequest: fixRequest,
                  );
                  final diff = _AiFixDiffPanel(fixRequest: fixRequest);

                  if (isNarrow) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        details,
                        const SizedBox(height: 14),
                        diff,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 320,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: details,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: AppColors.of(context).divider,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: diff,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _AiFixReviewActions(fixRequest: fixRequest),
          ],
        ),
      ),
    );
  }
}

class _AiFixReviewHeader extends StatelessWidget {
  const _AiFixReviewHeader({
    required this.buildJob,
    required this.fixRequest,
  });

  final BuildJob buildJob;
  final CiCdFixRequest fixRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        border: Border(
          bottom: BorderSide(color: AppColors.of(context).divider),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF58A6FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_fix_high_rounded,
              color: Color(0xFF58A6FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'CI/CD修正案',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AiFixStatusChip(label: fixRequest.status.label),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${fixRequest.repository} / ${fixRequest.branch} / ${fixRequest.workflowPath}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.of(context).textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFixStatusChip extends StatelessWidget {
  const _AiFixStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF3FB950).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF3FB950).withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          color: Color(0xFF2DA44E),
        ),
      ),
    );
  }
}

class _AiFixReviewDetails extends StatelessWidget {
  const _AiFixReviewDetails({
    required this.buildJob,
    required this.fixRequest,
  });

  final BuildJob buildJob;
  final CiCdFixRequest fixRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AiFixSection(
          title: '失敗原因',
          icon: Icons.report_problem_rounded,
          child: Text(
            fixRequest.failureReason.isEmpty
                ? '失敗ログから修正案を生成しました。'
                : fixRequest.failureReason,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AiFixSection(
          title: '修正内容',
          icon: Icons.checklist_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in fixRequest.fixSummary)
                _AiFixBullet(text: item),
              if (fixRequest.fixSummary.isEmpty)
                const _AiFixBullet(text: 'CI/CD設定の差分を生成しました。'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AiFixSection(
          title: '対象',
          icon: Icons.account_tree_rounded,
          child: Column(
            children: [
              _AiFixTargetRow(
                label: 'repo',
                value: fixRequest.repository.isEmpty
                    ? '${buildJob.owner}/${buildJob.repo}'
                    : fixRequest.repository,
              ),
              _AiFixTargetRow(label: 'branch', value: fixRequest.branch),
              _AiFixTargetRow(
                label: 'workflow',
                value: fixRequest.workflowPath,
              ),
              if (fixRequest.jobKey != null && fixRequest.jobKey!.isNotEmpty)
                _AiFixTargetRow(label: 'job', value: fixRequest.jobKey!),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AiFixSection(
          title: '変更ファイル',
          icon: Icons.description_rounded,
          child: Column(
            children: [
              for (final file in fixRequest.files)
                _AiFixChangedFileTile(file: file),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AiFixWarningBox(warnings: fixRequest.warnings),
      ],
    );
  }
}

class _AiFixSection extends StatelessWidget {
  const _AiFixSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).borderSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.of(context).textTertiary),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _AiFixBullet extends StatelessWidget {
  const _AiFixBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF58A6FF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.of(context).textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFixChangedFileTile extends StatelessWidget {
  const _AiFixChangedFileTile({required this.file});

  final CiCdFixFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.of(context).divider),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 14,
            color: AppColors.of(context).textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.of(context).textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${file.added} -${file.removed}',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: AppColors.of(context).textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFixWarningBox extends StatelessWidget {
  const _AiFixWarningBox({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFD29922).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD29922).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Color(0xFFD29922),
              ),
              SizedBox(width: 7),
              Text(
                '確認が必要',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD29922),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                warning,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AiFixDiffPanel extends StatelessWidget {
  const _AiFixDiffPanel({required this.fixRequest});

  final CiCdFixRequest fixRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '差分レビュー',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '生成された変更案です。反映前に内容を確認してください。',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.of(context).textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        for (final file in fixRequest.files) ...[
          _AiFixFileDiff(file: file),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AiFixFileDiff extends StatelessWidget {
  const _AiFixFileDiff({required this.file});

  final CiCdFixFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppColors.of(context).borderSubtle,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    file.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                ),
                Text(
                  '+${file.added} -${file.removed}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF2DA44E),
                  ),
                ),
              ],
            ),
          ),
          for (final line in file.lines) _AiFixDiffLineView(line: line),
        ],
      ),
    );
  }
}

class _AiFixDiffLineView extends StatelessWidget {
  const _AiFixDiffLineView({required this.line});

  final CiCdFixDiffLine line;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (line.kind) {
      CiCdFixDiffLineKind.added => const Color(
        0xFF2DA44E,
      ).withValues(alpha: 0.12),
      CiCdFixDiffLineKind.removed => const Color(
        0xFFF85149,
      ).withValues(alpha: 0.11),
      CiCdFixDiffLineKind.context => Colors.transparent,
    };
    final marker = switch (line.kind) {
      CiCdFixDiffLineKind.added => '+',
      CiCdFixDiffLineKind.removed => '-',
      CiCdFixDiffLineKind.context => ' ',
    };
    final markerColor = switch (line.kind) {
      CiCdFixDiffLineKind.added => const Color(0xFF2DA44E),
      CiCdFixDiffLineKind.removed => const Color(0xFFF85149),
      CiCdFixDiffLineKind.context => AppColors.of(context).textTertiary,
    };

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Text(
              marker,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: markerColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              line.text,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                fontFamily: 'monospace',
                color: AppColors.of(context).textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFixReviewActions extends HookConsumerWidget {
  const _AiFixReviewActions({required this.fixRequest});

  final CiCdFixRequest fixRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runningAction = useState<String?>(null);
    final instructionController = useTextEditingController();
    final canApply = fixRequest.status == CiCdFixStatus.ready;
    final isCreatingPr = runningAction.value == 'pr';
    final isCommitting = runningAction.value == 'commit';
    final isRevising = runningAction.value == 'revise';

    Future<void> runAction(String action, Future<void> Function() body) async {
      runningAction.value = action;
      try {
        await body();
        if (context.mounted) {
          final message = switch (action) {
            'pr' => '修正PRを作成しました',
            'revise' => '要望を反映した修正案を作成します',
            _ => '対象ブランチにコミットしました',
          };
          context.showSnackBarMessage(message);
          Navigator.of(context).pop();
        }
      } on FirebaseFunctionsException catch (e, s) {
        final errorMessage = await FunctionErrorMessage.capture(
          e,
          stackTrace: s,
        );
        if (context.mounted) {
          context.showSnackBarMessage(errorMessage.message);
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnackBarMessage(e.toString());
        }
      } finally {
        if (context.mounted) runningAction.value = null;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        border: Border(top: BorderSide(color: AppColors.of(context).divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: instructionController,
            enabled: canApply && runningAction.value == null,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: '修正案への要望を書く。例: deploy job は触らず test job だけ直して',
              prefixIcon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
              ),
              filled: true,
              fillColor: AppColors.of(context).borderSubtle,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.of(context).border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.of(context).border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF58A6FF)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('破棄'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: canApply && runningAction.value == null
                    ? () {
                        final instruction = instructionController.text.trim();
                        if (instruction.isEmpty) {
                          context.showSnackBarMessage('修正方針を入力してください');
                          return;
                        }
                        runAction(
                          'revise',
                          () => ref
                              .read(ciCdFixActionsProvider)
                              .revise(
                                requestId: fixRequest.id,
                                instruction: instruction,
                              ),
                        );
                      }
                    : null,
                icon: isRevising
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('要望を反映して再生成'),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: canApply && runningAction.value == null
                    ? () => runAction(
                        'pr',
                        () => ref
                            .read(ciCdFixActionsProvider)
                            .createPullRequest(fixRequest.id),
                      )
                    : null,
                icon: isCreatingPr
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.call_merge_rounded, size: 16),
                label: const Text('PRを作成'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: canApply && runningAction.value == null
                    ? () => runAction(
                        'commit',
                        () => ref
                            .read(ciCdFixActionsProvider)
                            .commit(fixRequest.id),
                      )
                    : null,
                icon: isCommitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.commit_rounded, size: 16),
                label: const Text('このブランチにコミット'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiFixTargetRow extends StatelessWidget {
  const _AiFixTargetRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.of(context).textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.of(context).textPrimary,
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

  final FaIconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.of(context).borderSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.of(context).border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 11, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.of(context).textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLogsView extends HookConsumerWidget {
  const _DetailLogsView({
    required this.buildJobId,
    required this.runId,
    required this.buildStatus,
  });

  final String buildJobId;
  final String runId;
  final BuildJobStatus buildStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(buildLogsProvider(buildJobId, runId));
    final detailT = t.buildLogs.detail;
    final scrollController = useScrollController();
    final showScrollToBottom = useState(false);
    final copyDone = useState(false);
    final isNearBottom = useRef(true);
    final prevLogCount = useRef(0);

    useEffect(() {
      void listener() {
        if (!scrollController.hasClients) return;
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;
        final nearBottom = (maxScroll - currentScroll) <= 200;
        showScrollToBottom.value = !nearBottom;
        isNearBottom.value = nearBottom;
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController]);

    return logsAsync.when(
      data: (logs) {
        if (logs.length != prevLogCount.value) {
          final wasNearBottom = isNearBottom.value;
          prevLogCount.value = logs.length;
          if (wasNearBottom && scrollController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }

        if (logs.isEmpty) {
          final isTerminal =
              buildStatus == BuildJobStatus.SUCCESS ||
              buildStatus == BuildJobStatus.FAILURE ||
              buildStatus == BuildJobStatus.CANCELLED ||
              buildStatus == BuildJobStatus.SKIPPED ||
              buildStatus == BuildJobStatus.TIMED_OUT;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTerminal)
                  Icon(
                    Icons.subject_rounded,
                    size: 22,
                    color: AppColors.of(context).textTertiary,
                  )
                else
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  isTerminal ? detailT.noLogsAvailable : detailT.waitingForLogs,
                  style: TextStyle(
                    color: AppColors.of(context).textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Column(
              children: [
                // ── Toolbar ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.of(context).divider,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 14,
                        color: AppColors.of(context).textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        detailT.logEntries(count: logs.length.toString()),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.of(context).textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      _ToolbarButton(
                        icon: copyDone.value
                            ? Icons.check_rounded
                            : Icons.copy_all_rounded,
                        iconColor: copyDone.value
                            ? const Color(0xFF3FB950)
                            : AppColors.of(context).textTertiary,
                        tooltip: detailT.copyAll,
                        onPressed: copyDone.value
                            ? null
                            : () {
                                final allLogs = logs
                                    .map((l) => l.message)
                                    .join('\n');
                                Clipboard.setData(ClipboardData(text: allLogs));
                                copyDone.value = true;
                                Future.delayed(
                                  const Duration(milliseconds: 1500),
                                  () {
                                    if (context.mounted) {
                                      copyDone.value = false;
                                    }
                                  },
                                );
                                if (context.mounted) {
                                  context.showSnackBarMessage(
                                    detailT.logsCopied,
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ),
                // ── Log list ─────────────────────────────────────────
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _DetailLogLine(
                          log: log,
                          lineNumber: index + 1,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            // ── Scroll-to-bottom button ──────────────────────────────
            if (showScrollToBottom.value)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'build-log-scroll-to-bottom',
                  tooltip: 'ログの末尾へ移動',
                  backgroundColor: AppColors.of(context).accent,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Icon(Icons.keyboard_double_arrow_down_rounded),
                ),
              ),
          ],
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.of(context).border,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF85149).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: Color(0xFFF85149),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                t.common.error(error: error.toString()),
                style: TextStyle(
                  color: const Color(0xFFF85149).withValues(alpha: 0.8),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed: onPressed,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            key: ValueKey(icon),
            size: 15,
            color: iconColor,
          ),
        ),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _DetailLogLine extends HookWidget {
  const _DetailLogLine({required this.log, required this.lineNumber});
  final BuildLog log;
  final int lineNumber;

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);
    final lines = log.message.split('\n');
    final isMultiLine = lines.length > 1;

    final levelColor = switch (log.level) {
      'error' => const Color(0xFFF85149),
      'warning' => const Color(0xFFD29922),
      'success' => const Color(0xFF3FB950),
      _ => AppColors.of(context).textSecondary,
    };

    final levelIcon = switch (log.level) {
      'error' => Icons.error_outline_rounded,
      'warning' => Icons.warning_amber_rounded,
      'success' => Icons.check_circle_outline_rounded,
      _ => Icons.circle,
    };

    // ── Single-line log ────────────────────────────────────────────────────
    if (!isMultiLine) {
      return _logLineHoverWrapper(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lineNumberWidget(context),
              const SizedBox(width: 12),
              _levelIconWidget(levelIcon, levelColor),
              const SizedBox(width: 8),
              Expanded(
                child: _HorizontalLogSelectableText(
                  text: log.message,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: levelColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Multi-line log (collapsible) ───────────────────────────────────────
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).borderSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.of(context).textPrimary.withValues(
              alpha: isExpanded.value ? 0.1 : 0.06,
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
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lineNumberWidget(context),
                      const SizedBox(width: 12),
                      _levelIconWidget(levelIcon, levelColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HorizontalLogText(
                          text: lines.first,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: levelColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).divider,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.of(context).border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded.value
                                  ? Icons.unfold_less_rounded
                                  : Icons.unfold_more_rounded,
                              size: 13,
                              color: AppColors.of(context).textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.buildLogs.detail.lines(
                                count: lines.length.toString(),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.of(context).textTertiary,
                                fontWeight: FontWeight.w500,
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
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded.value
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.of(context).scaffold,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.of(context).divider,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: _HorizontalLogSelectableText(
                  text: log.message,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: levelColor.withValues(alpha: 0.9),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logLineHoverWrapper({required Widget child}) {
    return _HoverHighlight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: child,
      ),
    );
  }

  Widget _lineNumberWidget(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        '$lineNumber',
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: AppColors.of(context).border,
          height: 1.5,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _levelIconWidget(IconData icon, Color color) {
    return SizedBox(
      width: 16,
      height: 20,
      child: Center(
        child: Icon(
          icon,
          size: log.level == 'info' ? 5 : 13,
          color: color.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _HorizontalLogText extends StatelessWidget {
  const _HorizontalLogText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text(
        text,
        softWrap: false,
        style: style,
      ),
    );
  }
}

class _HorizontalLogSelectableText extends StatelessWidget {
  const _HorizontalLogSelectableText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SelectableText(
        text,
        maxLines: null,
        style: style,
      ),
    );
  }
}

// ── Hover highlight for log lines ───────────────────────────────────────────

class _HoverHighlight extends StatefulWidget {
  const _HoverHighlight({required this.child});
  final Widget child;

  @override
  State<_HoverHighlight> createState() => _HoverHighlightState();
}

class _HoverHighlightState extends State<_HoverHighlight> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _hovering
              ? AppColors.of(context).borderSubtle
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: widget.child,
      ),
    );
  }
}

// ── AI Failure Summary Card ─────────────────────────────────────────────────

class _FailureSummaryCard extends HookWidget {
  const _FailureSummaryCard({
    required this.status,
    this.summary,
    this.model,
    this.durationMs,
  });

  final String status;
  final String? summary;
  final String? model;
  final int? durationMs;

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(true);

    // Loading state: generating
    if (status == 'generating') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          border: Border(
            bottom: BorderSide(
              color: AppColors.of(context).divider,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: const Color(0xFFD29922).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: const Color(0xFFD29922).withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              t.buildLogs.detail.generatingSummary,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFD29922).withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // No summary available (error or no_logs)
    if (status != 'done' || summary == null) {
      return const SizedBox.shrink();
    }

    const accentColor = Color(0xFFF85149);

    String durationLabel = '';
    if (durationMs != null) {
      durationLabel = durationMs! < 1000
          ? '${durationMs}ms'
          : '${(durationMs! / 1000).toStringAsFixed(1)}s';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.of(context).divider,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => isExpanded.value = !isExpanded.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: accentColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.buildLogs.detail.failureSummaryTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    if (model != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).borderSubtle,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.of(context).border,
                          ),
                        ),
                        child: Text(
                          model!,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: AppColors.of(context).textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (durationLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        durationLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColors.of(context).textTertiary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      isExpanded.value
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.of(context).textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Body (collapsible) ──
          Flexible(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded.value
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left accent bar
                      Container(
                        width: 3,
                        constraints: const BoxConstraints(minHeight: 60),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColor.withValues(alpha: 0.7),
                              accentColor.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                      // Summary content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: MarkdownBody(
                            data: summary!,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontSize: 13,
                                color: AppColors.of(context).textSecondary,
                                height: 1.6,
                              ),
                              strong: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.of(context).textPrimary,
                              ),
                              code: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: const Color(0xFF58A6FF),
                                backgroundColor: AppColors.of(context).divider,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: AppColors.of(context).scaffold,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.of(context).border,
                                ),
                              ),
                              blockquote: TextStyle(
                                color: AppColors.of(context).textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                              blockquoteDecoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.of(context).border,
                                    width: 3,
                                  ),
                                ),
                              ),
                              listBullet: TextStyle(
                                color: AppColors.of(context).textTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
