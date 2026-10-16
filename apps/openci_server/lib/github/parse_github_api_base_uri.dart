Uri parseGitHubApiBaseUri(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw StateError(
      'GITHUB_API_BASE_URL must be an HTTP(S) URL without credentials, query, '
      'or fragment.',
    );
  }

  final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
  return uri.replace(path: path);
}
