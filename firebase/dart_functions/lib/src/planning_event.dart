import 'dart:convert';

import 'github_webhook_payload.dart';

/// A permanent input error. Never includes webhook contents or source code.
class InvalidPlanningInput implements Exception {
  const InvalidPlanningInput(this.reason);
  final String reason;
}

class PlanningEvent {
  const PlanningEvent(this.webhook, this.repositoryId, this.ownerId);

  final GitHubWebhookPayload webhook;
  final int repositoryId;
  final int ownerId;

  static PlanningEvent? parse(String eventType, String payload) {
    try {
      final raw = _object(jsonDecode(payload));
      if (eventType == 'push' && raw['deleted'] == true) return null;
      if (eventType != 'push' && eventType != 'pull_request') _invalid();
      if (eventType == 'pull_request' &&
          !['opened', 'synchronize', 'reopened'].contains(raw['action'])) {
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
      final String sha;
      if (eventType == 'pull_request') {
        final pr = _object(raw['pull_request']);
        final head = _object(pr['head']);
        final base = _object(pr['base']);
        if (_positiveId(_object(base['repo'])['id']) != repositoryId) {
          _invalid();
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
      if (!RegExp(r'^(?:[0-9a-f]{40}|[0-9a-f]{64})$').hasMatch(sha) ||
          RegExp(r'^0+$').hasMatch(sha)) {
        _invalid();
      }
      return PlanningEvent(
        GitHubWebhookPayload.fromRawJson(eventType: eventType, rawJson: raw),
        repositoryId,
        ownerId,
      );
    } on FormatException {
      _invalid();
    } on TypeError {
      _invalid();
    }
  }
}

Never _invalid() => throw const InvalidPlanningInput('invalid_payload');

Map<String, dynamic> _object(Object? value) =>
    value is Map<String, dynamic> ? value : _invalid();

String _nonempty(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : _invalid();

int _positiveId(Object? value) =>
    value is int && value > 0 && value <= 9007199254740991 ? value : _invalid();
