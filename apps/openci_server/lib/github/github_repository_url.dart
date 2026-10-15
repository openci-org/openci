import 'dart:io';

String githubRepositoryBaseUrl({Map<String, String>? environment}) {
  final value = (environment ?? Platform.environment)['GITHUB_API_BASE_URL'];
  final apiUrl = Uri.tryParse(value?.trim() ?? '');
  if (apiUrl == null ||
      (apiUrl.scheme != 'https' && apiUrl.scheme != 'http') ||
      apiUrl.host.isEmpty ||
      apiUrl.userInfo.isNotEmpty ||
      apiUrl.hasQuery ||
      apiUrl.hasFragment) {
    throw StateError(
      'GITHUB_API_BASE_URL must be an HTTP(S) URL without credentials, query, '
      'or fragment.',
    );
  }

  final path = apiUrl.path.replaceFirst(RegExp(r'/+$'), '');
  if (apiUrl.origin == 'https://api.github.com' && path.isEmpty) {
    return 'https://github.com';
  }

  // GHES serves REST APIs under /api/v3 and repositories at the instance root.
  return apiUrl
      .replace(path: path.replaceFirst(RegExp(r'/api/v3$'), ''))
      .toString();
}
