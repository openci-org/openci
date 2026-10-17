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
