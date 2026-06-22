import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/webhook_task_processor.dart';
import 'package:sentry/sentry.dart';

final webhookTaskController = StreamController<void>.broadcast();

class SimplePool {
  SimplePool(this.maxConcurrency);
  final int maxConcurrency;
  int _activeCount = 0;
  final List<Completer<void>> _waiting = [];

  Future<void> run(Future<void> Function() task) async {
    while (_activeCount >= maxConcurrency) {
      final completer = Completer<void>();
      _waiting.add(completer);
      await completer.future;
    }
    _activeCount++;
    try {
      await task();
    } finally {
      _activeCount--;
      if (_waiting.isNotEmpty) {
        final next = _waiting.removeAt(0);
        next.complete();
      }
    }
  }
}

final _pool = SimplePool(3); // Concurrency limit of 3 tasks

void startWebhookTaskWorker(AppDatabase db) {
  webhookTaskController.stream.listen((_) {
    _triggerWorker(db);
  });

  // Wait 500ms for global database instantiation and server booting to complete
  Future.delayed(const Duration(milliseconds: 500), () {
    _triggerWorker(db);
  });
}

void _triggerWorker(AppDatabase db) {
  _pool.run(() async {
    while (true) {
      final task = await db.webhookTaskDao.claimNextWebhookTask();
      if (task == null) break;

      try {
        await processWebhookTask(db, task);

        final completedTask = task.copyWith(
          status: 'completed',
          updatedAt: DateTime.now().toUtc(),
        );
        await db.webhookTaskDao.updateWebhookTask(completedTask);
      } catch (e, stack) {
        stderr.writeln('Webhook task processing failed: $e\n$stack');
        await Sentry.captureException(e, stackTrace: stack);

        final failedTask = task.copyWith(
          status: 'failed',
          retryCount: task.retryCount + 1,
          errorMessage: Value('$e\n$stack'),
          updatedAt: DateTime.now().toUtc(),
        );
        await db.webhookTaskDao.updateWebhookTask(failedTask);
      }
    }
  });
}
