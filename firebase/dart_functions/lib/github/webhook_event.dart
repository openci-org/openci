enum GitHubEventType {
  pullRequest('pull_request'),
  push('push'),
  create('create'),
  release('release'),
  issueComment('issue_comment'),
  unknown('unknown');

  final String value;
  const GitHubEventType(this.value);

  static GitHubEventType fromString(String value) {
    return GitHubEventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GitHubEventType.unknown,
    );
  }
}

enum WebhookAction {
  opened('opened'),
  synchronize('synchronize'),
  published('published'),
  created('created'),
  unknown('unknown');

  final String value;
  const WebhookAction(this.value);

  static WebhookAction? fromString(String? value) {
    if (value == null) return null;
    return WebhookAction.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WebhookAction.unknown,
    );
  }
}

class WebhookEvent {
  final GitHubEventType event;
  final WebhookAction? action;
  final String? ref;
  final String? refType;
  final WebhookRepository? repository;
  final WebhookSender? sender;
  final WebhookInstallation? installation;
  final WebhookPullRequest? pullRequest;
  final WebhookRelease? release;
  final WebhookComment? comment;
  final Map<String, dynamic> raw;

  WebhookEvent({
    required this.event,
    required this.raw,
    this.action,
    this.ref,
    this.refType,
    this.repository,
    this.sender,
    this.installation,
    this.pullRequest,
    this.release,
    this.comment,
  });

  factory WebhookEvent.fromRequest({
    required String event,
    required Map<String, dynamic> body,
  }) {
    return WebhookEvent(
      event: GitHubEventType.fromString(event),
      raw: body,
      action: WebhookAction.fromString(body['action'] as String?),
      ref: body['ref'] as String?,
      refType: body['ref_type'] as String?,
      repository: body['repository'] != null
          ? WebhookRepository.fromJson(
              body['repository'] as Map<String, dynamic>,
            )
          : null,
      sender: body['sender'] != null
          ? WebhookSender.fromJson(body['sender'] as Map<String, dynamic>)
          : null,
      installation: body['installation'] != null
          ? WebhookInstallation.fromJson(
              body['installation'] as Map<String, dynamic>,
            )
          : null,
      pullRequest: body['pull_request'] != null
          ? WebhookPullRequest.fromJson(
              body['pull_request'] as Map<String, dynamic>,
            )
          : null,
      release: body['release'] != null
          ? WebhookRelease.fromJson(body['release'] as Map<String, dynamic>)
          : null,
      comment: body['comment'] != null
          ? WebhookComment.fromJson(body['comment'] as Map<String, dynamic>)
          : null,
    );
  }
}

class WebhookRepository {
  final String fullName;
  final String name;
  final String defaultBranch;

  WebhookRepository({
    required this.fullName,
    required this.name,
    required this.defaultBranch,
  });

  factory WebhookRepository.fromJson(Map<String, dynamic> json) {
    return WebhookRepository(
      fullName: json['full_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      defaultBranch: json['default_branch'] as String? ?? 'main',
    );
  }

  String get owner => fullName.split('/').first;
}

class WebhookSender {
  final String login;

  WebhookSender({required this.login});

  factory WebhookSender.fromJson(Map<String, dynamic> json) {
    return WebhookSender(login: json['login'] as String? ?? '');
  }
}

class WebhookInstallation {
  final int id;

  WebhookInstallation({required this.id});

  factory WebhookInstallation.fromJson(Map<String, dynamic> json) {
    return WebhookInstallation(id: json['id'] as int? ?? 0);
  }
}

class WebhookPullRequest {
  final int number;
  final String headSha;
  final String headRef;
  final String baseRef;

  WebhookPullRequest({
    required this.number,
    required this.headSha,
    required this.headRef,
    required this.baseRef,
  });

  factory WebhookPullRequest.fromJson(Map<String, dynamic> json) {
    return WebhookPullRequest(
      number: json['number'] as int? ?? 0,
      headSha: (json['head'] as Map<String, dynamic>?)?['sha'] as String? ?? '',
      headRef: (json['head'] as Map<String, dynamic>?)?['ref'] as String? ?? '',
      baseRef: (json['base'] as Map<String, dynamic>?)?['ref'] as String? ?? '',
    );
  }
}

class WebhookRelease {
  final String tagName;
  final String? htmlUrl;
  final List<WebhookReleaseAsset> assets;

  WebhookRelease({required this.tagName, this.htmlUrl, this.assets = const []});

  factory WebhookRelease.fromJson(Map<String, dynamic> json) {
    return WebhookRelease(
      tagName: json['tag_name'] as String? ?? '',
      htmlUrl: json['html_url'] as String?,
      assets:
          (json['assets'] as List<dynamic>?)
              ?.map(
                (a) => WebhookReleaseAsset.fromJson(a as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class WebhookReleaseAsset {
  final String name;
  final String browserDownloadUrl;

  WebhookReleaseAsset({required this.name, required this.browserDownloadUrl});

  factory WebhookReleaseAsset.fromJson(Map<String, dynamic> json) {
    return WebhookReleaseAsset(
      name: json['name'] as String? ?? '',
      browserDownloadUrl: json['browser_download_url'] as String? ?? '',
    );
  }
}

class WebhookComment {
  final String body;

  WebhookComment({required this.body});

  factory WebhookComment.fromJson(Map<String, dynamic> json) {
    return WebhookComment(body: json['body'] as String? ?? '');
  }
}
