import 'dart:convert';

import 'package:dashboard/team/github_connection_context.dart';
import 'package:web/web.dart' as web;

const _storageKey = 'github_connection_context_v1';

void saveGitHubConnectionContext(GitHubConnectionContext context) {
  web.window.sessionStorage.setItem(_storageKey, jsonEncode(context.toJson()));
}

void clearGitHubConnectionContext() {
  web.window.sessionStorage.removeItem(_storageKey);
}

GitHubConnectionContext? takeGitHubConnectionContext() {
  try {
    final storage = web.window.sessionStorage;
    final value = storage.getItem(_storageKey);
    storage.removeItem(_storageKey);
    if (value == null) return null;
    return GitHubConnectionContext.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  } catch (_) {
    // Treat unavailable storage or malformed context as an interrupted attempt.
    return null;
  }
}
