typedef Json = Map<String, Object?>;

Json jsonObject(Object? value) => (value as Map<Object?, Object?>).cast<String, Object?>();
List<Json> jsonObjects(Object? value) => (value as List<Object?>).map(jsonObject).toList();

class Repository {
  const Repository({required this.id, required this.fullName, this.defaultBranch});
  final int id;
  final String fullName;
  final String? defaultBranch;
  factory Repository.fromJson(Json json) => Repository(
    id: json['id'] as int,
    fullName: json['full_name'] as String,
    defaultBranch: json['default_branch'] as String?,
  );
  String get apiPath => '/repos/${fullName.split('/').map(Uri.encodeComponent).join('/')}';
  Json toJson() => {'id': id, 'full_name': fullName, 'default_branch': defaultBranch};
}

class PullRequest {
  PullRequest({
    required this.number,
    required this.title,
    required this.head,
    required this.headRef,
    required this.base,
    required this.baseRef,
    this.url = '',
    this.state = 'open',
    this.merged = false,
    this.draft = false,
    this.sameRepo = true,
    this.mergeCommit,
    this.parent,
    this.boundary,
  });
  final int number;
  final String title, url, state, headRef;
  final bool merged, draft, sameRepo;
  final String? mergeCommit;
  String head, base, baseRef;
  int? parent;
  String? boundary;
  bool get isOpen => state == 'open';

  factory PullRequest.fromApi(Json raw, int repoId) {
    final head = jsonObject(raw['head']), base = jsonObject(raw['base']);
    return PullRequest(
      number: raw['number'] as int,
      title: raw['title'] as String,
      url: raw['html_url'] as String? ?? '',
      state: raw['state'] as String,
      merged: raw['merged'] == true || raw['merged_at'] != null,
      mergeCommit: raw['merge_commit_sha'] as String?,
      draft: raw['draft'] == true,
      head: head['sha'] as String,
      headRef: head['ref'] as String,
      base: base['sha'] as String,
      baseRef: base['ref'] as String,
      sameRepo:
          head['repo'] != null &&
          base['repo'] != null &&
          jsonObject(head['repo'])['id'] == repoId &&
          jsonObject(base['repo'])['id'] == repoId,
    );
  }

  // Keep JSON keys compatible with the earlier SQLite records.
  factory PullRequest.fromJson(Json json) => PullRequest(
    number: json['number'] as int,
    title: json['title'] as String,
    url: json['url'] as String? ?? '',
    state: json['state'] as String,
    merged: json['merged'] == true,
    mergeCommit: json['mergeCommit'] as String?,
    draft: json['draft'] == true,
    sameRepo: json['sameRepo'] == true,
    head: json['head'] as String,
    headRef: json['headRef'] as String,
    base: json['base'] as String,
    baseRef: json['baseRef'] as String,
    parent: json['parent'] as int?,
    boundary: json['boundary'] as String?,
  );
  PullRequest copy() => PullRequest.fromJson(toJson());
  Json toJson() => {
    'number': number,
    'title': title,
    'url': url,
    'state': state,
    'merged': merged,
    if (mergeCommit != null) 'mergeCommit': mergeCommit,
    'draft': draft,
    'sameRepo': sameRepo,
    'head': head,
    'headRef': headRef,
    'base': base,
    'baseRef': baseRef,
    'parent': parent,
    'boundary': boundary,
  };
}

class RepositoryState {
  RepositoryState([List<PullRequest>? pulls]) : pulls = pulls ?? [];
  final List<PullRequest> pulls;
  factory RepositoryState.fromJson(Json json) =>
      RepositoryState(jsonObjects(json['pulls']).map(PullRequest.fromJson).toList());
  Json toJson() => {'pulls': pulls.map((p) => p.toJson()).toList()};
}

class BranchChange {
  const BranchChange({
    required this.number,
    required this.headRef,
    required this.oldHead,
    required this.newHead,
    required this.oldBase,
    required this.newBase,
  });
  final int number;
  final String headRef, oldHead, newHead, oldBase, newBase;
  bool get changesHead => oldHead != newHead;
  bool get mutates => changesHead || oldBase != newBase;
  factory BranchChange.fromJson(Json j) => BranchChange(
    number: j['number'] as int,
    headRef: j['headRef'] as String,
    oldHead: j['oldHead'] as String,
    newHead: j['newHead'] as String,
    oldBase: j['oldBase'] as String,
    newBase: j['newBase'] as String,
  );
  Json toJson() => {
    'number': number,
    'headRef': headRef,
    'oldHead': oldHead,
    'newHead': newHead,
    'oldBase': oldBase,
    'newBase': newBase,
  };
}

class Operation {
  Operation({required this.changes, required this.nextState, this.phase = 'prepared'});
  final List<BranchChange> changes;
  final RepositoryState nextState;
  String phase;
  factory Operation.fromJson(Json j) => Operation(
    changes: jsonObjects(j['changes']).map(BranchChange.fromJson).toList(),
    nextState: RepositoryState.fromJson(jsonObject(j['nextState'])),
    phase: j['phase'] as String,
  );
  Json toJson() => {
    'changes': changes.map((c) => c.toJson()).toList(),
    'nextState': nextState.toJson(),
    'phase': phase,
  };
}

class SavedRepository {
  SavedRepository(this.state, this.operation);
  RepositoryState state;
  final Operation? operation;
}

class Job {
  const Job({required this.id, required this.event, required this.payload, this.attempts = 0});
  final String id, event;
  final Json payload;
  final int attempts;
}

class RestackException implements Exception {
  const RestackException(this.message, {this.number, this.files = const []});
  final String message;
  final int? number;
  final List<String> files;
  @override
  String toString() => message;
}

class RetryException implements Exception {
  const RetryException(this.message);
  final String message;
  @override
  String toString() => message;
}
