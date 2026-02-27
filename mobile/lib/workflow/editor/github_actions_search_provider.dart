import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_actions_search_provider.g.dart';

class GitHubAction {
  GitHubAction({
    required this.fullName,
    required this.description,
    required this.stars,
    required this.defaultTag,
  });

  final String fullName;
  final String description;
  final int stars;
  final String defaultTag;

  String get usesString => '$fullName@$defaultTag';
}

@riverpod
Future<List<GitHubAction>> searchGitHubActions(
  Ref ref, {
  required String query,
}) async {
  if (query.trim().isEmpty) {
    return _popularActions;
  }

  final client = HttpClient();
  try {
    final encodedQuery = Uri.encodeComponent('$query topic:github-actions');
    final uri = Uri.parse(
      'https://api.github.com/search/repositories?q=$encodedQuery&sort=stars&order=desc&per_page=15',
    );

    final request = await client.getUrl(uri);
    request.headers.set('Accept', 'application/vnd.github+json');
    request.headers.set('User-Agent', 'OpenCI-Mobile');

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      return _popularActions
          .where(
            (a) => a.fullName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>? ?? [];

    return items.map((item) {
      final repo = item as Map<String, dynamic>;
      final fullName = repo['full_name'] as String? ?? '';
      final description = repo['description'] as String? ?? '';
      final stars = repo['stargazers_count'] as int? ?? 0;
      final defaultBranch = repo['default_branch'] as String? ?? 'main';

      String tag = 'v1';
      if (fullName.startsWith('actions/')) {
        tag = 'v4';
      } else if (fullName.contains('flutter')) {
        tag = 'v2';
      } else {
        tag = defaultBranch;
      }

      return GitHubAction(
        fullName: fullName,
        description: description,
        stars: stars,
        defaultTag: tag,
      );
    }).toList();
  } catch (_) {
    return _popularActions
        .where(
          (a) => a.fullName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  } finally {
    client.close();
  }
}

final _popularActions = [
  GitHubAction(
    fullName: 'actions/checkout',
    description: 'Check out a Git repository',
    stars: 6000,
    defaultTag: 'v4',
  ),
  GitHubAction(
    fullName: 'actions/setup-node',
    description: 'Set up Node.js environment',
    stars: 4000,
    defaultTag: 'v4',
  ),
  GitHubAction(
    fullName: 'actions/setup-java',
    description: 'Set up Java JDK',
    stars: 1800,
    defaultTag: 'v4',
  ),
  GitHubAction(
    fullName: 'actions/setup-python',
    description: 'Set up Python environment',
    stars: 2000,
    defaultTag: 'v5',
  ),
  GitHubAction(
    fullName: 'actions/upload-artifact',
    description: 'Upload a build artifact',
    stars: 3200,
    defaultTag: 'v4',
  ),
  GitHubAction(
    fullName: 'actions/download-artifact',
    description: 'Download a build artifact',
    stars: 1600,
    defaultTag: 'v4',
  ),
  GitHubAction(
    fullName: 'actions/cache',
    description: 'Cache dependencies and build outputs',
    stars: 5000,
    defaultTag: 'v4',
  ),
  GitHubAction(
    fullName: 'subosito/flutter-action',
    description: 'Set up Flutter SDK',
    stars: 2100,
    defaultTag: 'v2',
  ),
  GitHubAction(
    fullName: 'ruby/setup-ruby',
    description: 'Set up Ruby, JRuby, or TruffleRuby',
    stars: 900,
    defaultTag: 'v1',
  ),
  GitHubAction(
    fullName: 'aws-actions/configure-aws-credentials',
    description: 'Configure AWS credential and region environment variables',
    stars: 2200,
    defaultTag: 'v4',
  ),
  GitHubAction(
    fullName: 'google-github-actions/setup-gcloud',
    description: 'Set up and configure gcloud CLI',
    stars: 400,
    defaultTag: 'v2',
  ),
  GitHubAction(
    fullName: 'docker/build-push-action',
    description: 'Build and push Docker images',
    stars: 4500,
    defaultTag: 'v6',
  ),
  GitHubAction(
    fullName: 'codecov/codecov-action',
    description: 'Upload coverage to Codecov',
    stars: 1500,
    defaultTag: 'v5',
  ),
  GitHubAction(
    fullName: 'softprops/action-gh-release',
    description: 'Create GitHub Releases',
    stars: 4000,
    defaultTag: 'v2',
  ),
  GitHubAction(
    fullName: 'peaceiris/actions-gh-pages',
    description: 'Deploy to GitHub Pages',
    stars: 4800,
    defaultTag: 'v4',
  ),
];
