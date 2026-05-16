part of 'issue_board_ima_page.dart';

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
    final actualWeight = _asInt(data['actualWeight']);
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
      workStartSource: _asString(data['workStartSource']),
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
    final total = _asInt(data['total']);
    if (total <= 0) {
      return null;
    }
    final completed = _asInt(data['completed']).clamp(0, total).toInt();
    final rawPercent = _asInt(data['percentCompleted']);
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
    final issueId = _asString(data['issueId']);
    final nodeId = _asString(data['nodeId']);
    final number = _asInt(data['number']);
    final url = _normalizedOptionalUrl(_asString(data['url']));
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
    final title = _asString(data['title']);
    final number = _asInt(data['number']);
    if (title.isEmpty && number <= 0) {
      return null;
    }
    return IssueSubIssueReference(
      issueId: _asString(data['issueId']),
      nodeId: _asString(data['nodeId']),
      number: number,
      title: title.isEmpty ? '#$number' : title,
      url: _normalizedOptionalUrl(_asString(data['url'])),
      state: _asString(data['state'], 'open'),
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
    this.subIssuesSummary,
    this.subIssues = const [],
    this.parentIssue,
    this.cursorAgent,
  }) : displayId = displayId ?? issueKey ?? id;

  factory Issue.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final githubIssue = _asMap(data['githubIssue']);
    final number = _asInt(githubIssue['number']);
    final repo = _asString(data['repo']);
    final issueKey = _asString(data['issueKey']);

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
      title: _asString(data['title'], '#$number'),
      body: _asString(data['body']),
      githubUrl: _normalizedOptionalUrl(_asString(githubIssue['url'])),
      labels: _asStringList(data['labels']),
      comments: _asInt(data['comments']),
      priority: _priorityFromString(_asString(data['priority'], 'medium')),
      dueDate: _asDate(data['dueDate']),
      statusId: _asString(data['statusId'], 'triage'),
      rank: _asDouble(data['rank']),
      closedAt: _asDate(data['closedAt']),
      weightEstimate: IssueWeightEstimate.fromMap(
        _asMap(data['weightEstimate']),
      ),
      resolution: IssueResolution.fromMap(_asMap(data['resolution'])),
      pullRequests: _asList(data['pullRequests'])
          .map((value) => IssuePullRequest.fromMap(_asMap(value)))
          .where((pullRequest) => pullRequest.number > 0)
          .toList(),
      subIssuesSummary: IssueSubIssuesSummary.fromMap(
        _asMap(
          githubIssue['subIssuesSummary'] ?? githubIssue['sub_issues_summary'],
        ),
      ),
      subIssues: _asList(githubIssue['subIssues'])
          .map((value) => IssueSubIssueReference.fromMap(_asMap(value)))
          .whereType<IssueSubIssueReference>()
          .toList(),
      parentIssue: IssueParentIssue.fromMap(_asMap(githubIssue['parentIssue'])),
      cursorAgent: CursorAgentState.fromMap(_asMap(data['cursorAgent'])),
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
  final IssueSubIssuesSummary? subIssuesSummary;
  final List<IssueSubIssueReference> subIssues;
  final IssueParentIssue? parentIssue;
  final CursorAgentState? cursorAgent;
}

class CursorAgentState {
  const CursorAgentState({
    required this.status,
    this.agentId = '',
    this.runId = '',
    this.errorMessage = '',
  });

  static CursorAgentState? fromMap(Map<String, dynamic> data) {
    final status = _asString(data['status']);
    if (status.isEmpty) {
      return null;
    }

    return CursorAgentState(
      status: status,
      agentId: _asString(data['agentId']),
      runId: _asString(data['runId']),
      errorMessage: _asString(data['errorMessage']),
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
      number: _asInt(data['number']),
      title: _asString(data['title'], 'Pull request'),
      url: _normalizedOptionalUrl(_asString(data['url'])),
      state: _asString(data['state'], 'open'),
      merged: data['merged'] == true,
      branch: _asString(data['branch']),
      createdAt: _asDate(data['createdAt']),
      linkedIssues: _asList(data['linkedIssues'])
          .map((value) => IssuePullRequestLinkedIssue.fromMap(_asMap(value)))
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

class IssuePullRequestLinkedIssue {
  const IssuePullRequestLinkedIssue({
    required this.number,
    required this.title,
    this.url,
    required this.state,
  });

  factory IssuePullRequestLinkedIssue.fromMap(Map<String, dynamic> data) {
    final number = _asInt(data['number']);
    return IssuePullRequestLinkedIssue(
      number: number,
      title: _asString(data['title'], '#$number'),
      url: _normalizedOptionalUrl(_asString(data['url'])),
      state: _asString(data['state'], 'open').toLowerCase(),
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
    required this.branch,
    required this.additions,
    required this.deletions,
    required this.changedFiles,
    required this.filesTruncated,
    required this.files,
  });

  factory IssuePullRequestDiff.fromMap(Map<String, dynamic> data) {
    return IssuePullRequestDiff(
      repository: _asString(data['repository']),
      pullRequestNumber: _asInt(data['pullRequestNumber']),
      title: _asString(data['title'], 'Pull request'),
      url: _asString(data['url']),
      state: _asString(data['state'], 'open'),
      merged: data['merged'] == true,
      branch: _asString(data['branch']),
      additions: _asInt(data['additions']),
      deletions: _asInt(data['deletions']),
      changedFiles: _asInt(data['changedFiles']),
      filesTruncated: data['filesTruncated'] == true,
      files: _asList(data['files'])
          .map((value) => IssuePullRequestDiffFile.fromMap(_asMap(value)))
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
  final String branch;
  final int additions;
  final int deletions;
  final int changedFiles;
  final bool filesTruncated;
  final List<IssuePullRequestDiffFile> files;
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
    final previousFilename = _asString(data['previousFilename']);
    return IssuePullRequestDiffFile(
      filename: _asString(data['filename']),
      status: _asString(data['status'], 'modified'),
      additions: _asInt(data['additions']),
      deletions: _asInt(data['deletions']),
      changes: _asInt(data['changes']),
      patch: _asString(data['patch']),
      patchTruncated: data['patchTruncated'] == true,
      blobUrl: _asString(data['blobUrl']),
      rawUrl: _asString(data['rawUrl']),
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
    final value = _asInt(data['value']);
    final normalizedValue = hasValue && value >= 0 ? value : null;
    return IssueWeightEstimate(
      status: _asString(
        data['status'],
        normalizedValue == null ? 'unknown' : 'done',
      ),
      value: normalizedValue,
      confidence: _asDouble(data['confidence']),
      reason: _asString(data['reason']),
      model: _asString(data['model']),
      promptVersion: _asString(data['promptVersion']),
      inputHash: _asString(data['inputHash']),
      source: _asString(data['source']),
      manualOverride: data['manualOverride'] == true,
      estimatedAt: _asDate(data['estimatedAt']),
      error: _asString(data['error']).isEmpty ? null : _asString(data['error']),
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
    final fullName = _asString(data['fullName']);
    final parts = fullName.split('/');

    return GitHubRepository(
      fullName: fullName,
      name: _asString(data['name'], parts.length > 1 ? parts[1] : fullName),
      owner: _asString(data['owner'], parts.isEmpty ? '' : parts.first),
      private: data['private'] == true,
      defaultBranch: _asString(data['defaultBranch'], 'main'),
    );
  }

  final String fullName;
  final String name;
  final String owner;
  final bool private;
  final String defaultBranch;
}
