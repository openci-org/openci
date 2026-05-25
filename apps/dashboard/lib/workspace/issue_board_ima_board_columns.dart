import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'issue_board_ima_app_shell.dart';
import 'issue_board_ima_issue_cards.dart';
import 'issue_board_ima_models.dart';
import 'issue_board_ima_overview.dart';
import 'issue_board_ima_utils.dart';

class BoardColumnView extends StatelessWidget {
  const BoardColumnView({
    super.key,
    required this.column,
    this.subIssuesByParentId = const {},
    this.buildStatusesByIssueId = const {},
    this.issuesByRepositoryNumber = const {},
    required this.requiresLongPressDrag,
    required this.onIssueDropped,
    this.onIssueLinkedToPullRequest,
    required this.onAddIssue,
    required this.onIssueTapped,
  });

  final BoardColumn column;
  final Map<String, List<Issue>> subIssuesByParentId;
  final Map<String, CardBuildStatus> buildStatusesByIssueId;
  final Map<String, Issue> issuesByRepositoryNumber;
  final bool requiresLongPressDrag;
  final IssueDropCallback onIssueDropped;
  final IssuePullRequestLinkCallback? onIssueLinkedToPullRequest;
  final ValueChanged<String> onAddIssue;
  final ValueChanged<String> onIssueTapped;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = visibleIssuesForColumn(column);
    final rankIndicesByIssueId = _rankIndicesByIssueId(column.issues);
    final reviewGroups = column.id == reviewStatusId
        ? _reviewPullRequestGroupsForIssues(visibleIssues)
        : const <ReviewPullRequestGroup>[];
    final acceptsColumnDrop =
        column.id != reviewStatusId || reviewGroups.isEmpty;

    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) =>
          acceptsColumnDrop && details.data.sourceColumnId != column.id,
      onAcceptWithDetails: (details) {
        onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: column.id,
          targetIndex: column.issues.length,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: boardColumnWidth,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering
                ? column.color.withValues(alpha: 0.08)
                : Colors.white,
            border: Border.all(
              color: isHovering
                  ? column.color.withValues(alpha: 0.45)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColumnHeader(
                column: column,
                isCompact: false,
                onAddIssue: () => onAddIssue(column.id),
              ),
              const SizedBox(height: 10),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(top: 10),
                  children: [
                    if (visibleIssues.isEmpty) ...[
                      EmptyColumnIssueCreator(
                        columnTitle: column.title,
                        onPressed: () => onAddIssue(column.id),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (reviewGroups.isNotEmpty)
                      for (final group in reviewGroups) ...[
                        ReviewPullRequestGroupView(
                          group: group,
                          column: column,
                          subIssuesByParentId: subIssuesByParentId,
                          buildStatusesByIssueId: buildStatusesByIssueId,
                          issuesByRepositoryNumber: issuesByRepositoryNumber,
                          rankIndicesByIssueId: rankIndicesByIssueId,
                          requiresLongPressDrag: requiresLongPressDrag,
                          onIssueTapped: onIssueTapped,
                          onSubIssueTap: onIssueTapped,
                          onIssueDropped: onIssueDropped,
                          onIssueLinkedToPullRequest:
                              onIssueLinkedToPullRequest,
                        ),
                        const SizedBox(height: 8),
                      ]
                    else
                      for (
                        var index = 0;
                        index < visibleIssues.length;
                        index++
                      ) ...[
                        Builder(
                          builder: (context) {
                            final issue = visibleIssues[index];
                            final rankIndex = rankIndicesByIssueId[issue.id];

                            return IssueCardDropTarget(
                              key: ValueKey(issue.id),
                              issue: issue,
                              subIssues:
                                  subIssuesByParentId[issue.id] ??
                                  const <Issue>[],
                              buildStatus: buildStatusesByIssueId[issue.id],
                              sourceColumnId: column.id,
                              index: rankIndex ?? index,
                              requiresLongPressDrag: requiresLongPressDrag,
                              onTap: () => onIssueTapped(issue.id),
                              onSubIssueTap: onIssueTapped,
                              onIssueDropped: onIssueDropped,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    IssueDropSlot(
                      columnId: column.id,
                      index: column.issues.length,
                      onIssueDropped: onIssueDropped,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CompactBoardColumnView extends StatefulWidget {
  const CompactBoardColumnView({
    super.key,
    required this.column,
    this.subIssuesByParentId = const {},
    this.buildStatusesByIssueId = const {},
    this.issuesByRepositoryNumber = const {},
    required this.requiresLongPressDrag,
    required this.onIssueDropped,
    this.onIssueLinkedToPullRequest,
    required this.onAddIssue,
    required this.onIssueTapped,
  });

  final BoardColumn column;
  final Map<String, List<Issue>> subIssuesByParentId;
  final Map<String, CardBuildStatus> buildStatusesByIssueId;
  final Map<String, Issue> issuesByRepositoryNumber;
  final bool requiresLongPressDrag;
  final IssueDropCallback onIssueDropped;
  final IssuePullRequestLinkCallback? onIssueLinkedToPullRequest;
  final ValueChanged<String> onAddIssue;
  final ValueChanged<String> onIssueTapped;

  @override
  State<CompactBoardColumnView> createState() => _CompactBoardColumnViewState();
}

class _CompactBoardColumnViewState extends State<CompactBoardColumnView> {
  var _isShrunk = true;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = visibleIssuesForColumn(widget.column);
    final displayedIssues = _isShrunk
        ? visibleIssues.take(compactColumnCollapsedLimit).toList()
        : visibleIssues;
    final rankIndicesByIssueId = _rankIndicesByIssueId(widget.column.issues);
    final reviewGroups = widget.column.id == reviewStatusId
        ? _reviewPullRequestGroupsForIssues(displayedIssues)
        : const <ReviewPullRequestGroup>[];
    final acceptsColumnDrop =
        widget.column.id != reviewStatusId || reviewGroups.isEmpty;
    final hiddenIssueCount = visibleIssues.length - displayedIssues.length;
    final canToggleSize = visibleIssues.length > compactColumnCollapsedLimit;

    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) =>
          acceptsColumnDrop && details.data.sourceColumnId != widget.column.id,
      onAcceptWithDetails: (details) {
        widget.onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: widget.column.id,
          targetIndex: widget.column.issues.length,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering
                ? widget.column.color.withValues(alpha: 0.08)
                : Colors.white,
            border: Border.all(
              color: isHovering
                  ? widget.column.color.withValues(alpha: 0.45)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColumnHeader(
                column: widget.column,
                isCompact: true,
                onAddIssue: () => widget.onAddIssue(widget.column.id),
              ),
              const SizedBox(height: 10),
              // const Divider(
              //   height: 1,
              //   thickness: 1,
              //   color: Color(0xFFE2E8F0),
              // ),
              const SizedBox(height: 10),
              if (visibleIssues.isEmpty) ...[
                EmptyColumnIssueCreator(
                  columnTitle: widget.column.title,
                  onPressed: () => widget.onAddIssue(widget.column.id),
                ),
                const SizedBox(height: 8),
              ],
              if (reviewGroups.isNotEmpty)
                for (final group in reviewGroups) ...[
                  ReviewPullRequestGroupView(
                    group: group,
                    column: widget.column,
                    subIssuesByParentId: widget.subIssuesByParentId,
                    buildStatusesByIssueId: widget.buildStatusesByIssueId,
                    issuesByRepositoryNumber: widget.issuesByRepositoryNumber,
                    rankIndicesByIssueId: rankIndicesByIssueId,
                    requiresLongPressDrag: widget.requiresLongPressDrag,
                    onIssueTapped: widget.onIssueTapped,
                    onSubIssueTap: widget.onIssueTapped,
                    onIssueDropped: widget.onIssueDropped,
                    onIssueLinkedToPullRequest:
                        widget.onIssueLinkedToPullRequest,
                  ),
                  const SizedBox(height: 8),
                ]
              else
                for (
                  var index = 0;
                  index < displayedIssues.length;
                  index++
                ) ...[
                  Builder(
                    builder: (context) {
                      final issue = displayedIssues[index];
                      final rankIndex = rankIndicesByIssueId[issue.id];

                      return IssueCardDropTarget(
                        key: ValueKey(issue.id),
                        issue: issue,
                        subIssues:
                            widget.subIssuesByParentId[issue.id] ??
                            const <Issue>[],
                        buildStatus: widget.buildStatusesByIssueId[issue.id],
                        sourceColumnId: widget.column.id,
                        index: rankIndex ?? index,
                        requiresLongPressDrag: widget.requiresLongPressDrag,
                        onTap: () => widget.onIssueTapped(issue.id),
                        onSubIssueTap: widget.onIssueTapped,
                        onIssueDropped: widget.onIssueDropped,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              if (canToggleSize) ...[
                InlineColumnSizeButton(
                  isShrunk: _isShrunk,
                  hiddenIssueCount: hiddenIssueCount,
                  totalIssueCount: visibleIssues.length,
                  collapsedIssueCount: compactColumnCollapsedLimit,
                  onPressed: () => setState(() => _isShrunk = !_isShrunk),
                ),
                const SizedBox(height: 8),
              ],
              IssueDropSlot(
                columnId: widget.column.id,
                index: widget.column.issues.length,
                onIssueDropped: widget.onIssueDropped,
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReviewPullRequestGroup {
  const ReviewPullRequestGroup({
    required this.repository,
    required this.pullRequest,
    required this.issues,
  });

  final String repository;
  final IssuePullRequest? pullRequest;
  final List<Issue> issues;
}

class _MutableReviewPullRequestGroup {
  _MutableReviewPullRequestGroup({
    required this.repository,
    required this.pullRequest,
  });

  final String repository;
  final IssuePullRequest? pullRequest;
  final List<Issue> issues = [];
}

class _ReviewLinkedIssueItem {
  const _ReviewLinkedIssueItem({this.issue, this.reference});

  final Issue? issue;
  final IssuePullRequestLinkedIssue? reference;

  int get number => reference?.number ?? issue?.githubNumber ?? 0;
}

List<ReviewPullRequestGroup> _reviewPullRequestGroupsForIssues(
  List<Issue> issues,
) {
  final groups = <String, _MutableReviewPullRequestGroup>{};
  for (final issue in issues) {
    final pullRequest = issue.pullRequests.isEmpty
        ? null
        : issue.pullRequests.last;
    final repository = issue.repo;
    final key = pullRequest == null
        ? 'without-pull-request'
        : '$repository#${pullRequest.number}';
    final group = groups.putIfAbsent(
      key,
      () => _MutableReviewPullRequestGroup(
        repository: repository,
        pullRequest: pullRequest,
      ),
    );
    group.issues.add(issue);
  }

  return [
    for (final group in groups.values)
      ReviewPullRequestGroup(
        repository: group.repository,
        pullRequest: group.pullRequest,
        issues: List.unmodifiable(group.issues),
      ),
  ]..sort(_compareReviewPullRequestGroups);
}

int _compareReviewPullRequestGroups(
  ReviewPullRequestGroup a,
  ReviewPullRequestGroup b,
) {
  final aCreatedAt = a.pullRequest?.createdAt;
  final bCreatedAt = b.pullRequest?.createdAt;
  if (aCreatedAt != null && bCreatedAt != null) {
    final createdAtCompare = aCreatedAt.compareTo(bCreatedAt);
    if (createdAtCompare != 0) {
      return createdAtCompare;
    }
  } else if (aCreatedAt != null) {
    return -1;
  } else if (bCreatedAt != null) {
    return 1;
  }

  final rankCompare = _firstReviewIssueRank(a).compareTo(
    _firstReviewIssueRank(b),
  );
  if (rankCompare != 0) {
    return rankCompare;
  }

  final repositoryCompare = a.repository.compareTo(b.repository);
  if (repositoryCompare != 0) {
    return repositoryCompare;
  }

  return (a.pullRequest?.number ?? 0).compareTo(b.pullRequest?.number ?? 0);
}

double _firstReviewIssueRank(ReviewPullRequestGroup group) {
  return group.issues.isEmpty ? double.infinity : group.issues.first.rank;
}

List<_ReviewLinkedIssueItem> _linkedIssueItemsForPullRequest({
  required ReviewPullRequestGroup group,
  required Map<String, Issue> issuesByRepositoryNumber,
}) {
  final pullRequest = group.pullRequest;
  final seenNumbers = <int>{};
  final items = <_ReviewLinkedIssueItem>[];

  for (final reference
      in pullRequest?.linkedIssues ?? const <IssuePullRequestLinkedIssue>[]) {
    final issue =
        issuesByRepositoryNumber[issueRepositoryNumberKey(
          group.repository,
          reference.number,
        )];
    if (issue != null &&
        !issue.pullRequests.any(
          (issuePullRequest) => issuePullRequest.number == pullRequest?.number,
        )) {
      continue;
    }
    seenNumbers.add(reference.number);
    items.add(_ReviewLinkedIssueItem(issue: issue, reference: reference));
  }

  for (final issue in group.issues) {
    final issueNumber = issue.githubNumber;
    if (issueNumber > 0 && seenNumbers.contains(issueNumber)) {
      continue;
    }
    if (issueNumber > 0) {
      seenNumbers.add(issueNumber);
    }
    items.add(_ReviewLinkedIssueItem(issue: issue));
  }

  return items;
}

class ReviewPullRequestGroupView extends StatelessWidget {
  const ReviewPullRequestGroupView({
    super.key,
    required this.group,
    required this.column,
    required this.subIssuesByParentId,
    required this.buildStatusesByIssueId,
    required this.issuesByRepositoryNumber,
    required this.rankIndicesByIssueId,
    required this.requiresLongPressDrag,
    required this.onIssueTapped,
    required this.onSubIssueTap,
    required this.onIssueDropped,
    this.onIssueLinkedToPullRequest,
  });

  final ReviewPullRequestGroup group;
  final BoardColumn column;
  final Map<String, List<Issue>> subIssuesByParentId;
  final Map<String, CardBuildStatus> buildStatusesByIssueId;
  final Map<String, Issue> issuesByRepositoryNumber;
  final Map<String, int> rankIndicesByIssueId;
  final bool requiresLongPressDrag;
  final ValueChanged<String> onIssueTapped;
  final ValueChanged<String> onSubIssueTap;
  final IssueDropCallback onIssueDropped;
  final IssuePullRequestLinkCallback? onIssueLinkedToPullRequest;

  @override
  Widget build(BuildContext context) {
    final pullRequest = group.pullRequest;
    final linkedIssueItems = _linkedIssueItemsForPullRequest(
      group: group,
      issuesByRepositoryNumber: issuesByRepositoryNumber,
    );
    final buildStatus = pullRequest == null
        ? null
        : group.issues.isEmpty
        ? null
        : buildStatusesByIssueId[group.issues.first.id];
    final title = pullRequest?.title ?? 'PR未紐づけ';
    final url = pullRequest?.url;
    final isOpenPullRequest =
        pullRequest != null &&
        !pullRequest.merged &&
        pullRequest.state.toLowerCase() == 'open';
    final stateLabel = pullRequest == null
        ? 'no PR'
        : pullRequest.merged
        ? 'merged'
        : pullRequest.state;
    final stateColor = pullRequest == null
        ? const Color(0xFF64748B)
        : pullRequest.merged
        ? const Color(0xFF7C3AED)
        : pullRequest.state == 'closed'
        ? const Color(0xFFB45309)
        : const Color(0xFF15803D);
    final groupIssueIds = group.issues.map((issue) => issue.id).toSet();

    void handleIssueDropped({
      required String issueId,
      required String targetColumnId,
      required int targetIndex,
      bool clearPullRequests = false,
    }) {
      final targetPullRequest = pullRequest;
      final onLink = onIssueLinkedToPullRequest;
      if (targetPullRequest != null &&
          onLink != null &&
          !groupIssueIds.contains(issueId)) {
        unawaited(
          onLink(
            issueId: issueId,
            repository: group.repository,
            pullRequest: targetPullRequest,
          ),
        );
        return;
      }

      onIssueDropped(
        issueId: issueId,
        targetColumnId: targetColumnId,
        targetIndex: targetIndex,
        clearPullRequests: clearPullRequests || pullRequest == null,
      );
    }

    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) =>
          pullRequest != null &&
          onIssueLinkedToPullRequest != null &&
          !groupIssueIds.contains(details.data.issueId),
      onAcceptWithDetails: (details) {
        handleIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: column.id,
          targetIndex: column.issues.length,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isGroupHovering = candidateData.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isGroupHovering
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF8FAFC),
            border: Border.all(
              color: isGroupHovering
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DragTarget<IssueDragData>(
                onWillAcceptWithDetails: (details) =>
                    pullRequest != null &&
                    onIssueLinkedToPullRequest != null &&
                    !groupIssueIds.contains(details.data.issueId),
                onAcceptWithDetails: (details) {
                  final targetPullRequest = pullRequest;
                  final onLink = onIssueLinkedToPullRequest;
                  if (targetPullRequest == null || onLink == null) {
                    return;
                  }

                  unawaited(
                    onLink(
                      issueId: details.data.issueId,
                      repository: group.repository,
                      pullRequest: targetPullRequest,
                    ),
                  );
                },
                builder: (context, candidateData, rejectedData) {
                  final isHovering = candidateData.isNotEmpty;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isHovering
                          ? const Color(0xFFEFF6FF)
                          : Colors.transparent,
                      border: Border.all(
                        color: isHovering
                            ? const Color(0xFF60A5FA)
                            : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: url == null
                            ? null
                            : () => unawaited(launchUrlExternal(url)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: FaIcon(
                                      FontAwesomeIcons.codePullRequest,
                                      size: 16,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pullRequest == null
                                              ? 'PRなし'
                                              : '${group.repository} #${pullRequest.number}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF475569),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.w900,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (!isOpenPullRequest)
                                    ReviewGroupPill(
                                      label: stateLabel,
                                      color: stateColor,
                                      icon: pullRequest?.merged == true
                                          ? Icons.call_merge_rounded
                                          : Icons.circle_rounded,
                                    ),
                                  BuildStatusBadge(status: buildStatus),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              for (final entry in linkedIssueItems.indexed) ...[
                Builder(
                  builder: (context) {
                    final item = entry.$2;
                    final issue = item.issue;
                    if (issue == null) {
                      final reference = item.reference;
                      if (reference == null) {
                        return const SizedBox.shrink();
                      }
                      return ReviewLinkedIssueReferenceCard(
                        reference: reference,
                      );
                    }

                    final isReviewColumnIssue = group.issues.any(
                      (candidate) => candidate.id == issue.id,
                    );
                    if (!isReviewColumnIssue) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onIssueTapped(issue.id),
                        child: ReviewGroupIssueCard(issue: issue),
                      );
                    }

                    final rankIndex = rankIndicesByIssueId[issue.id];

                    return IssueCardDropTarget(
                      key: ValueKey(issue.id),
                      issue: issue,
                      subIssues:
                          subIssuesByParentId[issue.id] ?? const <Issue>[],
                      buildStatus: pullRequest == null
                          ? buildStatusesByIssueId[issue.id]
                          : null,
                      isReviewGroupCard: true,
                      sourceColumnId: column.id,
                      index: rankIndex ?? entry.$1,
                      requiresLongPressDrag: requiresLongPressDrag,
                      onTap: () => onIssueTapped(issue.id),
                      onSubIssueTap: onSubIssueTap,
                      onIssueDropped: handleIssueDropped,
                    );
                  },
                ),
                if (entry.$1 != linkedIssueItems.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ReviewGroupPill extends StatelessWidget {
  const ReviewGroupPill({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class InlineColumnSizeButton extends StatelessWidget {
  const InlineColumnSizeButton({
    super.key,
    required this.isShrunk,
    required this.hiddenIssueCount,
    required this.totalIssueCount,
    required this.collapsedIssueCount,
    required this.onPressed,
  });

  final bool isShrunk;
  final int hiddenIssueCount;
  final int totalIssueCount;
  final int collapsedIssueCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = isShrunk
        ? 'さらに$hiddenIssueCount件表示（全$totalIssueCount件）'
        : collapsedIssueCount == 0
        ? '縮小して件数だけ表示'
        : '縮小して先頭$collapsedIssueCount件だけ表示';
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          isShrunk
              ? Icons.keyboard_arrow_down_rounded
              : Icons.keyboard_arrow_up_rounded,
          size: 20,
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: const Color(0xFF2563EB),
          backgroundColor: const Color(0xFFEFF6FF),
          side: const BorderSide(color: Color(0xFFBFDBFE)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class OverviewBoard extends StatelessWidget {
  const OverviewBoard({
    super.key,
    required this.columns,
    required this.isCompact,
    required this.onIssueTapped,
    required this.onIssueDropped,
  });

  final List<BoardColumn> columns;
  final bool isCompact;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: OverviewList(
            columns: columns,
            isCompact: isCompact,
            onIssueTapped: onIssueTapped,
            onIssueDropped: onIssueDropped,
          ),
        ),
      ],
    );
  }
}

class OverviewList extends StatelessWidget {
  const OverviewList({
    super.key,
    required this.columns,
    required this.isCompact,
    required this.onIssueTapped,
    required this.onIssueDropped,
  });

  final List<BoardColumn> columns;
  final bool isCompact;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = isCompact ? boardBottomPadding + 72 : 14.0;

    if (isCompact) {
      return CompactOverviewList(
        columns: columns,
        bottomPadding: bottomPadding,
        onIssueTapped: onIssueTapped,
        onIssueDropped: onIssueDropped,
      );
    }

    final allIssues = [
      for (final column in columns)
        for (final issue in visibleIssuesForColumn(column)) issue,
    ];
    final totalWeight = allIssues.fold<int>(
      0,
      (total, issue) => total + issueProgressWeight(issue),
    );
    final summary = OverviewSummaryCard(
      issueCount: allIssues.length,
      totalWeight: totalWeight,
      columnCount: columns.length,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            boardHorizontalPadding,
            4,
            boardHorizontalPadding,
            0,
          ),
          child: summary,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              boardHorizontalPadding,
              0,
              boardHorizontalPadding,
              bottomPadding,
            ),
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final column in columns) ...[
                  SizedBox(
                    width: 286,
                    child: OverviewSection(
                      key: ValueKey(column.id),
                      column: column,
                      isCompact: false,
                      requiresLongPressDrag: false,
                      fillHeight: true,
                      onIssueTapped: onIssueTapped,
                      onIssueDropped: onIssueDropped,
                    ),
                  ),
                  if (column != columns.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CompactOverviewList extends StatefulWidget {
  const CompactOverviewList({
    super.key,
    required this.columns,
    required this.bottomPadding,
    required this.onIssueTapped,
    required this.onIssueDropped,
  });

  final List<BoardColumn> columns;
  final double bottomPadding;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;

  @override
  State<CompactOverviewList> createState() => _CompactOverviewListState();
}

class _CompactOverviewListState extends State<CompactOverviewList> {
  final _expandedColumnIds = <String>{};

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        for (final entry in widget.columns.indexed) ...[
          SliverStickyHeader(
            header: Padding(
              padding: EdgeInsets.fromLTRB(
                boardHorizontalPadding,
                entry.$1 == 0 ? 4 : 8,
                boardHorizontalPadding,
                0,
              ),
              child: OverviewSectionHeader(
                column: entry.$2,
                isShrunk: !_expandedColumnIds.contains(entry.$2.id),
                onToggleSize: () => setState(() {
                  final columnId = entry.$2.id;
                  if (!_expandedColumnIds.remove(columnId)) {
                    _expandedColumnIds.add(columnId);
                  }
                }),
              ),
            ),
            sliver: _expandedColumnIds.contains(entry.$2.id)
                ? SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: boardHorizontalPadding,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _CompactOverviewSectionBody(
                        column: entry.$2,
                        onIssueTapped: widget.onIssueTapped,
                        onIssueDropped: widget.onIssueDropped,
                      ),
                    ),
                  )
                : const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: widget.bottomPadding)),
      ],
    );
  }
}

class OverviewSectionHeader extends StatelessWidget {
  const OverviewSectionHeader({
    super.key,
    required this.column,
    required this.isShrunk,
    required this.onToggleSize,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  final BoardColumn column;
  final bool isShrunk;
  final VoidCallback onToggleSize;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = visibleIssuesForColumn(column);
    final totalWeight = visibleIssues.fold<int>(
      0,
      (total, issue) => total + issueProgressWeight(issue),
    );

    return Material(
      color: const Color(0xFFFAFBFC),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggleSize,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: column.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  column.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _OverviewMiniPill(
                label: '${visibleIssues.length}件 / W$totalWeight',
                foregroundColor: column.color,
                backgroundColor: column.color.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 4),
              Icon(
                isShrunk
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactOverviewSectionBody extends StatelessWidget {
  const _CompactOverviewSectionBody({
    required this.column,
    required this.onIssueTapped,
    required this.onIssueDropped,
  });

  final BoardColumn column;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = visibleIssuesForColumn(column);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0))),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
        child: Column(
          children: [
            for (final entry in visibleIssues.indexed) ...[
              Builder(
                builder: (context) {
                  final issue = entry.$2;
                  final rankIndex = column.issues.indexWhere(
                    (candidate) => candidate.id == issue.id,
                  );
                  return OverviewIssueDropTarget(
                    issue: issue,
                    columnId: column.id,
                    index: rankIndex < 0 ? entry.$1 : rankIndex,
                    accentColor: column.color,
                    isCompact: true,
                    requiresLongPressDrag: true,
                    onIssueTapped: onIssueTapped,
                    onIssueDropped: onIssueDropped,
                  );
                },
              ),
              if (entry.$1 != visibleIssues.length - 1)
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ],
            OverviewColumnDropSlot(
              columnId: column.id,
              index: column.issues.length,
              onIssueDropped: onIssueDropped,
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewSummaryCard extends StatelessWidget {
  const OverviewSummaryCard({
    super.key,
    required this.issueCount,
    required this.totalWeight,
    required this.columnCount,
  });

  final int issueCount;
  final int totalWeight;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            '全体リスト',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          _OverviewMiniPill(
            label: '$issueCount件',
            foregroundColor: const Color(0xFF2563EB),
            backgroundColor: const Color(0xFFEFF6FF),
          ),
          _OverviewMiniPill(
            label: 'W$totalWeight',
            foregroundColor: const Color(0xFF15803D),
            backgroundColor: const Color(0xFFDCFCE7),
          ),
          _OverviewMiniPill(
            label: '$columnCount列',
            foregroundColor: const Color(0xFF64748B),
            backgroundColor: const Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }
}

class OverviewSection extends StatefulWidget {
  const OverviewSection({
    super.key,
    required this.column,
    required this.isCompact,
    required this.requiresLongPressDrag,
    required this.onIssueTapped,
    required this.onIssueDropped,
    this.fillHeight = false,
  });

  final BoardColumn column;
  final bool isCompact;
  final bool requiresLongPressDrag;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;
  final bool fillHeight;

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  late var _isShrunk = widget.isCompact;

  @override
  void didUpdateWidget(covariant OverviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompact != widget.isCompact) {
      _isShrunk = widget.isCompact;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleIssues = visibleIssuesForColumn(widget.column);
    final displayedIssues = widget.isCompact && _isShrunk
        ? visibleIssues.take(compactColumnCollapsedLimit).toList()
        : visibleIssues;
    final hiddenIssueCount = visibleIssues.length - displayedIssues.length;
    final canToggleSize =
        widget.isCompact && visibleIssues.length > compactColumnCollapsedLimit;
    final showDropSlot = !widget.isCompact || !_isShrunk;
    final totalWeight = visibleIssues.fold<int>(
      0,
      (total, issue) => total + issueProgressWeight(issue),
    );

    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.sourceColumnId != widget.column.id,
      onAcceptWithDetails: (details) {
        widget.onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: widget.column.id,
          targetIndex: widget.column.issues.length,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: isHovering
                ? widget.column.color.withValues(alpha: 0.06)
                : Colors.white,
            border: Border.all(
              color: isHovering
                  ? widget.column.color.withValues(alpha: 0.38)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
                color: const Color(0xFFFAFBFC),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.column.color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.column.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OverviewMiniPill(
                      label: '${visibleIssues.length}件 / W$totalWeight',
                      foregroundColor: widget.column.color,
                      backgroundColor: widget.column.color.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.fillHeight)
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ..._issueRows(displayedIssues),
                      if (canToggleSize)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InlineColumnSizeButton(
                            isShrunk: _isShrunk,
                            hiddenIssueCount: hiddenIssueCount,
                            totalIssueCount: visibleIssues.length,
                            collapsedIssueCount: compactColumnCollapsedLimit,
                            onPressed: () =>
                                setState(() => _isShrunk = !_isShrunk),
                          ),
                        ),
                      if (showDropSlot)
                        OverviewColumnDropSlot(
                          columnId: widget.column.id,
                          index: widget.column.issues.length,
                          onIssueDropped: widget.onIssueDropped,
                        ),
                    ],
                  ),
                )
              else ...[
                ..._issueRows(displayedIssues),
                if (canToggleSize)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                    child: InlineColumnSizeButton(
                      isShrunk: _isShrunk,
                      hiddenIssueCount: hiddenIssueCount,
                      totalIssueCount: visibleIssues.length,
                      collapsedIssueCount: compactColumnCollapsedLimit,
                      onPressed: () => setState(() => _isShrunk = !_isShrunk),
                    ),
                  ),
                if (showDropSlot)
                  OverviewColumnDropSlot(
                    columnId: widget.column.id,
                    index: widget.column.issues.length,
                    onIssueDropped: widget.onIssueDropped,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _issueRows(List<Issue> visibleIssues) {
    final rankIndicesByIssueId = _rankIndicesByIssueId(widget.column.issues);
    return [
      for (final entry in visibleIssues.indexed) ...[
        Builder(
          builder: (context) {
            final issue = entry.$2;
            final rankIndex = rankIndicesByIssueId[issue.id];
            return OverviewIssueDropTarget(
              key: ValueKey(issue.id),
              issue: issue,
              columnId: widget.column.id,
              index: rankIndex ?? entry.$1,
              accentColor: widget.column.color,
              isCompact: widget.isCompact,
              requiresLongPressDrag: widget.requiresLongPressDrag,
              onIssueTapped: widget.onIssueTapped,
              onIssueDropped: widget.onIssueDropped,
            );
          },
        ),
        if (entry.$1 != visibleIssues.length - 1)
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
      ],
    ];
  }
}

class OverviewIssueDropTarget extends StatelessWidget {
  const OverviewIssueDropTarget({
    super.key,
    required this.issue,
    required this.columnId,
    required this.index,
    required this.accentColor,
    required this.isCompact,
    required this.requiresLongPressDrag,
    required this.onIssueTapped,
    required this.onIssueDropped,
  });

  final Issue issue;
  final String columnId;
  final int index;
  final Color accentColor;
  final bool isCompact;
  final bool requiresLongPressDrag;
  final ValueChanged<String> onIssueTapped;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) => details.data.issueId != issue.id,
      onAcceptWithDetails: (details) {
        onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: columnId,
          targetIndex: index,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: isHovering ? 4 : 0,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            OverviewIssueRow(
              issue: issue,
              sourceColumnId: columnId,
              accentColor: accentColor,
              isCompact: isCompact,
              requiresLongPressDrag: requiresLongPressDrag,
              onTap: () => onIssueTapped(issue.id),
            ),
          ],
        );
      },
    );
  }
}

class OverviewColumnDropSlot extends StatelessWidget {
  const OverviewColumnDropSlot({
    super.key,
    required this.columnId,
    required this.index,
    required this.onIssueDropped,
  });

  final String columnId;
  final int index;
  final IssueDropCallback onIssueDropped;

  @override
  Widget build(BuildContext context) {
    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: columnId,
          targetIndex: index,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: isHovering ? 34 : 10,
          margin: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: BoxDecoration(
            color: isHovering
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF8FAFC),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: isHovering
              ? const Text(
                  'ここに移動',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class OverviewIssueRow extends StatelessWidget {
  const OverviewIssueRow({
    super.key,
    required this.issue,
    required this.sourceColumnId,
    required this.accentColor,
    required this.isCompact,
    required this.requiresLongPressDrag,
    required this.onTap,
  });

  final Issue issue;
  final String sourceColumnId;
  final Color accentColor;
  final bool isCompact;
  final bool requiresLongPressDrag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final repoName = _overviewRepoName(issue.repo);
    final weight = issue.statusId == closedStatusId
        ? issue.resolution?.actualWeight
        : issue.weightEstimate?.value;
    final weightPill = weight == null
        ? const SizedBox(width: 38)
        : _OverviewMiniPill(
            label: 'W$weight',
            foregroundColor: accentColor,
            backgroundColor: accentColor.withValues(alpha: 0.1),
          );

    final row = _OverviewIssueRowContent(
      repoName: repoName,
      title: issue.title,
      weightPill: weightPill,
      isCompact: isCompact,
    );

    final data = IssueDragData(
      issueId: issue.id,
      sourceColumnId: sourceColumnId,
    );
    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: isCompact ? 320 : 286,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: row,
        ),
      ),
    );
    final child = Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );

    if (requiresLongPressDrag) {
      return LongPressDraggable<IssueDragData>(
        data: data,
        delay: mobileDragStartDelay,
        feedback: feedback,
        childWhenDragging: Opacity(opacity: 0.35, child: row),
        child: child,
      );
    }

    return Draggable<IssueDragData>(
      data: data,
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.35, child: row),
      child: child,
    );
  }
}

class _OverviewIssueRowContent extends StatelessWidget {
  const _OverviewIssueRowContent({
    required this.repoName,
    required this.title,
    required this.weightPill,
    required this.isCompact,
  });

  final String repoName;
  final String title;
  final Widget weightPill;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        10,
        isCompact ? 9 : 7,
        10,
        isCompact ? 9 : 7,
      ),
      child: Row(
        crossAxisAlignment: isCompact
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: isCompact ? 58 : 72,
            child: Text(
              repoName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: isCompact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Align(alignment: Alignment.topRight, child: weightPill),
        ],
      ),
    );
  }
}

String _overviewRepoName(String repo) {
  final parts = repo.split('/');
  return parts.isEmpty ? repo : parts.last;
}

class _OverviewMiniPill extends StatelessWidget {
  const _OverviewMiniPill({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

List<Issue> visibleIssuesForColumn(BoardColumn column) {
  if (column.id != closedStatusId) {
    return column.issues;
  }

  return [...column.issues]..sort(compareDoneIssues);
}

Map<String, int> _rankIndicesByIssueId(List<Issue> issues) {
  return {
    for (final entry in issues.indexed) entry.$2.id: entry.$1,
  };
}

List<Issue> subIssuesForParent(Issue parent, List<Issue> allIssues) {
  final subIssues = allIssues
      .where((issue) => issue.parentIssue?.issueId == parent.id)
      .toList();
  subIssues.sort((left, right) => left.rank.compareTo(right.rank));
  return subIssues;
}

Map<String, List<Issue>> subIssuesByParentId(List<Issue> allIssues) {
  final subIssuesByParentId = <String, List<Issue>>{};
  for (final issue in allIssues) {
    final parentId = issue.parentIssue?.issueId;
    if (parentId == null || parentId.isEmpty) {
      continue;
    }
    subIssuesByParentId.putIfAbsent(parentId, () => []).add(issue);
  }
  for (final subIssues in subIssuesByParentId.values) {
    subIssues.sort((left, right) => left.rank.compareTo(right.rank));
  }
  return subIssuesByParentId;
}

List<Issue> descendantSubIssuesForParent(Issue parent, List<Issue> allIssues) {
  final descendants = <Issue>[];
  final seenIssueIds = <String>{parent.id};
  var frontier = <Issue>[parent];

  while (frontier.isNotEmpty) {
    final nextFrontier = <Issue>[];
    for (final issue in frontier) {
      final children = subIssuesForParent(issue, allIssues);
      for (final child in children) {
        if (!seenIssueIds.add(child.id)) {
          continue;
        }
        descendants.add(child);
        nextFrontier.add(child);
      }
    }
    frontier = nextFrontier;
  }

  return descendants;
}

int compareDoneIssues(Issue left, Issue right) {
  final leftClosedAt = left.closedAt;
  final rightClosedAt = right.closedAt;

  if (leftClosedAt != null && rightClosedAt != null) {
    final closedAtComparison = rightClosedAt.compareTo(leftClosedAt);
    if (closedAtComparison != 0) {
      return closedAtComparison;
    }
  }

  return left.rank.compareTo(right.rank);
}

class ColumnHeader extends StatelessWidget {
  const ColumnHeader({
    super.key,
    required this.column,
    required this.isCompact,
    required this.onAddIssue,
  });

  final BoardColumn column;
  final bool isCompact;
  final VoidCallback onAddIssue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 34,
          decoration: BoxDecoration(
            color: column.color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      column.title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CountPill(count: column.issues.length),
                  const SizedBox(width: 2),
                  AddIssueToColumnButton(
                    columnTitle: column.title,
                    isCompact: isCompact,
                    onPressed: onAddIssue,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                column.description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddIssueToColumnButton extends StatelessWidget {
  const AddIssueToColumnButton({
    super.key,
    required this.columnTitle,
    required this.isCompact,
    required this.onPressed,
  });

  final String columnTitle;
  final bool isCompact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonSize = isCompact ? 36.0 : 26.0;
    final iconSize = isCompact ? 24.0 : 16.0;

    return SizedBox.square(
      dimension: buttonSize,
      child: IconButton(
        tooltip: '$columnTitleにissueを作成',
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(
          width: buttonSize,
          height: buttonSize,
        ),
        onPressed: onPressed,
        icon: Icon(Icons.add_rounded, size: iconSize),
      ),
    );
  }
}

class CountPill extends StatelessWidget {
  const CountPill({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class EmptyColumnIssueCreator extends StatelessWidget {
  const EmptyColumnIssueCreator({
    super.key,
    required this.columnTitle,
    required this.onPressed,
  });

  final String columnTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: Color(0xFF94A3B8), size: 24),
          const SizedBox(height: 6),
          const Text(
            'まだチケットがありません',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '$columnTitleにチケットを作成',
            child: OutlinedButton(
              onPressed: onPressed,
              child: const Text('+ チケット作成'),
            ),
          ),
        ],
      ),
    );
  }
}

class IssueDropSlot extends StatelessWidget {
  const IssueDropSlot({
    super.key,
    required this.columnId,
    required this.index,
    required this.onIssueDropped,
    this.isLast = false,
  });

  final String columnId;
  final int index;
  final IssueDropCallback onIssueDropped;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: columnId,
          targetIndex: index,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: isHovering ? 42 : (isLast ? 54 : 6),
          margin: EdgeInsets.only(bottom: isLast ? 0 : 4),
          decoration: BoxDecoration(
            color: isHovering ? const Color(0xFFE0F2FE) : Colors.transparent,
            border: Border.all(
              color: isHovering ? const Color(0xFF38BDF8) : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: isHovering
              ? const Text(
                  'ここに移動',
                  style: TextStyle(
                    color: Color(0xFF0369A1),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        );
      },
    );
  }
}
