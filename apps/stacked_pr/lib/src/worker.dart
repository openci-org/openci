import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'git.dart';
import 'github.dart';
import 'models.dart';
import 'service.dart';
import 'store.dart';

class Worker {
  Worker(this.store, this.service);
  final Store store;
  final Service service;
  Timer? _timer;
  Future<void>? _running;
  var _stopping = false;
  var _lastPoll = 0;

  void start() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      unawaited(tick());
    });
    unawaited(tick());
  }

  Future<void> tick() async {
    if (_stopping || _running != null) return;
    _running = _process();
    try {
      await _running;
    } catch (_) {
      stderr.writeln('Worker or SQLite failure');
    } finally {
      _running = null;
    }
  }

  Future<void> _process() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPoll > 300000) {
      _lastPoll = now;
      for (final target in store.targets()) {
        store.enqueue(
          'poll:${target.installation}:${target.repo.id}:${now ~/ 300000}',
          'reconcile',
          {
            'installation': {'id': target.installation},
            'repository': target.repo.toJson(),
          },
        );
      }
      store.prune();
    }
    final job = store.next();
    if (job == null) return;
    try {
      await service.handle(job);
      store.done(job.id);
    } catch (error) {
      final message = error is ApiException || error is GitException || error is RetryException
          ? error.toString()
          : 'Job failed; check connectivity, App credentials, permissions, and disk space';
      store.fail(job, message);
      stderr.writeln(
        jsonEncode({
          'event': 'job_failed',
          'delivery': job.id,
          'attempt': job.attempts,
          'message': message,
        }),
      );
    }
  }

  Future<void> stop() async {
    _stopping = true;
    _timer?.cancel();
    await _running;
  }
}
