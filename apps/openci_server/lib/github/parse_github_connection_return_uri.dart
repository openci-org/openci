Uri parseGitHubConnectionReturnUri(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw StateError(
      'GITHUB_CONNECTION_RETURN_URL must be an absolute HTTP(S) URL without '
      'credentials, query, or fragment.',
    );
  }
  return uri;
}
