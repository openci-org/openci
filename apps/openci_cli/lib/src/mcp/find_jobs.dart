import 'build_api.dart';

const _resultLimit = 20;

class _JobSearch {
  const _JobSearch(
    this.origin,
    this.owner,
    this.repo,
    this.pullRequest,
    this.commit,
  );

  final String origin;
  final String owner;
  final String repo;
  final int? pullRequest;
  final String? commit;

  factory _JobSearch.parse(Map<String, Object?> args) {
    final prUrl = args['pr_url'] as String?;
    final repo = args['repository'] as String?;
    final commit = (args['commit_sha'] as String?)?.toLowerCase();
    if ((prUrl == null) == (repo == null) ||
        (prUrl == null && commit == null)) {
      throw const BuildReadException(
        'Pass pr_url (optionally with commit_sha), or repository and commit_sha.',
      );
    }
    final raw = prUrl ?? repo!;
    final shortName = RegExp(r'^[\w.-]+/[\w.-]+$');
    final uri = Uri.tryParse(
      prUrl == null && shortName.hasMatch(raw)
          ? 'https://github.com/$raw'
          : raw,
    );
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const BuildReadException(
        'Use an HTTPS GitHub repository or pull request URL.',
      );
    }
    final parts = uri.pathSegments.toList();
    if (parts.isNotEmpty && parts.last.isEmpty) parts.removeLast();
    var repoIndex = parts.length - 1;
    int? number;
    if (prUrl != null) {
      final pull = parts.lastIndexOf('pull');
      if (pull >= 2 &&
          pull + 1 < parts.length &&
          RegExp(r'^[1-9][0-9]{0,15}$').hasMatch(parts[pull + 1])) {
        number = int.parse(parts[pull + 1]);
      }
      if (number == null) {
        throw const BuildReadException(
          'Expected a URL ending in /owner/repo/pull/NUMBER or its PR tab.',
        );
      }
      repoIndex = pull - 1;
    }
    if (repoIndex < 1 ||
        !shortName.hasMatch('${parts[repoIndex - 1]}/${parts[repoIndex]}')) {
      throw const BuildReadException('Invalid GitHub owner or repository.');
    }
    final origin = Uri(
      scheme: 'https',
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      pathSegments: parts.take(repoIndex - 1),
    ).toString().replaceFirst(RegExp(r'/$'), '');
    return _JobSearch(
      origin,
      parts[repoIndex - 1],
      parts[repoIndex].replaceFirst(RegExp(r'\.git$'), ''),
      number,
      commit,
    );
  }

  bool matches(Map job) {
    final base = (job['githubBaseUrl'] as String?) ?? '';
    final origin = base.isEmpty
        ? 'https://github.com'
        : base.replaceFirst(RegExp(r'/$'), '');
    return origin.toLowerCase() == this.origin.toLowerCase() &&
        (job['owner'] as String).toLowerCase() == owner.toLowerCase() &&
        (job['repo'] as String).toLowerCase() == repo.toLowerCase() &&
        (pullRequest == null ||
            job['pullRequestNumber'].toString() == '$pullRequest') &&
        (commit == null || job['commitSha'] == commit);
  }
}

Future<Map<String, Object?>> findJobs(
  BuildApi api,
  Map<String, Object?> args,
) async {
  final search = _JobSearch.parse(args);
  final cursor = (args['cursor'] as String?)?.split(':');
  final offset = cursor == null ? 0 : int.parse(cursor.last);
  if (cursor?.first == 'team') return _searchTeamPage(api, search, offset);

  try {
    final data = await api.query('builds', 'FindBuildJobs', {
      'teamId': api.profile.teamId,
      'githubBaseUrl': search.origin,
      'owner': search.owner,
      'repo': search.repo,
      'pullRequestNumber': ?search.pullRequest?.toString(),
      'commitSha': ?search.commit,
      'offset': offset,
      'limit': _resultLimit + 1,
    });
    final matches = (data['jobs'] as List).cast<Map>();
    return {
      'jobs': matches.take(_resultLimit).map(_jobSummary).toList(),
      if (matches.length > _resultLimit)
        'next_cursor': 'jobs:${offset + _resultLimit}',
    };
  } on BuildQueryUnavailable {
    if (cursor != null) rethrow;
    return _searchTeamPage(api, search, 0);
  }
}

Map<String, Object?> _jobSummary(Map job) => {
  'job_id': job['job_id'],
  'workflow': job['workflow'],
  'status': job['status'],
  'commit_sha': job['commit_sha'],
  'matrix_label': ?job['matrix_label'],
  'latest_run_id': ?job['latest_run_id'],
  if (job['retry_count'] case final int count when count >= 0)
    'retry_count': count,
  if (job['recent_runs'] case final List runs when runs.length > 1)
    'recent_runs': runs,
};

/// Older deployments only offer the paginated team list. Preserve the first
/// unread offset even if one team page contains more matches than we return.
Future<Map<String, Object?>> _searchTeamPage(
  BuildApi api,
  _JobSearch search,
  int offset,
) async {
  const pageSize = 200;
  final data = await api.query('builds', 'GetBuildJobs', {
    'teamId': api.profile.teamId,
    'offset': offset,
    'limit': pageSize,
  });
  final page = (data['buildJobs'] as List).cast<Map>();
  final jobs = <Map<String, Object?>>[];
  var consumed = 0;
  for (final job in page) {
    consumed++;
    if (job['teamId'] != api.profile.teamId || !search.matches(job)) continue;
    jobs.add(
      _jobSummary({
        'job_id': job['id'],
        'workflow': job['workflowName'],
        'status': job['status'],
        'commit_sha': job['commitSha'],
        'matrix_label': job['matrixLabel'],
        'latest_run_id': job['latestRunId'],
        'retry_count': job['retryCount'],
      }),
    );
    if (jobs.length == _resultLimit) break;
  }
  return {
    'jobs': jobs,
    if (consumed < page.length || page.length == pageSize)
      'next_cursor': 'team:${offset + consumed}',
  };
}
