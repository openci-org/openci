import 'dart:async';
import 'dart:io';

import 'package:openci_server/database.dart';
import 'package:openci_server/github/delete_expired_github_connection_sessions.dart';

class GitHubConnectionSessionCleanup {
  GitHubConnectionSessionCleanup(this._db);

  final AppDatabase _db;
  Timer? _timer;
  Future<void>? _pending;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _run());
    _run();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _pending;
  }

  void _run() {
    if (_pending != null) return;
    _pending = _deleteExpiredSessions().whenComplete(() => _pending = null);
  }

  Future<void> _deleteExpiredSessions() async {
    try {
      await deleteExpiredGitHubConnectionSessions(db: _db);
    } catch (_) {
      stderr.writeln('Failed to clean up expired GitHub connection sessions');
    }
  }
}
