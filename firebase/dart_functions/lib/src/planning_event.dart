import 'dart:convert';

import 'github_webhook_payload.dart';

/// A permanent input error. Never includes webhook contents or source code.
class InvalidPlanningInput implements Exception {
  const InvalidPlanningInput(this.reason);
  final String reason;
}

class PlanningEvent {
  const PlanningEvent(
    this.webhook,
    this.repositoryId,
    this.ownerId, {
    this.baseSha,
    this.beforeSha,
    this.isForced = false,
    this.isPullRequestClosed = false,
  });

  final GitHubWebhookPayload webhook;
  final int repositoryId;
  final int ownerId;
  final String? baseSha;
  final String? beforeSha;
  final bool isForced;
  final bool isPullRequestClosed;

  bool get isRelease => webhook.eventType == 'release';

  /// Release payloads have no commit SHA. Pin the tag before fetching source.
  PlanningEvent withReleaseCommit(String sha) {
    if (!isRelease || !_isCommitSha(sha)) _invalid();
    return PlanningEvent(
      webhook.copyWith(commitSha: sha),
      repositoryId,
      ownerId,
    );
  }

  static PlanningEvent? parse(String eventType, String payload) {
    try {
      final raw = _object(jsonDecode(payload));
      if (eventType == 'push' && raw['deleted'] == true) return null;
      if (!['push', 'pull_request', 'release'].contains(eventType)) _invalid();
      if (eventType == 'release' && raw['action'] != 'published') return null;
      if (eventType == 'pull_request' &&
          ![
            'opened',
            'synchronize',
            'reopened',
            'closed',
          ].contains(raw['action']) &&
          !(raw['action'] == 'edited' &&
              raw['changes'] is Map<String, dynamic> &&
              (raw['changes'] as Map<String, dynamic>)['base'] is Map)) {
        return null;
      }
      _positiveId(_object(raw['installation'])['id']);
      final repository = _object(raw['repository']);
      final repositoryId = _positiveId(repository['id']);
      final owner = _object(repository['owner']);
      final ownerId = _positiveId(owner['id']);
      for (final name in [owner['login'], repository['name']]) {
        if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(_nonempty(name))) {
          _invalid();
        }
      }
      if (eventType == 'release') {
        final release = _object(raw['release']);
        if (release['draft'] == true) return null;
        if (release['draft'] != false) _invalid();
        _positiveId(release['id']);
        final tag = _nonempty(release['tag_name']);
        if (!_validTag(tag)) _invalid();
        return PlanningEvent(
          GitHubWebhookPayload(
            installationId: _positiveId(_object(raw['installation'])['id']),
            eventType: 'release',
            owner: owner['login'] as String,
            repo: repository['name'] as String,
            // Never use target_commitish: it may be a moving branch or stale
            // metadata for a tag which already existed when published.
            commitSha: '',
            branch: 'refs/tags/$tag',
            triggerBranch: tag,
            triggerType: 'release',
            commitMessage: tag,
          ),
          repositoryId,
          ownerId,
        );
      }
      final String sha;
      if (eventType == 'pull_request') {
        final pr = _object(raw['pull_request']);
        final head = _object(pr['head']);
        final base = _object(pr['base']);
        if (_positiveId(_object(base['repo'])['id']) != repositoryId) {
          _invalid();
        }
        // The workflow runs with team secrets. Only a head in the same
        // repository is trusted; missing/deleted repositories fail closed too.
        if (raw['action'] != 'closed' &&
            _positiveId(_object(head['repo'])['id']) != repositoryId) {
          throw const InvalidPlanningInput('untrusted_pull_request');
        }
        sha = _nonempty(head['sha']);
        _nonempty(head['ref']);
        _nonempty(base['ref']);
        _nonempty(pr['title']);
        _positiveId(raw['number']);
      } else {
        final ref = _nonempty(raw['ref']);
        if (!ref.startsWith('refs/heads/') && !ref.startsWith('refs/tags/')) {
          _invalid();
        }
        _nonempty(ref.startsWith('refs/heads/') ? ref.substring(11) : ref);
        sha = _nonempty(raw['after']);
        if (raw['head_commit'] != null) {
          final head = _object(raw['head_commit']);
          if (head['id'] != null && head['id'] != sha) _invalid();
        }
      }
      if (!_isCommitSha(sha)) {
        _invalid();
      }
      return PlanningEvent(
        GitHubWebhookPayload.fromRawJson(eventType: eventType, rawJson: raw),
        repositoryId,
        ownerId,
        baseSha: eventType == 'pull_request'
            ? _optionalSha(_object(_object(raw['pull_request'])['base'])['sha'])
            : null,
        beforeSha: eventType == 'push' ? _optionalSha(raw['before']) : null,
        isForced: raw['forced'] == true,
        isPullRequestClosed:
            eventType == 'pull_request' && raw['action'] == 'closed',
      );
    } on FormatException {
      _invalid();
    } on TypeError {
      _invalid();
    }
  }
}

bool _isCommitSha(String sha) =>
    RegExp(r'^(?:[0-9a-f]{40}|[0-9a-f]{64})$').hasMatch(sha) &&
    !RegExp(r'^0+$').hasMatch(sha);

bool _validTag(String tag) =>
    tag != '@' &&
    !RegExp(r'[\x00-\x20\x7f~^:?*\[\\]').hasMatch(tag) &&
    !tag.contains('..') &&
    !tag.contains('@{') &&
    !tag.endsWith('.') &&
    tag
        .split('/')
        .every(
          (part) =>
              part.isNotEmpty &&
              !part.startsWith('.') &&
              !part.endsWith('.lock'),
        );

String? _optionalSha(Object? value) {
  if (value == null) return null;
  if (value is! String ||
      !RegExp(r'^(?:[0-9a-f]{40}|[0-9a-f]{64})$').hasMatch(value)) {
    _invalid();
  }
  return value;
}

Never _invalid() => throw const InvalidPlanningInput('invalid_payload');

Map<String, dynamic> _object(Object? value) =>
    value is Map<String, dynamic> ? value : _invalid();

String _nonempty(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : _invalid();

int _positiveId(Object? value) =>
    value is int && value > 0 && value <= 9007199254740991 ? value : _invalid();
