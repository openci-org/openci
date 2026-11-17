import 'package:dashboard/app_strings.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_repository.dart';
import 'package:dashboard/cicd_log/cicd_log_providers.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RetryJobButton extends ConsumerWidget {
  const RetryJobButton({super.key, required this.job});

  final BuildJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRetry =
        job.teamId != null &&
        job.teamId!.isNotEmpty &&
        job.runsOn == 'macos-latest' &&
        switch (job.status) {
          BuildJobStatus.SUCCESS ||
          BuildJobStatus.FAILURE ||
          BuildJobStatus.CANCELLED ||
          BuildJobStatus.TIMED_OUT => true,
          _ => false,
        };
    if (!canRetry) return const SizedBox.shrink();
    final repository = ref.watch(buildRepositoryProvider).asData?.value;
    if (repository == null) return const SizedBox.shrink();
    return _RetryJobButton(
      // A connection or job change also discards the previous request's UI.
      key: ValueKey((repository, job.id)),
      repository: repository,
      job: job,
    );
  }
}

class _RetryJobButton extends ConsumerStatefulWidget {
  const _RetryJobButton({
    super.key,
    required this.repository,
    required this.job,
  });

  final BuildRepository repository;
  final BuildJob job;

  @override
  ConsumerState<_RetryJobButton> createState() => _RetryJobButtonState();
}

class _RetryJobButtonState extends ConsumerState<_RetryJobButton> {
  bool _pending = false;
  int? _acceptedRetryCount;

  bool get _awaitingUpdate =>
      _acceptedRetryCount != null &&
      widget.job.retryCount < _acceptedRetryCount!;

  Future<void> _retry() async {
    if (_pending ||
        _awaitingUpdate ||
        ref.read(buildRepositoryProvider).asData?.value != widget.repository) {
      return;
    }
    final job = widget.job;
    setState(() => _pending = true);
    try {
      await widget.repository.retryJob(
        id: job.id,
        expectedRetryCount: job.retryCount,
      );
      if (!mounted) return;
      setState(() => _acceptedRetryCount = job.retryCount + 1);
      context.showSnackBarMessage(context.t.logs.retryQueued);
    } catch (_) {
      if (!mounted) return;
      context.showSnackBarMessage(context.t.logs.retryFailed);
    } finally {
      if (mounted) {
        setState(() => _pending = false);
        // Also reconcile an ambiguous response. Never resubmit automatically
        // with a newly fetched counter: another explicit click is required.
        ref.invalidate(buildJobByIdProvider(job.id));
        ref.invalidate(cicdCommitGroupsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _pending
        ? context.t.logs.retrySubmitting
        : _awaitingUpdate
        ? context.t.logs.retryRequested
        : context.t.logs.retryJob;
    final onPressed = _pending || _awaitingUpdate ? null : _retry;
    final icon = _pending
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.replay_rounded);
    if (MediaQuery.sizeOf(context).width < 600) {
      return IconButton(tooltip: label, onPressed: onPressed, icon: icon);
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
    );
  }
}
