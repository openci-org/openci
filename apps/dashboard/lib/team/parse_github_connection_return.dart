import 'package:freezed_annotation/freezed_annotation.dart';

part 'parse_github_connection_return.freezed.dart';

enum GitHubConnectionReturnError {
  accessDenied,
  invalidCallback,
  invalidState,
  forbidden,
  connectionFailed,
  invalidResult,
}

@Freezed(copyWith: false, toStringOverride: false)
abstract class GitHubConnectionReturn with _$GitHubConnectionReturn {
  const factory GitHubConnectionReturn._({
    String? reference,
    GitHubConnectionReturnError? error,
  }) = _GitHubConnectionReturn;
}

GitHubConnectionReturn parseGitHubConnectionReturn(String fragment) {
  const invalid = GitHubConnectionReturn._(
    error: GitHubConnectionReturnError.invalidResult,
  );
  if (fragment.contains('&')) return invalid;

  try {
    final parameters = Uri.splitQueryString(fragment);
    if (parameters.length != 1) return invalid;

    final reference = parameters['reference'];
    if (reference != null) {
      if (reference.trim().isEmpty) return invalid;
      return GitHubConnectionReturn._(reference: reference);
    }

    final error = switch (parameters['error']) {
      'access_denied' => GitHubConnectionReturnError.accessDenied,
      'invalid_callback' => GitHubConnectionReturnError.invalidCallback,
      'invalid_state' => GitHubConnectionReturnError.invalidState,
      'forbidden' => GitHubConnectionReturnError.forbidden,
      'connection_failed' => GitHubConnectionReturnError.connectionFailed,
      _ => GitHubConnectionReturnError.invalidResult,
    };
    return GitHubConnectionReturn._(error: error);
  } on FormatException {
    return invalid;
  } on ArgumentError {
    return invalid;
  }
}
