import 'dart:async';

import 'package:genuine_ci/src/loki/log_buffer.dart';
import 'package:test/test.dart';

void main() {
  test('sends full batches and flushes the remainder on close', () async {
    final batches = <List<List<String>>>[];
    final buffer = LokiLogBuffer(
      sendBatch: (values) async => batches.add(values),
      onError: (error) => fail('Unexpected upload error: $error'),
      flushInterval: const Duration(days: 1),
    );
    addTearDown(buffer.close);

    final before = DateTime.now().microsecondsSinceEpoch * 1000;
    await buffer.add('line-0');
    final after = DateTime.now().microsecondsSinceEpoch * 1000;
    for (var i = 1; i < 99; i++) {
      await buffer.add('line-$i');
    }
    expect(batches, isEmpty);

    await buffer.add('line-99');
    expect(batches, hasLength(1));
    expect(
      batches.single.map((value) => value[1]),
      List.generate(100, (i) => 'line-$i'),
    );
    expect(int.parse(batches.single.first[0]), inInclusiveRange(before, after));

    await buffer.add('last');
    await buffer.close();
    expect(batches, hasLength(2));
    expect(batches.last.single[1], 'last');
  });

  test('flushes sparse output while the stream remains open', () async {
    final received = Completer<List<List<String>>>();
    final buffer = LokiLogBuffer(
      sendBatch: (values) async => received.complete(values),
      onError: (error) => fail('Unexpected upload error: $error'),
      flushInterval: const Duration(milliseconds: 5),
    );
    addTearDown(buffer.close);

    await buffer.add('still running');

    final values = await received.future;
    expect(values.single[1], 'still running');
    await buffer.close();
  });

  test('bounds UTF-8 batch bytes and preserves an oversized line', () async {
    final batches = <List<List<String>>>[];
    final buffer = LokiLogBuffer(
      sendBatch: (values) async => batches.add(values),
      onError: (error) => fail('Unexpected upload error: $error'),
      maxBytes: 6,
      flushInterval: const Duration(days: 1),
    );
    addTearDown(buffer.close);

    await buffer.add('あい');
    expect(batches, hasLength(1));
    await buffer.add('あ');
    await buffer.add('🙂');
    expect(batches, hasLength(2));
    await buffer.add('あいう');
    await buffer.close();

    expect(batches.map((batch) => batch.single[1]), ['あい', 'あ', '🙂', 'あいう']);
  });

  for (final fails in [false, true]) {
    test('bounds pending logs during a slow upload (fails: $fails)', () async {
      final firstStarted = Completer<void>();
      final secondStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      final releaseSecond = Completer<void>();
      final batches = <List<List<String>>>[];
      final errors = <Object>[];
      var activeUploads = 0;
      var maximumActiveUploads = 0;

      final buffer = LokiLogBuffer(
        sendBatch: (values) async {
          batches.add(values);
          activeUploads++;
          if (activeUploads > maximumActiveUploads) {
            maximumActiveUploads = activeUploads;
          }
          try {
            if (batches.length == 1) {
              firstStarted.complete();
              await releaseFirst.future;
              if (fails) throw StateError('Upload failed');
            } else {
              secondStarted.complete();
              await releaseSecond.future;
            }
          } finally {
            activeUploads--;
          }
        },
        onError: errors.add,
        maxLines: 2,
        flushInterval: const Duration(milliseconds: 5),
      );
      addTearDown(() async {
        if (!releaseFirst.isCompleted) releaseFirst.complete();
        if (!releaseSecond.isCompleted) releaseSecond.complete();
        await buffer.close();
      });

      await buffer.add('first');
      await firstStarted.future;
      await buffer.add('second');
      var fullBatchFinished = false;
      final fullBatch = buffer.add('third').then((_) {
        fullBatchFinished = true;
      });
      final closing = buffer.close();

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fullBatchFinished, isFalse);
      expect(batches, hasLength(1));
      releaseFirst.complete();

      if (!fails) {
        await secondStarted.future;
        expect(fullBatchFinished, isFalse);
        expect(batches.last.map((value) => value[1]), ['second', 'third']);
        releaseSecond.complete();
      }
      await Future.wait([fullBatch, closing]);

      expect(fullBatchFinished, isTrue);
      expect(maximumActiveUploads, 1);
      expect(batches, hasLength(fails ? 1 : 2));
      expect(errors, hasLength(fails ? 1 : 0));
    });
  }

  test('handles a timer-triggered upload error and stops forwarding', () async {
    var uploads = 0;
    final reportedError = Completer<Object>();
    final buffer = LokiLogBuffer(
      sendBatch: (_) async {
        uploads++;
        throw StateError('Loki unavailable');
      },
      onError: reportedError.complete,
      flushInterval: const Duration(milliseconds: 5),
    );
    addTearDown(buffer.close);

    await buffer.add('first');
    expect(await reportedError.future, isA<StateError>());
    await buffer.add('after failure');
    await buffer.close();

    expect(uploads, 1);
  });
}
