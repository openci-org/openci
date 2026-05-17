import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'issue_board_ima_utils.dart';
import 'issue_board_ima_board_columns.dart';
import 'issue_board_ima_models.dart';
import 'issue_board_ima_app_shell.dart';
import 'issue_board_ima_overview.dart';

class IssueCardDropTarget extends StatefulWidget {
  const IssueCardDropTarget({
    super.key,
    required this.issue,
    this.subIssues = const [],
    this.buildStatus,
    this.isReviewGroupCard = false,
    required this.sourceColumnId,
    required this.index,
    required this.isStartingCursorAgent,
    required this.requiresLongPressDrag,
    required this.onTap,
    this.onSubIssueTap,
    this.onStartCursorAgent,
    required this.onIssueDropped,
  });

  final Issue issue;
  final List<Issue> subIssues;
  final CardBuildStatus? buildStatus;
  final bool isReviewGroupCard;
  final String sourceColumnId;
  final int index;
  final bool isStartingCursorAgent;
  final bool requiresLongPressDrag;
  final VoidCallback onTap;
  final ValueChanged<String>? onSubIssueTap;
  final VoidCallback? onStartCursorAgent;
  final IssueDropCallback onIssueDropped;

  @override
  State<IssueCardDropTarget> createState() => _IssueCardDropTargetState();
}

class _IssueCardDropTargetState extends State<IssueCardDropTarget> {
  final _cardKey = GlobalKey();
  bool _isHovering = false;
  bool _insertAfter = false;

  void _updateDropPosition(Offset globalPosition) {
    final renderObject = _cardKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    final localPosition = renderObject.globalToLocal(globalPosition);
    final nextInsertAfter = localPosition.dy > renderObject.size.height / 2;

    if (_isHovering == true && _insertAfter == nextInsertAfter) {
      return;
    }

    setState(() {
      _isHovering = true;
      _insertAfter = nextInsertAfter;
    });
  }

  void _clearDropPosition() {
    if (!_isHovering) {
      return;
    }

    setState(() => _isHovering = false);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<IssueDragData>(
      onWillAcceptWithDetails: (details) {
        _updateDropPosition(details.offset);
        return true;
      },
      onMove: (details) => _updateDropPosition(details.offset),
      onLeave: (_) => _clearDropPosition(),
      onAcceptWithDetails: (details) {
        widget.onIssueDropped(
          issueId: details.data.issueId,
          targetColumnId: widget.sourceColumnId,
          targetIndex: widget.index + (_insertAfter ? 1 : 0),
        );
        _clearDropPosition();
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            KeyedSubtree(
              key: _cardKey,
              child: IssueCardDraggable(
                issue: widget.issue,
                subIssues: widget.subIssues,
                buildStatus: widget.buildStatus,
                isReviewGroupCard: widget.isReviewGroupCard,
                sourceColumnId: widget.sourceColumnId,
                isStartingCursorAgent: widget.isStartingCursorAgent,
                requiresLongPressDrag: widget.requiresLongPressDrag,
                onTap: widget.onTap,
                onSubIssueTap: widget.onSubIssueTap,
                onStartCursorAgent: widget.onStartCursorAgent,
              ),
            ),
            if (_isHovering)
              Positioned(
                left: 10,
                right: 10,
                top: _insertAfter ? null : -3,
                bottom: _insertAfter ? -3 : null,
                child: const DropIndicator(),
              ),
          ],
        );
      },
    );
  }
}

class DropIndicator extends StatelessWidget {
  const DropIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.32),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class IssueCardDraggable extends StatefulWidget {
  const IssueCardDraggable({
    super.key,
    required this.issue,
    this.subIssues = const [],
    this.buildStatus,
    this.isReviewGroupCard = false,
    required this.sourceColumnId,
    required this.isStartingCursorAgent,
    required this.requiresLongPressDrag,
    required this.onTap,
    this.onSubIssueTap,
    this.onStartCursorAgent,
  });

  final Issue issue;
  final List<Issue> subIssues;
  final CardBuildStatus? buildStatus;
  final bool isReviewGroupCard;
  final String sourceColumnId;
  final bool isStartingCursorAgent;
  final bool requiresLongPressDrag;
  final VoidCallback onTap;
  final ValueChanged<String>? onSubIssueTap;
  final VoidCallback? onStartCursorAgent;

  @override
  State<IssueCardDraggable> createState() => _IssueCardDraggableState();
}

class _IssueCardDraggableState extends State<IssueCardDraggable> {
  static const _liftPreviewDelay = Duration(milliseconds: 280);
  static const _liftPreviewCancelSlop = 8.0;

  Timer? _liftPreviewTimer;
  Timer? _tapSuppressionTimer;
  Offset? _pressStartPosition;
  bool _isLiftPreviewVisible = false;
  bool _suppressNextTap = false;

  @override
  void dispose() {
    _liftPreviewTimer?.cancel();
    _tapSuppressionTimer?.cancel();
    super.dispose();
  }

  void _startLiftPreviewTimer(PointerDownEvent event) {
    _liftPreviewTimer?.cancel();
    _pressStartPosition = event.position;
    _liftPreviewTimer = Timer(_liftPreviewDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLiftPreviewVisible = true;
        _suppressNextTap = true;
      });
    });
  }

  void _cancelLiftPreview() {
    _liftPreviewTimer?.cancel();
    _liftPreviewTimer = null;
    _pressStartPosition = null;

    if (!_isLiftPreviewVisible || !mounted) {
      return;
    }

    setState(() {
      _isLiftPreviewVisible = false;
    });
  }

  void _handlePointerUp() {
    final shouldSuppressTap = _suppressNextTap;
    _cancelLiftPreview();

    if (!shouldSuppressTap) {
      return;
    }

    _tapSuppressionTimer?.cancel();
    _tapSuppressionTimer = Timer(const Duration(milliseconds: 250), () {
      _suppressNextTap = false;
      _tapSuppressionTimer = null;
    });
  }

  void _clearTapSuppression() {
    _tapSuppressionTimer?.cancel();
    _tapSuppressionTimer = null;
    _suppressNextTap = false;
  }

  void _handleTap() {
    final shouldSuppressTap = _suppressNextTap;
    _clearTapSuppression();

    if (shouldSuppressTap) {
      return;
    }

    widget.onTap();
  }

  void _finishDragInteraction() {
    _cancelLiftPreview();
    _clearTapSuppression();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final startPosition = _pressStartPosition;
    if (startPosition == null || _isLiftPreviewVisible) {
      return;
    }

    if ((event.position - startPosition).distance > _liftPreviewCancelSlop) {
      _liftPreviewTimer?.cancel();
      _liftPreviewTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = IssueDragData(
      issueId: widget.issue.id,
      sourceColumnId: widget.sourceColumnId,
    );
    Widget buildCard({
      bool isDragging = false,
      bool isDragPlaceholder = false,
      bool includeActions = true,
    }) {
      if (widget.isReviewGroupCard) {
        return ReviewGroupIssueCard(
          issue: widget.issue,
          isDragging: isDragging,
          isDragPlaceholder: isDragPlaceholder,
        );
      }

      return IssueCard(
        issue: widget.issue,
        subIssues: widget.subIssues,
        buildStatus: widget.buildStatus,
        onSubIssueTap: widget.onSubIssueTap,
        isDragging: isDragging,
        isDragPlaceholder: isDragPlaceholder,
        isStartingCursorAgent: includeActions && widget.isStartingCursorAgent,
        onStartCursorAgent: includeActions ? widget.onStartCursorAgent : null,
      );
    }

    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 290,
        child: Opacity(
          opacity: 0.96,
          child: Transform.translate(
            offset: const Offset(0, -8),
            child: Transform.rotate(
              angle: -0.035,
              child: Transform.scale(
                scale: 1.04,
                child: buildCard(isDragging: true, includeActions: false),
              ),
            ),
          ),
        ),
      ),
    );
    final childWhenDragging = Transform.scale(
      scale: 0.98,
      child: Opacity(
        opacity: 0.28,
        child: buildCard(isDragPlaceholder: true, includeActions: false),
      ),
    );
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isLiftPreviewVisible ? 1.025 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            0,
            _isLiftPreviewVisible ? -6 : 0,
            0,
          ),
          child: buildCard(isDragging: _isLiftPreviewVisible),
        ),
      ),
    );

    final draggable = widget.requiresLongPressDrag
        ? LongPressDraggable<IssueDragData>(
            data: data,
            delay: mobileDragStartDelay,
            hitTestBehavior: HitTestBehavior.opaque,
            onDragStarted: _finishDragInteraction,
            onDragCompleted: _finishDragInteraction,
            onDraggableCanceled: (_, _) => _finishDragInteraction(),
            onDragEnd: (_) => _finishDragInteraction(),
            feedback: feedback,
            childWhenDragging: childWhenDragging,
            child: child,
          )
        : Draggable<IssueDragData>(
            data: data,
            hitTestBehavior: HitTestBehavior.opaque,
            onDragStarted: _finishDragInteraction,
            onDragCompleted: _finishDragInteraction,
            onDraggableCanceled: (_, _) => _finishDragInteraction(),
            onDragEnd: (_) => _finishDragInteraction(),
            feedback: feedback,
            childWhenDragging: childWhenDragging,
            child: child,
          );

    if (widget.requiresLongPressDrag) {
      return draggable;
    }

    return Listener(
      onPointerDown: _startLiftPreviewTimer,
      onPointerMove: _handlePointerMove,
      onPointerUp: (_) => _handlePointerUp(),
      onPointerCancel: (_) => _finishDragInteraction(),
      child: draggable,
    );
  }
}

class IssueCard extends StatelessWidget {
  const IssueCard({
    super.key,
    required this.issue,
    this.subIssues = const [],
    this.buildStatus,
    this.onSubIssueTap,
    this.isDragging = false,
    this.isDragPlaceholder = false,
    this.isStartingCursorAgent = false,
    this.onStartCursorAgent,
  });

  final Issue issue;
  final List<Issue> subIssues;
  final CardBuildStatus? buildStatus;
  final ValueChanged<String>? onSubIssueTap;
  final bool isDragging;
  final bool isDragPlaceholder;
  final bool isStartingCursorAgent;
  final VoidCallback? onStartCursorAgent;

  @override
  Widget build(BuildContext context) {
    final githubUrl = issue.githubUrl;
    final weightEstimate = issue.weightEstimate;
    final cardWeight = issue.statusId == closedStatusId
        ? issue.resolution?.actualWeight
        : weightEstimate?.value;
    final cardWeightTooltip = issue.statusId == closedStatusId
        ? '実績weight $cardWeight'
        : 'Weight $cardWeight / 信頼度 ${((weightEstimate?.confidence ?? 0) * 100).round()}%';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
      decoration: BoxDecoration(
        color: isDragPlaceholder ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(
          color: isDragging || isDragPlaceholder
              ? const Color(0xFF38BDF8).withValues(alpha: 0.48)
              : const Color(0xFFDDE7F0),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDragging
                  ? 0.22
                  : isDragPlaceholder
                  ? 0
                  : 0.035,
            ),
            blurRadius: isDragging ? 30 : 14,
            offset: Offset(0, isDragging ? 18 : 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTight = constraints.maxWidth < 300;
          final body = issue.body.trim();
          final visibleLabelLimit = isTight ? 3 : 5;
          final visibleLabels = issue.labels.take(visibleLabelLimit).toList();
          final hiddenLabelCount = issue.labels.length - visibleLabels.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        RepoBadge(repo: issue.repo),
                        if (cardWeight != null)
                          WeightBadge(
                            value: cardWeight,
                            tooltip: cardWeightTooltip,
                            isActual: issue.statusId == closedStatusId,
                          ),
                      ],
                    ),
                  ),
                  if (githubUrl != null) ...[
                    const SizedBox(width: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        GitHubLinkCopyButton(url: githubUrl),
                        CursorAgentCardButton(
                          issue: issue,
                          isStarting: isStartingCursorAgent,
                          onStart: onStartCursorAgent,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                issue.title,
                maxLines: isTight ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  height: 1.28,
                ),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: isTight ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
              if (issue.subIssuesSummary != null || subIssues.isNotEmpty) ...[
                const SizedBox(height: 10),
                IssueCardSubIssuesSection(
                  summary: issue.subIssuesSummary,
                  subIssues: subIssues,
                  onIssueTap: onSubIssueTap,
                ),
              ],
              if (visibleLabels.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final label in visibleLabels) LabelPill(label: label),
                    if (hiddenLabelCount > 0)
                      LabelPill(label: '+$hiddenLabelCount'),
                  ],
                ),
              ],
              const SizedBox(height: 11),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IssueIdMetaChip(
                    issueId: issue.displayId,
                    isPending: issue.isTicketNumberPending,
                  ),
                  if (issue.dueDate != null)
                    DueDatePill(dueDate: issue.dueDate!),
                  if (issue.parentIssue != null)
                    ParentIssueMetaChip(parentIssue: issue.parentIssue!),
                  if (issue.pullRequests.isNotEmpty)
                    PullRequestBadge(pullRequests: issue.pullRequests),
                  BuildStatusBadge(status: buildStatus),
                  CommentMetaChip(comments: issue.comments),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class ReviewGroupIssueCard extends StatelessWidget {
  const ReviewGroupIssueCard({
    super.key,
    required this.issue,
    this.isDragging = false,
    this.isDragPlaceholder = false,
  });

  final Issue issue;
  final bool isDragging;
  final bool isDragPlaceholder;

  @override
  Widget build(BuildContext context) {
    final weight = issue.statusId == closedStatusId
        ? issue.resolution?.actualWeight
        : issue.weightEstimate?.value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: isDragPlaceholder ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(
          color: isDragging || isDragPlaceholder
              ? const Color(0xFF38BDF8).withValues(alpha: 0.48)
              : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDragging
                  ? 0.18
                  : isDragPlaceholder
                  ? 0
                  : 0.02,
            ),
            blurRadius: isDragging ? 24 : 8,
            offset: Offset(0, isDragging ? 14 : 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              issue.isTicketNumberPending
                  ? const _IssueCreatingBadge()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        issue.displayId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  issue.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (weight != null)
                ReviewGroupPill(
                  label: 'W$weight',
                  color: issue.statusId == closedStatusId
                      ? const Color(0xFF15803D)
                      : const Color(0xFF2563EB),
                  icon: Icons.speed_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReviewLinkedIssueReferenceCard extends StatelessWidget {
  const ReviewLinkedIssueReferenceCard({super.key, required this.reference});

  final IssuePullRequestLinkedIssue reference;

  @override
  Widget build(BuildContext context) {
    final isClosed = reference.state == 'closed';
    final stateColor = isClosed
        ? const Color(0xFF15803D)
        : const Color(0xFF64748B);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: reference.url == null
          ? null
          : () => unawaited(launchUrlExternal(reference.url!)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#${reference.number}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    reference.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ReviewGroupPill(
              label: isClosed ? 'closed' : 'open',
              color: stateColor,
              icon: isClosed
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class SubIssuesProgressMeter extends StatelessWidget {
  const SubIssuesProgressMeter({super.key, required this.summary});

  final IssueSubIssuesSummary summary;

  @override
  Widget build(BuildContext context) {
    final color = summary.completed == summary.total
        ? const Color(0xFF16A34A)
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sub-issues ${summary.completed}/${summary.total}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${summary.percentCompleted}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: summary.progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class IssueCardSubIssuesSection extends StatelessWidget {
  const IssueCardSubIssuesSection({
    super.key,
    required this.summary,
    required this.subIssues,
    this.onIssueTap,
  });

  final IssueSubIssuesSummary? summary;
  final List<Issue> subIssues;
  final ValueChanged<String>? onIssueTap;

  @override
  Widget build(BuildContext context) {
    final currentSummary = summary;
    final completed = currentSummary?.completed ?? 0;
    final total = currentSummary?.total ?? subIssues.length;
    final percentCompleted = currentSummary?.percentCompleted ?? 0;
    final progress = currentSummary?.progress ?? 0;
    final color = total > 0 && completed == total
        ? const Color(0xFF16A34A)
        : Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_tree_outlined, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sub-issues $completed/$total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percentCompleted%',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          if (subIssues.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            SubIssuesList(
              subIssues: subIssues,
              onIssueTap: onIssueTap,
              isEmbedded: true,
            ),
          ],
        ],
      ),
    );
  }
}

class SubIssuesList extends StatelessWidget {
  const SubIssuesList({
    super.key,
    required this.subIssues,
    this.workspaceId,
    this.referenceSubIssues = const [],
    this.onIssueTap,
    this.isEmbedded = false,
  });

  final List<Issue> subIssues;
  final String? workspaceId;
  final List<IssueSubIssueReference> referenceSubIssues;
  final ValueChanged<String>? onIssueTap;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (final issue in subIssues)
        SubIssueListRow(issue: issue, onTap: onIssueTap),
      for (final subIssue in referenceSubIssues)
        SubIssueReferenceRow(
          subIssue: subIssue,
          workspaceId: workspaceId,
          onTap: onIssueTap,
        ),
    ];
    final list = Column(
      children: [
        for (final entry in rows.indexed) ...[
          entry.$2,
          if (entry.$1 != rows.length - 1)
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
        ],
      ],
    );
    if (isEmbedded) {
      return list;
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: list,
    );
  }
}

class SubIssueReferenceList extends StatelessWidget {
  const SubIssueReferenceList({
    super.key,
    required this.subIssues,
    this.workspaceId,
    this.onIssueTap,
  });

  final List<IssueSubIssueReference> subIssues;
  final String? workspaceId;
  final ValueChanged<String>? onIssueTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (final entry in subIssues.indexed) ...[
            SubIssueReferenceRow(
              subIssue: entry.$2,
              workspaceId: workspaceId,
              onTap: onIssueTap,
            ),
            if (entry.$1 != subIssues.length - 1)
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],
        ],
      ),
    );
  }
}

class SubIssueListRow extends StatelessWidget {
  const SubIssueListRow({super.key, required this.issue, this.onTap});

  final Issue issue;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final isClosed = issue.statusId == closedStatusId;
    final isCreating = issue.isTicketNumberPending;
    final iconColor = isClosed
        ? const Color(0xFF8250DF)
        : const Color(0xFF1F883D);
    return InkWell(
      onTap: onTap == null || isCreating ? null : () => onTap!(issue.id),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          children: [
            Icon(
              isClosed
                  ? Icons.check_circle_outline_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 15,
              color: iconColor,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                issue.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isClosed
                      ? const Color(0xFF64748B)
                      : const Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  decoration: isClosed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: 7),
            isCreating
                ? const _IssueCreatingBadge()
                : Text(
                    issue.displayId,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class SubIssueReferenceRow extends StatelessWidget {
  const SubIssueReferenceRow({
    super.key,
    required this.subIssue,
    this.workspaceId,
    this.onTap,
  });

  final IssueSubIssueReference subIssue;
  final String? workspaceId;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final issueId = subIssue.issueId;
    final currentWorkspaceId = workspaceId;
    if (issueId.isNotEmpty &&
        currentWorkspaceId != null &&
        currentWorkspaceId.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .doc('workspaces/$currentWorkspaceId/issues/$issueId')
            .snapshots(),
        builder: (context, snapshot) {
          final issueSnapshot = snapshot.data;
          if (issueSnapshot != null && issueSnapshot.exists) {
            final issue = Issue.fromDocument(issueSnapshot);
            if (issue.isTicketNumberPending) {
              return _SubIssueReferenceContent(
                title: issue.title,
                isClosed: issue.statusId == closedStatusId,
                isCreating: true,
              );
            }
            return SubIssueListRow(issue: issue, onTap: onTap);
          }
          return _SubIssueReferenceContent(
            title: subIssue.title,
            isClosed: subIssue.state == 'closed',
            isCreating: true,
          );
        },
      );
    }
    return _SubIssueReferenceContent(
      title: subIssue.title,
      isClosed: subIssue.state == 'closed',
      trailingLabel: subIssue.number > 0 ? '#${subIssue.number}' : '',
      onTap: onTap == null || issueId.isEmpty ? null : () => onTap!(issueId),
    );
  }
}

class _SubIssueReferenceContent extends StatelessWidget {
  const _SubIssueReferenceContent({
    required this.title,
    required this.isClosed,
    this.trailingLabel = '',
    this.isCreating = false,
    this.onTap,
  });

  final String title;
  final bool isClosed;
  final String trailingLabel;
  final bool isCreating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = isClosed
        ? const Color(0xFF8250DF)
        : const Color(0xFF1F883D);
    return InkWell(
      onTap: isCreating ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          children: [
            Icon(
              isClosed
                  ? Icons.check_circle_outline_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 15,
              color: iconColor,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isClosed
                      ? const Color(0xFF64748B)
                      : const Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  decoration: isClosed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: 7),
            isCreating
                ? const _IssueCreatingBadge()
                : Text(
                    trailingLabel,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _IssueCreatingBadge extends StatelessWidget {
  const _IssueCreatingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFD97706),
            ),
          ),
          SizedBox(width: 5),
          Text(
            '作成中',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class IssueIdMetaChip extends StatelessWidget {
  const IssueIdMetaChip({
    super.key,
    required this.issueId,
    this.isPending = false,
  });

  final String issueId;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return const _IssueCreatingBadge();
    }

    return IssueMetaChip(
      label: issueId,
      trailing: IssueIdCopyButton(issueId: issueId),
    );
  }
}

class ParentIssueMetaChip extends StatelessWidget {
  const ParentIssueMetaChip({super.key, required this.parentIssue});

  final IssueParentIssue parentIssue;

  @override
  Widget build(BuildContext context) {
    return IssueMetaChip(
      icon: Icons.account_tree_outlined,
      label: parentIssue.number > 0
          ? 'Parent #${parentIssue.number}'
          : 'Parent',
    );
  }
}

class CommentMetaChip extends StatelessWidget {
  const CommentMetaChip({super.key, required this.comments});

  final int comments;

  @override
  Widget build(BuildContext context) {
    return IssueMetaChip(
      icon: Icons.chat_bubble_outline_rounded,
      label: '$comments',
    );
  }
}

class IssueMetaChip extends StatelessWidget {
  const IssueMetaChip({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.trailing,
  });

  final String label;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        leading == null && icon == null ? 8 : 5,
        3,
        6,
        3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 1), trailing!],
        ],
      ),
    );
  }
}

class IssueIdCopyButton extends StatelessWidget {
  const IssueIdCopyButton({super.key, required this.issueId});

  final String issueId;

  @override
  Widget build(BuildContext context) {
    return _CopyFeedbackIconButton(
      tooltip: 'Issue IDをコピー',
      copiedTooltip: 'Issue IDをコピーしました',
      text: issueId,
      successMessage: 'Issue IDをコピーしました',
      icon: const Icon(
        Icons.copy_rounded,
        size: 13,
        color: Color(0xFF94A3B8),
      ),
      iconSize: 13,
      dimension: 22,
    );
  }
}

class PullRequestBadge extends StatelessWidget {
  const PullRequestBadge({super.key, required this.pullRequests});

  final List<IssuePullRequest> pullRequests;

  @override
  Widget build(BuildContext context) {
    final latest = pullRequests.last;
    final label = pullRequests.length == 1
        ? 'PR #${latest.number}'
        : '${pullRequests.length} PRs';
    final prUrl = latest.url;
    return Tooltip(
      message: prUrl ?? 'Linked pull request',
      child: GestureDetector(
        onTap: prUrl != null ? () => unawaited(launchUrlExternal(prUrl)) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            border: Border.all(color: const Color(0xFFBFDBFE)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.alt_route_rounded,
                size: 14,
                color: Color(0xFF0EA5E9),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0369A1),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GitHubLinkCopyButton extends StatelessWidget {
  const GitHubLinkCopyButton({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return _CopyFeedbackIconButton(
      tooltip: 'GitHubリンクをコピー',
      copiedTooltip: 'GitHubリンクをコピーしました',
      text: url,
      successMessage: 'GitHubリンクをコピーしました',
      icon: const _CopyLinkIcon(),
      iconSize: 14,
      dimension: 26,
    );
  }
}

class _CopyLinkIcon extends StatelessWidget {
  const _CopyLinkIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Symbols.link_2_rounded,
      size: 17,
      color: Color(0xFF475569),
    );
  }
}

class _CopyFeedbackIconButton extends StatefulWidget {
  const _CopyFeedbackIconButton({
    required this.tooltip,
    required this.copiedTooltip,
    required this.text,
    required this.successMessage,
    required this.icon,
    required this.iconSize,
    required this.dimension,
  });

  final String tooltip;
  final String copiedTooltip;
  final String text;
  final String successMessage;
  final Widget icon;
  final double iconSize;
  final double dimension;

  @override
  State<_CopyFeedbackIconButton> createState() =>
      _CopyFeedbackIconButtonState();
}

class _CopyFeedbackIconButtonState extends State<_CopyFeedbackIconButton> {
  bool _copied = false;
  int _copyVersion = 0;

  Future<void> _handleCopy() async {
    final version = ++_copyVersion;
    await copyTextToClipboard(
      context,
      text: widget.text,
      successMessage: widget.successMessage,
    );
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted || version != _copyVersion) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.dimension,
      child: IconButton(
        tooltip: _copied ? widget.copiedTooltip : widget.tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: () => unawaited(_handleCopy()),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: _copied
              ? Icon(
                  Icons.check_rounded,
                  key: const ValueKey('copied'),
                  size: widget.iconSize,
                  color: const Color(0xFF22C55E),
                )
              : KeyedSubtree(
                  key: const ValueKey('copyIcon'),
                  child: widget.icon,
                ),
        ),
      ),
    );
  }
}

class CursorAgentCardButton extends StatelessWidget {
  const CursorAgentCardButton({
    super.key,
    required this.issue,
    required this.isStarting,
    this.onStart,
  });

  final Issue issue;
  final bool isStarting;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final hasPullRequest = issue.pullRequests.isNotEmpty;
    final isRunning = issue.cursorAgent?.isActive == true && !hasPullRequest;
    final isBusy = isStarting || isRunning;
    return SizedBox.square(
      dimension: 26,
      child: IconButton(
        tooltip: isRunning ? 'Cursor agentを実行中' : 'Cursor agentを開始',
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: isBusy ? null : onStart,
        icon: isBusy
            ? const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.smart_toy_outlined, size: 16),
      ),
    );
  }
}

class RepoBadge extends StatelessWidget {
  const RepoBadge({super.key, required this.repo});

  final String repo;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          repo,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class LabelPill extends StatelessWidget {
  const LabelPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 128),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class DueDatePill extends StatelessWidget {
  const DueDatePill({super.key, required this.dueDate});

  final DateTime dueDate;

  @override
  Widget build(BuildContext context) {
    final status = dueDateStatus(dueDate);
    final colors = switch (status) {
      DueDateStatus.overdue => (
        background: const Color(0xFFFEE2E2),
        foreground: const Color(0xFFB91C1C),
      ),
      DueDateStatus.today => (
        background: const Color(0xFFFFEDD5),
        foreground: const Color(0xFFC2410C),
      ),
      DueDateStatus.soon => (
        background: const Color(0xFFFEF3C7),
        foreground: const Color(0xFF92400E),
      ),
      DueDateStatus.later => (
        background: const Color(0xFFEFF6FF),
        foreground: const Color(0xFF1D4ED8),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_outlined, size: 12, color: colors.foreground),
          const SizedBox(width: 3),
          Text(
            dueDateLabel(dueDate),
            style: TextStyle(
              color: colors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class WeightBadge extends StatelessWidget {
  const WeightBadge({
    super.key,
    required this.value,
    required this.tooltip,
    this.isActual = false,
  });

  final int value;
  final String tooltip;
  final bool isActual;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isActual ? const Color(0xFFF0FDF4) : const Color(0xFFEEF2FF),
          border: Border.all(
            color: isActual ? const Color(0xFFBBF7D0) : const Color(0xFFC7D2FE),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'W$value',
          style: TextStyle(
            color: isActual ? const Color(0xFF15803D) : const Color(0xFF4338CA),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class IssueWeightOverrideDialog extends StatefulWidget {
  const IssueWeightOverrideDialog({super.key, required this.issue});

  final Issue issue;

  @override
  State<IssueWeightOverrideDialog> createState() =>
      _IssueWeightOverrideDialogState();
}

class _IssueWeightOverrideDialogState extends State<IssueWeightOverrideDialog> {
  int? _estimateWeight;
  int? _actualWeight;

  @override
  void initState() {
    super.initState();
    final estimateWeight = widget.issue.weightEstimate?.value;
    final actualWeight = widget.issue.resolution?.actualWeight;
    _estimateWeight = validIssueWeights.contains(estimateWeight)
        ? estimateWeight
        : null;
    _actualWeight = validIssueWeights.contains(actualWeight)
        ? actualWeight
        : _estimateWeight;
  }

  void _save() {
    final estimateWeight = _estimateWeight;
    if (estimateWeight == null) {
      return;
    }
    final actualWeight = widget.issue.statusId == closedStatusId
        ? _actualWeight
        : null;
    if (widget.issue.statusId == closedStatusId && actualWeight == null) {
      return;
    }
    Navigator.of(context).pop(
      IssueWeightOverrideDraft(
        estimateWeight: estimateWeight,
        actualWeight: actualWeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.issue.statusId == closedStatusId;
    final canSave =
        _estimateWeight != null && (!isClosed || _actualWeight != null);

    return AlertDialog(
      title: const Text('Weight上書き'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LLM estimateと完了時のactual weightを手動で補正します。',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _estimateWeight,
            decoration: const InputDecoration(
              labelText: '推定weight',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final weight in validIssueWeights)
                DropdownMenuItem(value: weight, child: Text('W$weight')),
            ],
            onChanged: (value) => setState(() => _estimateWeight = value),
          ),
          if (isClosed) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _actualWeight,
              decoration: const InputDecoration(
                labelText: '実績weight',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final weight in validIssueWeights)
                  DropdownMenuItem(value: weight, child: Text('W$weight')),
              ],
              onChanged: (value) => setState(() => _actualWeight = value),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class IssueWeightPanel extends StatelessWidget {
  const IssueWeightPanel({
    super.key,
    required this.issue,
    required this.isEstimating,
    this.isOverriding = false,
    this.onEstimate,
    this.onOverride,
  });

  final Issue issue;
  final bool isEstimating;
  final bool isOverriding;
  final Future<void> Function()? onEstimate;
  final Future<void> Function()? onOverride;

  @override
  Widget build(BuildContext context) {
    final estimate = issue.weightEstimate;
    final value = estimate?.value;
    final resolution = issue.resolution;
    final actualWeight = resolution?.actualWeight;
    final isClosed = issue.statusId == 'done';
    final subtitle = switch (estimate?.status) {
      'done' when estimate?.manualOverride == true && value != null => '手動上書き',
      'done' when value != null =>
        '信頼度 ${(estimate!.confidence * 100).round()}%'
            '${estimate.estimatedAt == null ? '' : ' / ${formatDate(estimate.estimatedAt!)}'}',
      'failed' => estimate?.error ?? 'Weight推定に失敗しました',
      'estimating' => 'Weightを推定中...',
      _ => 'まだ推定していません',
    };
    final reason = estimate?.reason;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isEstimating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        value == null ? 'W?' : 'W$value',
                        style: const TextStyle(
                          color: Color(0xFF4338CA),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LLM weight',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reason,
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: isEstimating || isOverriding ? null : onEstimate,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(value == null ? '推定' : '再推定'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isEstimating || isOverriding ? null : onOverride,
                    icon: isOverriding
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('上書き'),
                  ),
                ],
              ),
            ],
          ),
          if (isClosed && actualWeight != null) ...[
            const SizedBox(height: 12),
            _ActualWeightRow(
              predictedWeight: value,
              actualWeight: actualWeight,
              delta: resolution?.weightDelta,
              isManualOverride: resolution?.actualWeightManualOverride == true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActualWeightRow extends StatelessWidget {
  const _ActualWeightRow({
    required this.predictedWeight,
    required this.actualWeight,
    this.delta,
    this.isManualOverride = false,
  });

  static const _validWeights = [1, 2, 4, 8, 16, 32];

  static bool _isAdjacent(int a, int b) {
    final idxA = _validWeights.indexOf(a);
    final idxB = _validWeights.indexOf(b);
    if (idxA < 0 || idxB < 0) return (a - b).abs() <= 1;
    return (idxA - idxB).abs() <= 1;
  }

  final int? predictedWeight;
  final int actualWeight;
  final int? delta;
  final bool isManualOverride;

  @override
  Widget build(BuildContext context) {
    final isExact = predictedWeight == actualWeight;
    final isClose =
        predictedWeight != null && _isAdjacent(predictedWeight!, actualWeight);
    final deltaColor = isExact
        ? const Color(0xFF15803D)
        : isClose
        ? const Color(0xFFA16207)
        : const Color(0xFFDC2626);
    final deltaBg = isExact
        ? const Color(0xFFF0FDF4)
        : isClose
        ? const Color(0xFFFEFCE8)
        : const Color(0xFFFEF2F2);
    final deltaLabel = delta == null
        ? ''
        : delta == 0
        ? '一致'
        : delta! > 0
        ? '過大推定 +$delta'
        : '過小推定 $delta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: deltaBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.assessment_outlined, size: 16, color: deltaColor),
          const SizedBox(width: 8),
          Text(
            '実績 W$actualWeight',
            style: TextStyle(
              color: deltaColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          if (predictedWeight != null) ...[
            const SizedBox(width: 6),
            Text(
              '(予測 W$predictedWeight)',
              style: TextStyle(color: deltaColor.withAlpha(180), fontSize: 12),
            ),
          ],
          if (isManualOverride) ...[
            const SizedBox(width: 6),
            Text(
              'manual',
              style: TextStyle(
                color: deltaColor.withAlpha(180),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const Spacer(),
          if (deltaLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: deltaColor.withAlpha(25),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: deltaColor.withAlpha(60)),
              ),
              child: Text(
                deltaLabel,
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CursorAgentPanel extends StatelessWidget {
  const CursorAgentPanel({
    super.key,
    required this.issue,
    required this.isStarting,
    this.onStart,
  });

  final Issue issue;
  final bool isStarting;
  final Future<void> Function()? onStart;

  @override
  Widget build(BuildContext context) {
    final hasGitHubIssue = issue.githubUrl != null;
    final hasPullRequest = issue.pullRequests.isNotEmpty;
    final agent = issue.cursorAgent;
    final isRunning = agent?.isActive == true && !hasPullRequest;
    final isBusy = isStarting || isRunning;
    final subtitle = switch (agent?.status) {
      'running' when !hasPullRequest =>
        'Cursor agentを実行中です。Run ID: ${agent!.shortRunId}',
      'starting' when !hasPullRequest => 'Cursor agentを開始中...',
      'done' || 'running' || 'starting' => 'Cursor agentがpull requestを作成しました。',
      'failed' => agent?.errorMessage ?? 'Cursor agentの開始に失敗しました。',
      _ when hasGitHubIssue => 'Cursor Cloud Agentを開始して、このissueの対応PRを作成します。',
      _ => 'agentを開始する前に、このissueをGitHubに接続してください。',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.smart_toy_outlined,
                    color: Color(0xFF2563EB),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cursor agent',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: hasGitHubIssue && !isBusy ? onStart : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(isRunning ? '実行中' : '開始'),
          ),
        ],
      ),
    );
  }
}
