import 'dart:convert';

import 'package:meta/meta.dart';

/// A snapshot of the event and checkout used by this execution.
///
/// Read through `OpenCI.context`. This does not query GitHub or indicate whether
/// a newer commit has arrived since the checkout was resolved.
@immutable
sealed class WorkflowContext {
  const WorkflowContext();

  /// Decodes the executor's versioned metadata from a complete environment.
  ///
  /// Without CI markers, missing metadata means [LocalContext]. Missing metadata
  /// in CI, malformed data and unsupported versions throw a [StateError].
  factory WorkflowContext.fromEnvironment(Map<String, String> environment) {
    final encoded = environment['OPENCI_CONTEXT'];
    if (encoded == null) {
      if (environment.containsKey('OPENCI_RUN_ID') ||
          environment.containsKey('OPENCI_BUILD_JOB_ID')) {
        throw StateError(
          'OPENCI_CONTEXT is missing. Update the OpenCI executor to use context.',
        );
      }
      return const LocalContext();
    }
    try {
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      if (data['schemaVersion'] is! int || data['schemaVersion'] != 1) {
        _invalid();
      }
      final repo = data['repository'] as Map<String, dynamic>;
      final baseUrl = Uri.parse(_text(repo['githubBaseUrl']));
      if (baseUrl.scheme != 'https' ||
          baseUrl.host.isEmpty ||
          baseUrl.userInfo.isNotEmpty ||
          baseUrl.hasQuery ||
          baseUrl.hasFragment) {
        _invalid();
      }
      final repository = WorkflowRepository(
        owner: _identifier(repo['owner']),
        name: _identifier(repo['name']),
        githubBaseUrl: baseUrl,
      );
      final jobId = _text(data['jobId']);
      final runId = _text(data['runId']);
      final runNumber = _positiveInt(data['runNumber']);
      final checkoutSha = _sha(data['checkoutSha']);
      for (final entry in {
        'OPENCI_BUILD_JOB_ID': jobId,
        'OPENCI_RUN_ID': runId,
        'OPENCI_RUN_NUMBER': '$runNumber',
      }.entries) {
        final value = environment[entry.key];
        if (value != null && value != entry.value) _invalid();
      }
      return switch (data['event']) {
        'push' => PushContext(
          repository: repository,
          jobId: jobId,
          runId: runId,
          runNumber: runNumber,
          branch: _text(data['branch']),
          commitSha: _pushSha(data['commitSha'], checkoutSha),
          checkoutSha: checkoutSha,
        ),
        'pull_request' => PullRequestContext(
          repository: repository,
          jobId: jobId,
          runId: runId,
          runNumber: runNumber,
          number: _positiveInt(data['number']),
          headBranch: _text(data['headBranch']),
          baseBranch: _text(data['baseBranch']),
          headSha: _sha(data['headSha']),
          baseSha: _sha(data['baseSha']),
          checkoutSha: checkoutSha,
        ),
        _ => _invalid(),
      };
    } on FormatException {
      _invalid();
    } on TypeError {
      _invalid();
    }
  }
}

/// A local invocation without an OpenCI job. It is neither a push nor a PR.
final class LocalContext extends WorkflowContext {
  const LocalContext();
}

/// Metadata shared by CI executions, including GitHub Enterprise executions.
sealed class CIContext extends WorkflowContext {
  const CIContext({
    required this.repository,
    required this.jobId,
    required this.runId,
    required this.runNumber,
    required this.checkoutSha,
  });

  final WorkflowRepository repository;
  final String jobId;
  final String runId;
  final int runNumber;

  /// The exact commit checked out in this run; a verified merge SHA for PRs.
  final String checkoutSha;
}

/// A push execution pinned to the commit saved when the job was created.
final class PushContext extends CIContext {
  const PushContext({
    required super.repository,
    required super.jobId,
    required super.runId,
    required super.runNumber,
    required super.checkoutSha,
    required this.branch,
    required this.commitSha,
  });

  /// The saved push target: branch name, or `refs/tags/<name>` for tag pushes.
  final String branch;
  final String commitSha;
}

/// A PR execution whose head and base match the verified test merge commit.
final class PullRequestContext extends CIContext {
  const PullRequestContext({
    required super.repository,
    required super.jobId,
    required super.runId,
    required super.runNumber,
    required super.checkoutSha,
    required this.number,
    required this.headBranch,
    required this.baseBranch,
    required this.headSha,
    required this.baseSha,
  });

  final int number;
  final String headBranch;
  final String baseBranch;
  final String headSha;

  /// The base parent of [checkoutSha], which may be newer than the webhook.
  final String baseSha;
}

@immutable
final class WorkflowRepository {
  const WorkflowRepository({
    required this.owner,
    required this.name,
    required this.githubBaseUrl,
  });

  final String owner;
  final String name;
  final Uri githubBaseUrl;
}

Never _invalid() => throw StateError(
  'OPENCI_CONTEXT is invalid or unsupported. Update the OpenCI executor and SDK.',
);

String _text(Object? value) {
  if (value is! String ||
      value.isEmpty ||
      value.trim() != value ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
    _invalid();
  }
  return value;
}

String _identifier(Object? value) {
  final text = _text(value);
  if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(text)) _invalid();
  return text;
}

int _positiveInt(Object? value) {
  if (value is! int || value <= 0 || value > 9007199254740991) _invalid();
  return value;
}

String _sha(Object? value) {
  final text = _text(value);
  if (!RegExp(r'^(?:[a-fA-F0-9]{40}|[a-fA-F0-9]{64})$').hasMatch(text) ||
      RegExp(r'^0+$').hasMatch(text)) {
    _invalid();
  }
  return text.toLowerCase();
}

String _pushSha(Object? value, String checkoutSha) {
  final sha = _sha(value);
  if (sha != checkoutSha) _invalid();
  return sha;
}
