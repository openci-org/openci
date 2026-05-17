import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'issue_board_ima_utils.dart';
import 'issue_board_ima_app_shell.dart';

typedef IssueDropCallback =
    void Function({
      required String issueId,
      required String targetColumnId,
      required int targetIndex,
      bool clearPullRequests,
    });

typedef IssuePullRequestLinkCallback =
    Future<void> Function({
      required String issueId,
      required String repository,
      required IssuePullRequest pullRequest,
    });

typedef IssueWeightOverrideCallback =
    Future<void> Function({
      required String issueId,
      required IssueWeightOverrideDraft draft,
    });

typedef IssuePullRequestCreateCallback =
    Future<IssuePullRequest> Function({
      required String issueId,
      required String repository,
      required String head,
      required String base,
      required String title,
      required String body,
    });

typedef WorkspaceRecentBranchLoadCallback =
    Future<WorkspaceRecentBranchList> Function();

typedef WorkspaceRecentBranchCreatePullRequestCallback =
    Future<IssuePullRequest> Function(WorkspaceRecentBranch branch);

class IssueDragData {
  const IssueDragData({required this.issueId, required this.sourceColumnId});

  final String issueId;
  final String sourceColumnId;
}

class CloseIssueDialogResult {
  const CloseIssueDialogResult(this.issueId);

  final String issueId;
}

class EditIssueDialogResult {
  const EditIssueDialogResult({required this.issueId, required this.draft});

  final String issueId;
  final NewIssueDraft draft;
}

class IssueWeightOverrideDraft {
  const IssueWeightOverrideDraft({
    required this.estimateWeight,
    this.actualWeight,
  });

  final int estimateWeight;
  final int? actualWeight;
}

class NewIssueDraft {
  const NewIssueDraft({
    required this.title,
    required this.body,
    required this.repo,
    required this.githubUrl,
    required this.labels,
    required this.columnId,
    required this.priority,
    required this.dueDate,
  });

  final String title;
  final String body;
  final String repo;
  final String? githubUrl;
  final List<String> labels;
  final String columnId;
  final Priority priority;
  final DateTime? dueDate;
}

class BoardColumn {
  const BoardColumn({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.issues,
  });

  final String id;
  final String title;
  final String description;
  final Color color;
  final List<Issue> issues;
}

class IssueResolution {
  const IssueResolution({
    this.actualWeight,
    this.weightDelta,
    this.cycleTimeMs,
    this.leadTimeMs,
    this.workStartSource = '',
    this.actualWeightManualOverride = false,
  });

  static IssueResolution? fromMap(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }
    final hasActualWeight = data.containsKey('actualWeight');
    final actualWeight = asInt(data['actualWeight']);
    return IssueResolution(
      actualWeight: hasActualWeight && actualWeight >= 0 ? actualWeight : null,
      weightDelta: data['weightDelta'] is num
          ? (data['weightDelta'] as num).toInt()
          : null,
      cycleTimeMs: data['cycleTimeMs'] is num
          ? (data['cycleTimeMs'] as num).toInt()
          : null,
      leadTimeMs: data['leadTimeMs'] is num
          ? (data['leadTimeMs'] as num).toInt()
          : null,
      workStartSource: asString(data['workStartSource']),
      actualWeightManualOverride: data['actualWeightManualOverride'] == true,
    );
  }

  final int? actualWeight;
  final int? weightDelta;
  final int? cycleTimeMs;
  final int? leadTimeMs;
  final String workStartSource;
  final bool actualWeightManualOverride;
}

class IssueSubIssuesSummary {
  const IssueSubIssuesSummary({
    required this.total,
    required this.completed,
    required this.percentCompleted,
  });

  static IssueSubIssuesSummary? fromMap(Map<String, dynamic> data) {
    final total = asInt(data['total']);
    if (total <= 0) {
      return null;
    }
    final completed = asInt(data['completed']).clamp(0, total).toInt();
    final rawPercent = asInt(data['percentCompleted']);
    final percentCompleted = rawPercent > 0
        ? rawPercent.clamp(0, 100).toInt()
        : ((completed / total) * 100).round();
    return IssueSubIssuesSummary(
      total: total,
      completed: completed,
      percentCompleted: percentCompleted,
    );
  }

  double get progress => (percentCompleted / 100).clamp(0, 1).toDouble();

  Map<String, Object> toFirestore() {
    return {
      'total': total,
      'completed': completed,
      'percentCompleted': percentCompleted,
    };
  }

  final int total;
  final int completed;
  final int percentCompleted;
}

class IssueParentIssue {
  const IssueParentIssue({
    required this.issueId,
    required this.nodeId,
    required this.number,
    this.url,
  });

  static IssueParentIssue? fromMap(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }
    final issueId = asString(data['issueId']);
    final nodeId = asString(data['nodeId']);
    final number = asInt(data['number']);
    final url = normalizedOptionalUrl(asString(data['url']));
    if (issueId.isEmpty && nodeId.isEmpty && number <= 0 && url == null) {
      return null;
    }
    return IssueParentIssue(
      issueId: issueId,
      nodeId: nodeId,
      number: number,
      url: url,
    );
  }

  final String issueId;
  final String nodeId;
  final int number;
  final String? url;
}

class IssueSubIssueReference {
  const IssueSubIssueReference({
    required this.issueId,
    required this.nodeId,
    required this.number,
    required this.title,
    this.url,
    required this.state,
  });

  static IssueSubIssueReference? fromMap(Map<String, dynamic> data) {
    final title = asString(data['title']);
    final number = asInt(data['number']);
    if (title.isEmpty && number <= 0) {
      return null;
    }
    return IssueSubIssueReference(
      issueId: asString(data['issueId']),
      nodeId: asString(data['nodeId']),
      number: number,
      title: title.isEmpty ? '#$number' : title,
      url: normalizedOptionalUrl(asString(data['url'])),
      state: asString(data['state'], 'open'),
    );
  }

  final String issueId;
  final String nodeId;
  final int number;
  final String title;
  final String? url;
  final String state;
}

class Issue {
  const Issue({
    required this.id,
    String? displayId,
    this.issueKey,
    this.githubNumber = 0,
    required this.repo,
    required this.title,
    this.body = '',
    this.githubUrl,
    required this.labels,
    required this.comments,
    required this.priority,
    this.dueDate,
    this.statusId = 'triage',
    this.rank = 0,
    this.closedAt,
    this.weightEstimate,
    this.resolution,
    this.pullRequests = const [],
    this.workBranch = '',
    this.subIssuesSummary,
    this.subIssues = const [],
    this.parentIssue,
    this.cursorAgent,
  }) : displayId = displayId ?? issueKey ?? id;

  factory Issue.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final githubIssue = asMap(data['githubIssue']);
    final number = asInt(githubIssue['number']);
    final repo = asString(data['repo']);
    final issueKey = asString(data['issueKey']);

    return Issue(
      id: doc.id,
      issueKey: issueKey.isEmpty ? null : issueKey,
      githubNumber: number,
      displayId: issueKey.isNotEmpty
          ? issueKey
          : number > 0
          ? '#$number'
          : doc.id,
      repo: repo,
      title: asString(data['title'], '#$number'),
      body: asString(data['body']),
      githubUrl: normalizedOptionalUrl(asString(githubIssue['url'])),
      labels: asStringList(data['labels']),
      comments: asInt(data['comments']),
      priority: priorityFromString(asString(data['priority'], 'medium')),
      dueDate: asDate(data['dueDate']),
      statusId: asString(data['statusId'], 'triage'),
      rank: asDouble(data['rank']),
      closedAt: asDate(data['closedAt']),
      weightEstimate: IssueWeightEstimate.fromMap(
        asMap(data['weightEstimate']),
      ),
      resolution: IssueResolution.fromMap(asMap(data['resolution'])),
      pullRequests: asList(data['pullRequests'])
          .map((value) => IssuePullRequest.fromMap(asMap(value)))
          .where((pullRequest) => pullRequest.number > 0)
          .toList(),
      workBranch: asString(data['workBranch'] ?? data['branch']),
      subIssuesSummary: IssueSubIssuesSummary.fromMap(
        asMap(
          githubIssue['subIssuesSummary'] ?? githubIssue['sub_issues_summary'],
        ),
      ),
      subIssues: asList(githubIssue['subIssues'])
          .map((value) => IssueSubIssueReference.fromMap(asMap(value)))
          .whereType<IssueSubIssueReference>()
          .toList(),
      parentIssue: IssueParentIssue.fromMap(asMap(githubIssue['parentIssue'])),
      cursorAgent: CursorAgentState.fromMap(asMap(data['cursorAgent'])),
    );
  }

  Issue copyWith({
    String? statusId,
    double? rank,
    DateTime? closedAt,
    bool clearClosedAt = false,
    List<IssuePullRequest>? pullRequests,
  }) {
    return Issue(
      id: id,
      displayId: displayId,
      issueKey: issueKey,
      githubNumber: githubNumber,
      repo: repo,
      title: title,
      body: body,
      githubUrl: githubUrl,
      labels: labels,
      comments: comments,
      priority: priority,
      dueDate: dueDate,
      statusId: statusId ?? this.statusId,
      rank: rank ?? this.rank,
      closedAt: clearClosedAt ? null : closedAt ?? this.closedAt,
      weightEstimate: weightEstimate,
      resolution: resolution,
      pullRequests: pullRequests ?? this.pullRequests,
      workBranch: workBranch,
      subIssuesSummary: subIssuesSummary,
      subIssues: subIssues,
      parentIssue: parentIssue,
      cursorAgent: cursorAgent,
    );
  }

  final String id;
  final String displayId;
  final String? issueKey;
  final int githubNumber;
  final String repo;
  final String title;
  final String body;
  final String? githubUrl;
  final List<String> labels;
  final int comments;
  final Priority priority;
  final DateTime? dueDate;
  final String statusId;
  final double rank;
  final DateTime? closedAt;
  final IssueWeightEstimate? weightEstimate;
  final IssueResolution? resolution;
  final List<IssuePullRequest> pullRequests;
  final String workBranch;
  final IssueSubIssuesSummary? subIssuesSummary;
  final List<IssueSubIssueReference> subIssues;
  final IssueParentIssue? parentIssue;
  final CursorAgentState? cursorAgent;

  bool get isTicketNumberPending =>
      issueKey == null &&
      githubNumber <= 0 &&
      repo.isNotEmpty &&
      displayId == id;
}

class CursorAgentState {
  const CursorAgentState({
    required this.status,
    this.agentId = '',
    this.runId = '',
    this.errorMessage = '',
  });

  static CursorAgentState? fromMap(Map<String, dynamic> data) {
    final status = asString(data['status']);
    if (status.isEmpty) {
      return null;
    }

    return CursorAgentState(
      status: status,
      agentId: asString(data['agentId']),
      runId: asString(data['runId']),
      errorMessage: asString(data['errorMessage']),
    );
  }

  bool get isActive => status == 'starting' || status == 'running';

  String get shortRunId {
    if (runId.length <= 8) {
      return runId;
    }
    return runId.substring(0, 8);
  }

  final String status;
  final String agentId;
  final String runId;
  final String errorMessage;
}

class IssuePullRequest {
  const IssuePullRequest({
    required this.number,
    required this.title,
    this.url,
    required this.state,
    required this.merged,
    required this.branch,
    this.createdAt,
    this.linkedIssues = const [],
  });

  factory IssuePullRequest.fromMap(Map<String, dynamic> data) {
    return IssuePullRequest(
      number: asInt(data['number']),
      title: asString(data['title'], 'Pull request'),
      url: normalizedOptionalUrl(asString(data['url'])),
      state: asString(data['state'], 'open'),
      merged: data['merged'] == true,
      branch: asString(data['branch']),
      createdAt: asDate(data['createdAt']),
      linkedIssues: asList(data['linkedIssues'])
          .map((value) => IssuePullRequestLinkedIssue.fromMap(asMap(value)))
          .where((issue) => issue.number > 0)
          .toList(),
    );
  }

  Map<String, Object?> toFirestore({required String repository}) {
    final parts = repository.split('/');
    final owner = parts.isEmpty ? '' : parts.first;
    final repo = parts.length > 1 ? parts[1] : '';
    return {
      'owner': owner,
      'repo': repo,
      'number': number,
      'url': url,
      'title': title,
      'branch': branch,
      'state': state,
      'merged': merged,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'linkedIssues': [
        for (final issue in linkedIssues) issue.toFirestore(),
      ],
    };
  }

  IssuePullRequest copyWith({String? state, bool? merged}) {
    return IssuePullRequest(
      number: number,
      title: title,
      url: url,
      state: state ?? this.state,
      merged: merged ?? this.merged,
      branch: branch,
      createdAt: createdAt,
      linkedIssues: linkedIssues,
    );
  }

  final int number;
  final String title;
  final String? url;
  final String state;
  final bool merged;
  final String branch;
  final DateTime? createdAt;
  final List<IssuePullRequestLinkedIssue> linkedIssues;
}

class WorkspaceRecentBranchList {
  const WorkspaceRecentBranchList({
    required this.branches,
    required this.repositories,
  });

  factory WorkspaceRecentBranchList.fromMap(Map<String, dynamic> data) {
    return WorkspaceRecentBranchList(
      branches: asList(data['branches'])
          .map((value) => WorkspaceRecentBranch.fromMap(asMap(value)))
          .where(
            (branch) => branch.name.isNotEmpty && branch.repository.isNotEmpty,
          )
          .toList(),
      repositories: asInt(data['repositories']),
    );
  }

  final List<WorkspaceRecentBranch> branches;
  final int repositories;
}

class WorkspaceRecentBranch {
  const WorkspaceRecentBranch({
    required this.repository,
    required this.name,
    this.sha = '',
    this.base = 'main',
    this.pushedAt,
    this.issueId = '',
    this.issueKey = '',
    this.issueTitle = '',
    this.issueStatusId = '',
  });

  factory WorkspaceRecentBranch.fromMap(Map<String, dynamic> data) {
    final issue = asMap(data['issue']);
    return WorkspaceRecentBranch(
      repository: asString(data['repository']),
      name: asString(data['name']),
      sha: asString(data['sha']),
      base: asString(data['base'], 'main'),
      pushedAt: DateTime.tryParse(asString(data['pushedAt'])),
      issueId: asString(issue['id']),
      issueKey: asString(issue['issueKey'], asString(issue['displayId'])),
      issueTitle: asString(issue['title']),
      issueStatusId: asString(issue['statusId']),
    );
  }

  String get key => '$repository:$name';

  bool get hasIssue => issueId.isNotEmpty;

  final String repository;
  final String name;
  final String sha;
  final String base;
  final DateTime? pushedAt;
  final String issueId;
  final String issueKey;
  final String issueTitle;
  final String issueStatusId;
}

class IssuePullRequestLinkedIssue {
  const IssuePullRequestLinkedIssue({
    required this.number,
    required this.title,
    this.url,
    required this.state,
  });

  factory IssuePullRequestLinkedIssue.fromMap(Map<String, dynamic> data) {
    final number = asInt(data['number']);
    return IssuePullRequestLinkedIssue(
      number: number,
      title: asString(data['title'], '#$number'),
      url: normalizedOptionalUrl(asString(data['url'])),
      state: asString(data['state'], 'open').toLowerCase(),
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'number': number,
      'title': title,
      'url': url,
      'state': state,
    };
  }

  final int number;
  final String title;
  final String? url;
  final String state;
}

class IssuePullRequestDiff {
  const IssuePullRequestDiff({
    required this.repository,
    required this.pullRequestNumber,
    required this.title,
    required this.url,
    required this.state,
    required this.merged,
    this.mergeable,
    this.mergeableState = '',
    required this.branch,
    required this.additions,
    required this.deletions,
    required this.changedFiles,
    required this.ci,
    required this.comments,
    required this.commentsTruncated,
    required this.filesTruncated,
    required this.files,
  });

  factory IssuePullRequestDiff.fromMap(Map<String, dynamic> data) {
    return IssuePullRequestDiff(
      repository: asString(data['repository']),
      pullRequestNumber: asInt(data['pullRequestNumber']),
      title: asString(data['title'], 'Pull request'),
      url: asString(data['url']),
      state: asString(data['state'], 'open'),
      merged: data['merged'] == true,
      mergeable: data['mergeable'] is bool ? data['mergeable'] as bool : null,
      mergeableState: asString(data['mergeableState']),
      branch: asString(data['branch']),
      additions: asInt(data['additions']),
      deletions: asInt(data['deletions']),
      changedFiles: asInt(data['changedFiles']),
      ci: PullRequestCiSummary.fromMap(asMap(data['ci'])),
      comments: asList(data['comments'])
          .map((value) => IssuePullRequestComment.fromMap(asMap(value)))
          .where((comment) => comment.body.isNotEmpty)
          .toList(),
      commentsTruncated: data['commentsTruncated'] == true,
      filesTruncated: data['filesTruncated'] == true,
      files: asList(data['files'])
          .map((value) => IssuePullRequestDiffFile.fromMap(asMap(value)))
          .where((file) => file.filename.isNotEmpty)
          .toList(),
    );
  }

  final String repository;
  final int pullRequestNumber;
  final String title;
  final String url;
  final String state;
  final bool merged;
  final bool? mergeable;
  final String mergeableState;
  final String branch;
  final int additions;
  final int deletions;
  final int changedFiles;
  final PullRequestCiSummary ci;
  final List<IssuePullRequestComment> comments;
  final bool commentsTruncated;
  final bool filesTruncated;
  final List<IssuePullRequestDiffFile> files;
}

enum IssuePullRequestCommentKind { conversation, review }

class IssuePullRequestComment {
  const IssuePullRequestComment({
    required this.id,
    required this.author,
    required this.authorAssociation,
    required this.body,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
    required this.kind,
    this.path,
    this.line,
    this.side,
    this.inReplyToId,
  });

  factory IssuePullRequestComment.fromMap(Map<String, dynamic> data) {
    final line = asInt(data['line']);
    return IssuePullRequestComment(
      id: asString(data['id']),
      author: asString(data['author'], 'unknown'),
      authorAssociation: asString(data['authorAssociation']),
      body: asString(data['body']),
      url: asString(data['url']),
      createdAt: asString(data['createdAt']),
      updatedAt: asString(data['updatedAt']),
      kind: asString(data['kind']) == 'review'
          ? IssuePullRequestCommentKind.review
          : IssuePullRequestCommentKind.conversation,
      path: emptyToNull(asString(data['path'])),
      line: line > 0 ? line : null,
      side: emptyToNull(asString(data['side'])),
      inReplyToId: emptyToNull(asString(data['inReplyToId'])),
    );
  }

  final String id;
  final String author;
  final String authorAssociation;
  final String body;
  final String url;
  final String createdAt;
  final String updatedAt;
  final IssuePullRequestCommentKind kind;
  final String? path;
  final int? line;
  final String? side;
  final String? inReplyToId;
}

enum PullRequestCiStatus { success, failure, pending, none, unknown }

class PullRequestCiSummary {
  const PullRequestCiSummary({
    required this.status,
    required this.total,
    required this.passed,
    required this.failed,
    required this.pending,
    required this.skipped,
    required this.checksTruncated,
  });

  factory PullRequestCiSummary.fromMap(Map<String, dynamic> data) {
    return PullRequestCiSummary(
      status: switch (asString(data['status'])) {
        'success' => PullRequestCiStatus.success,
        'failure' => PullRequestCiStatus.failure,
        'pending' => PullRequestCiStatus.pending,
        'unknown' => PullRequestCiStatus.unknown,
        _ => PullRequestCiStatus.none,
      },
      total: asInt(data['total']),
      passed: asInt(data['passed']),
      failed: asInt(data['failed']),
      pending: asInt(data['pending']),
      skipped: asInt(data['skipped']),
      checksTruncated: data['checksTruncated'] == true,
    );
  }

  final PullRequestCiStatus status;
  final int total;
  final int passed;
  final int failed;
  final int pending;
  final int skipped;
  final bool checksTruncated;

  bool get allPassed => status == PullRequestCiStatus.success && total > 0;
}

class IssuePullRequestDiffFile {
  const IssuePullRequestDiffFile({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    required this.changes,
    required this.patch,
    required this.patchTruncated,
    required this.blobUrl,
    required this.rawUrl,
    this.previousFilename,
  });

  factory IssuePullRequestDiffFile.fromMap(Map<String, dynamic> data) {
    final previousFilename = asString(data['previousFilename']);
    return IssuePullRequestDiffFile(
      filename: asString(data['filename']),
      status: asString(data['status'], 'modified'),
      additions: asInt(data['additions']),
      deletions: asInt(data['deletions']),
      changes: asInt(data['changes']),
      patch: asString(data['patch']),
      patchTruncated: data['patchTruncated'] == true,
      blobUrl: asString(data['blobUrl']),
      rawUrl: asString(data['rawUrl']),
      previousFilename: previousFilename.isEmpty ? null : previousFilename,
    );
  }

  final String filename;
  final String status;
  final int additions;
  final int deletions;
  final int changes;
  final String patch;
  final bool patchTruncated;
  final String blobUrl;
  final String rawUrl;
  final String? previousFilename;
}

class IssueWeightEstimate {
  const IssueWeightEstimate({
    required this.status,
    this.value,
    this.confidence = 0,
    this.reason = '',
    this.model = '',
    this.promptVersion = '',
    this.inputHash = '',
    this.source = '',
    this.manualOverride = false,
    this.estimatedAt,
    this.error,
  });

  static IssueWeightEstimate? fromMap(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }
    final hasValue = data.containsKey('value');
    final value = asInt(data['value']);
    final normalizedValue = hasValue && value >= 0 ? value : null;
    return IssueWeightEstimate(
      status: asString(
        data['status'],
        normalizedValue == null ? 'unknown' : 'done',
      ),
      value: normalizedValue,
      confidence: asDouble(data['confidence']),
      reason: asString(data['reason']),
      model: asString(data['model']),
      promptVersion: asString(data['promptVersion']),
      inputHash: asString(data['inputHash']),
      source: asString(data['source']),
      manualOverride: data['manualOverride'] == true,
      estimatedAt: asDate(data['estimatedAt']),
      error: asString(data['error']).isEmpty ? null : asString(data['error']),
    );
  }

  final String status;
  final int? value;
  final double confidence;
  final String reason;
  final String model;
  final String promptVersion;
  final String inputHash;
  final String source;
  final bool manualOverride;
  final DateTime? estimatedAt;
  final String? error;
}

class GitHubRepository {
  const GitHubRepository({
    required this.fullName,
    required this.name,
    required this.owner,
    required this.private,
    required this.defaultBranch,
  });

  factory GitHubRepository.fromMap(Map<String, dynamic> data) {
    final fullName = asString(data['fullName']);
    final parts = fullName.split('/');

    return GitHubRepository(
      fullName: fullName,
      name: asString(data['name'], parts.length > 1 ? parts[1] : fullName),
      owner: asString(data['owner'], parts.isEmpty ? '' : parts.first),
      private: data['private'] == true,
      defaultBranch: asString(data['defaultBranch'], 'main'),
    );
  }

  final String fullName;
  final String name;
  final String owner;
  final bool private;
  final String defaultBranch;
}
