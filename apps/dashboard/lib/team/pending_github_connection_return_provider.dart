import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingGitHubConnectionReturnProvider =
    Provider<PendingGitHubConnectionReturn>(
      (ref) => PendingGitHubConnectionReturn(null),
    );

class PendingGitHubConnectionReturn {
  PendingGitHubConnectionReturn(this._value);

  GitHubConnectionReturn? _value;

  GitHubConnectionReturn? take() {
    final value = _value;
    _value = null;
    return value;
  }
}
