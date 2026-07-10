import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/extensions/date_time_extensions.dart';
import 'package:flutter/material.dart';

class BuildJobLogCard extends StatelessWidget {
  const BuildJobLogCard({
    super.key,
    required this.buildJob,
    this.child,
    this.jobs,
    this.isExpanded = false,
    this.dependencies,
    this.needs,
    this.workflowStyle,
    this.infoTextStyle,
    this.iconColor,
    this.iconSize = 12,
    this.spacing = 9,
    this.runSpacing = 5,
    this.contentSpacing = 12,
    this.maxTriggerWidth = 360,
    this.durationWidget,
    this.title,
  }) : assert(
         child != null || jobs != null || needs != null,
         'Either child, jobs, or needs must be provided',
       );

  final BuildJob buildJob;
  final String? title;
  final Widget? child;
  final List<Widget>? jobs;
  final bool isExpanded;
  final List<Widget>? dependencies;
  final List<Widget>? needs;

  final TextStyle? workflowStyle;
  final TextStyle? infoTextStyle;
  final Color? iconColor;
  final double iconSize;
  final double spacing;
  final double runSpacing;
  final double contentSpacing;
  final double maxTriggerWidth;
  final Widget? durationWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveWorkflowStyle =
        workflowStyle ??
        theme.textTheme.labelMedium?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.w800,
        ) ??
        const TextStyle(
          color: Color(0xFF667085),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        );

    final effectiveInfoTextStyle =
        infoTextStyle ??
        const TextStyle(
          color: Color(0xFF667085),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        );

    final effectiveIconColor = iconColor ?? const Color(0xFF98A2B3);

    final displayTitle =
        title ??
        (buildJob.jobKey != null
            ? '${buildJob.workflowName} (${buildJob.jobKey})'
            : buildJob.workflowName);

    final timeAgo = buildJob.createdAt.toTimeAgo();

    final String trigger;
    final IconData triggerIcon;

    if (buildJob.pullRequestNumber != null) {
      final prNumber = buildJob.pullRequestNumber;
      final branchName = buildJob.branch ?? '';
      final sha = buildJob.commitSha != null && buildJob.commitSha!.length >= 7
          ? buildJob.commitSha!.substring(0, 7)
          : (buildJob.commitSha ?? '');
      trigger = 'pull request · #$prNumber · $branchName · $sha';
      triggerIcon = Icons.call_merge_rounded;
    } else if (buildJob.tagName != null) {
      final tag = buildJob.tagName;
      final sha = buildJob.commitSha != null && buildJob.commitSha!.length >= 7
          ? buildJob.commitSha!.substring(0, 7)
          : (buildJob.commitSha ?? '');
      trigger = 'tag · $tag · $sha';
      triggerIcon = Icons.local_offer_rounded;
    } else {
      final branchName = buildJob.branch ?? '';
      final sha = buildJob.commitSha != null && buildJob.commitSha!.length >= 7
          ? buildJob.commitSha!.substring(0, 7)
          : (buildJob.commitSha ?? '');
      trigger = 'push · $branchName · $sha';
      triggerIcon = Icons.arrow_upward_rounded;
    }

    final Widget mainContent;
    if (jobs != null) {
      final wrap = Wrap(
        spacing: 7,
        runSpacing: 7,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: jobs!,
      );

      final List<Widget> children = [wrap];
      if (child != null) {
        children.add(child!);
      }

      if (children.length > 1) {
        mainContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      } else {
        mainContent = wrap;
      }
    } else if (needs != null) {
      final needsContent = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dependencies != null && dependencies!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < dependencies!.length; i++) ...[
                      dependencies![i],
                      if (i < dependencies!.length - 1) ...[
                        const SizedBox(width: 4.0),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: Color(0xFFB8C0CC),
                        ),
                        const SizedBox(width: 4.0),
                      ] else
                        const SizedBox(width: 4.0),
                    ],
                  ],
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: needs!,
            ),
          ],
        ),
      );

      final List<Widget> children = [needsContent];
      if (child != null) {
        children.add(child!);
      }

      if (children.length > 1) {
        mainContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      } else {
        mainContent = needsContent;
      }
    } else {
      mainContent = child ?? const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(displayTitle, style: effectiveWorkflowStyle),
            // ignore: use_null_aware_elements
            if (durationWidget != null) durationWidget!,
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTriggerWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(triggerIcon, size: iconSize, color: effectiveIconColor),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      trigger,
                      overflow: TextOverflow.ellipsis,
                      style: effectiveInfoTextStyle,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: iconSize,
                  color: effectiveIconColor,
                ),
                const SizedBox(width: 4),
                Text(timeAgo, style: effectiveInfoTextStyle),
              ],
            ),
          ],
        ),
        if (mainContent is! SizedBox) ...[
          SizedBox(height: contentSpacing),
          mainContent,
        ],
      ],
    );
  }
}
