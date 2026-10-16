import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

enum GitHubConnectionFailure {
  reauthorizationRequired,
  permissionsRequired,
  unavailable,
}

class GitHubConnectionException extends HttpException {
  const GitHubConnectionException(super.message, {required this.failure});

  factory GitHubConnectionException.fromResponse(
    http.Response response, {
    required String message,
  }) {
    final failure = switch (response.statusCode) {
      HttpStatus.unauthorized =>
        GitHubConnectionFailure.reauthorizationRequired,
      HttpStatus.forbidden when _isRateLimited(response) =>
        GitHubConnectionFailure.unavailable,
      HttpStatus.forbidden ||
      HttpStatus.notFound => GitHubConnectionFailure.permissionsRequired,
      _ => GitHubConnectionFailure.unavailable,
    };
    // Keep only our fixed message and category, never the upstream body or URL.
    return GitHubConnectionException(message, failure: failure);
  }

  final GitHubConnectionFailure failure;
}

bool _isRateLimited(http.Response response) {
  if (response.headers['x-ratelimit-remaining'] == '0' ||
      response.headers.containsKey('retry-after')) {
    return true;
  }
  // Secondary rate limits can return 403 without either header.
  try {
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['message'] is! String) {
      return false;
    }
    final message = (body['message'] as String).toLowerCase();
    return message.contains('rate limit') ||
        message.contains('abuse detection');
  } on FormatException {
    return false;
  }
}
