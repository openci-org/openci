import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import 'planning_event.dart';

typedef ChangedFilesRequest =
    Future<http.Response> Function(String path, Map<String, String>? query);

class _Indeterminate implements Exception {
  const _Indeterminate(this.reason);
  final String reason;
}

/// Only bounded, revision-consistent API responses can authorize skipping CI.
class GitHubChangedFiles {
  const GitHubChangedFiles(this.request);
  final ChangedFilesRequest request;

  Future<ChangedFilesResult> fetch(PlanningEvent event) async {
    final base = event.webhook.pullRequestNumber != null
        ? event.baseSha
        : event.beforeSha;
    try {
      if (base == null) throw const _Indeterminate('missing_base_sha');
      if (RegExp(r'^0+$').hasMatch(base)) {
        throw const _Indeterminate('new_branch');
      }
      if (event.isForced) throw const _Indeterminate('force_push');
      final paths = event.webhook.pullRequestNumber != null
          ? await _pullRequest(event)
          : await _push(event);
      return ChangedFilesResult(
        paths: paths.toList()..sort(),
        isComplete: true,
        baseSha: base,
        headSha: event.webhook.commitSha,
      );
    } on _Indeterminate catch (error) {
      return _incomplete(event, base, error.reason);
    } on TimeoutException {
      return _incomplete(event, base, 'github_timeout');
    } on http.ClientException {
      return _incomplete(event, base, 'github_transport_error');
    } on FormatException {
      return _incomplete(event, base, 'invalid_github_response');
    }
  }

  ChangedFilesResult _incomplete(
    PlanningEvent event,
    String? base,
    String reason,
  ) => ChangedFilesResult(
    paths: const [],
    isComplete: false,
    baseSha: base,
    headSha: event.webhook.commitSha,
    reason: reason,
  );

  Future<Object?> _get(
    String path, {
    Map<String, String>? query,
    bool comparison = false,
  }) async {
    final response = await request(path, query);
    if (response.statusCode == 429 ||
        (response.statusCode == 403 &&
            (response.headers['x-ratelimit-remaining'] == '0' ||
                response.headers.containsKey('retry-after')))) {
      throw const _Indeterminate('github_rate_limited');
    }
    if (response.statusCode >= 500) {
      throw const _Indeterminate('github_unavailable');
    }
    if (comparison && response.statusCode == 404) {
      throw const _Indeterminate('comparison_unavailable');
    }
    // Authorization and configuration errors must not become successful plans.
    if (response.statusCode != 200) {
      throw StateError('GitHub changed-file request failed');
    }
    return jsonDecode(response.body);
  }

  String _repo(PlanningEvent event) =>
      'repos/${Uri.encodeComponent(event.webhook.owner)}/'
      '${Uri.encodeComponent(event.webhook.repo)}';

  Future<Set<String>> _pullRequest(PlanningEvent event) async {
    final path = '${_repo(event)}/pulls/${event.webhook.pullRequestNumber}';
    final initial = await _get(path);
    final count = _prCount(initial, event);
    // The API caps even paginated results at 3,000. Be conservative at the cap.
    if (count >= 3000) throw const _Indeterminate('github_file_limit');
    final paths = <String>{};
    final filenames = <String>{};
    for (var page = 1; (page - 1) * 100 < count; page++) {
      final data = await _get(
        '$path/files',
        query: {'per_page': '100', 'page': page.toString()},
      );
      final expected = (count - (page - 1) * 100).clamp(0, 100);
      if (data is! List || data.length != expected) {
        throw const _Indeterminate('incomplete_file_list');
      }
      _addFiles(data, filenames, paths);
    }
    if (filenames.length != count ||
        _prCount(await _get(path), event) != count) {
      throw const _Indeterminate('pr_changed_during_fetch');
    }
    return paths;
  }

  int _prCount(Object? value, PlanningEvent event) {
    if (value is! Map<String, dynamic>) {
      throw const _Indeterminate('invalid_github_response');
    }
    final head = value['head'];
    final base = value['base'];
    if (head is! Map<String, dynamic> ||
        base is! Map<String, dynamic> ||
        head['repo'] is! Map<String, dynamic> ||
        base['repo'] is! Map<String, dynamic>) {
      throw const InvalidPlanningInput('untrusted_pull_request');
    }
    if (head['repo']['id'] != event.repositoryId ||
        base['repo']['id'] != event.repositoryId) {
      throw const InvalidPlanningInput('untrusted_pull_request');
    }
    if (head['sha'] != event.webhook.commitSha ||
        base['sha'] != event.baseSha ||
        value['number'] != event.webhook.pullRequestNumber) {
      throw const _Indeterminate('pr_revision_changed');
    }
    final count = value['changed_files'];
    if (count is! int || count < 0) {
      throw const _Indeterminate('invalid_github_response');
    }
    return count;
  }

  Future<Set<String>> _push(PlanningEvent event) async {
    final base = event.beforeSha!;
    final head = event.webhook.commitSha;
    final data = await _get(
      '${_repo(event)}/compare/$base...$head',
      query: {'per_page': '1'},
      comparison: true,
    );
    if (data is! Map<String, dynamic>) {
      throw const _Indeterminate('invalid_github_response');
    }
    // GitHub's comparison uses the merge base. A diverged/rewound push is not
    // the required before/after tree diff and must run without filtering.
    if (data['base_commit'] is! Map ||
        data['base_commit']['sha'] != base ||
        data['merge_base_commit'] is! Map ||
        data['merge_base_commit']['sha'] != base ||
        !['ahead', 'identical'].contains(data['status']) ||
        (data['status'] == 'identical' && base != head)) {
      throw const _Indeterminate('non_linear_push');
    }
    final files = data['files'];
    if (files is! List) {
      throw const _Indeterminate('incomplete_file_list');
    }
    if (files.length >= 300) {
      throw const _Indeterminate('github_file_limit');
    }
    final paths = <String>{};
    _addFiles(files, <String>{}, paths);
    return paths;
  }

  void _addFiles(
    List<Object?> files,
    Set<String> filenames,
    Set<String> paths,
  ) {
    for (final file in files) {
      if (file is! Map<String, dynamic> || !_validPath(file['filename'])) {
        throw const _Indeterminate('invalid_github_response');
      }
      final name = file['filename'] as String;
      if (!filenames.add(name)) {
        throw const _Indeterminate('incomplete_file_list');
      }
      paths.add(name);
      if (file['status'] == 'renamed' || file['previous_filename'] != null) {
        if (!_validPath(file['previous_filename'])) {
          throw const _Indeterminate('invalid_github_response');
        }
        paths.add(file['previous_filename'] as String);
      }
    }
  }

  bool _validPath(Object? value) =>
      value is String &&
      value.isNotEmpty &&
      !value.startsWith('/') &&
      !value.contains('\u0000') &&
      !value
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..');
}
