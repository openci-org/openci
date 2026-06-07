import 'dart:async';
import 'dart:io';

import 'transfer_progress.dart';

/// Downloads a file from the given [uri] to [savePath] with progress notifications.
/// Supports parallel connections and resuming by downloading to temporary chunk files
/// and merging them at the end. This prevents concurrent disk I/O bottlenecks.
Future<void> downloadFile({
  required Uri uri,
  required String savePath,
  String? accessToken,
  int concurrency = 4,
  bool force = false,
  void Function(TransferProgress progress)? onProgress,
}) async {
  final file = File(savePath);
  final parentDir = file.parent;
  if (!parentDir.existsSync()) {
    parentDir.createSync(recursive: true);
  }

  // HTTP client for HEAD request
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..autoUncompress = false;

  final headReq = await client.headUrl(uri);
  if (accessToken != null) {
    headReq.headers.add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
  }
  final headResp = await headReq.close();

  if (headResp.statusCode != HttpStatus.ok) {
    client.close();
    throw HttpException(
        'Failed to fetch file metadata: HTTP ${headResp.statusCode}');
  }

  final totalLength = headResp.contentLength;
  final acceptRanges = headResp.headers.value(HttpHeaders.acceptRangesHeader);
  client.close();

  // If already completed, skip
  if (!force && totalLength > 0 && file.existsSync()) {
    if (file.lengthSync() == totalLength) {
      throw StateError('The file is already fully downloaded.');
    }
  }

  // Fallback to single-connection if range or length not supported
  if (totalLength <= 0 || acceptRanges != 'bytes' || concurrency <= 1) {
    return downloadFileFallback(
        uri: uri,
        savePath: savePath,
        accessToken: accessToken,
        force: force,
        onProgress: onProgress);
  }

  // Divide the file into chunks
  final chunkSize = (totalLength / concurrency).ceil();
  final futures = <Future<void>>[];
  final activeClients = <HttpClient>[];
  final chunkFiles = <int, File>{};
  final chunkDownloadedBytes = List<int>.filled(concurrency, 0);

  // Initialize chunk files and check resume state
  for (int i = 0; i < concurrency; i++) {
    final chunkFile = File('$savePath.chunk$i');
    chunkFiles[i] = chunkFile;

    if (!force && chunkFile.existsSync()) {
      chunkDownloadedBytes[i] = chunkFile.lengthSync();
    } else {
      if (chunkFile.existsSync()) {
        chunkFile.deleteSync();
      }
      chunkDownloadedBytes[i] = 0;
    }
  }

  final stopwatch = Stopwatch()..start();
  int lastTime = stopwatch.elapsedMilliseconds;
  int lastDownloaded = chunkDownloadedBytes.reduce((a, b) => a + b);
  double speedMb = 0.0;
  Duration? remaining;

  int lastActivityTime = DateTime.now().millisecondsSinceEpoch;

  void triggerProgress() {
    final overallDownloaded = chunkDownloadedBytes.reduce((a, b) => a + b);
    lastActivityTime = DateTime.now().millisecondsSinceEpoch;

    if (onProgress != null && totalLength > 0) {
      final now = stopwatch.elapsedMilliseconds;
      if (now - lastTime >= 500) {
        final diff = overallDownloaded - lastDownloaded;
        final sec = (now - lastTime) / 1000.0;
        final speedBytesPerSec = diff / sec;
        speedMb = speedBytesPerSec / (1024.0 * 1024.0);

        final remainingBytes = totalLength - overallDownloaded;
        final etaSeconds = speedBytesPerSec > 0
            ? (remainingBytes / speedBytesPerSec).round()
            : 0;
        remaining = etaSeconds > 0 ? Duration(seconds: etaSeconds) : null;

        lastDownloaded = overallDownloaded;
        lastTime = now;
      }

      onProgress(TransferProgress(
        downloaded: overallDownloaded,
        total: totalLength,
        speedMb: speedMb,
        elapsed: stopwatch.elapsed,
        remaining: remaining,
      ));
    }
  }

  // Watchdog to prevent silent hangs (30s timeout)
  final watchdogTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastActivityTime > 30 * 1000) {
      for (final client in activeClients) {
        try {
          client.close(force: true);
        } catch (_) {}
      }
    }
  });

  try {
    for (int i = 0; i < concurrency; i++) {
      final start = i * chunkSize;
      int end = start + chunkSize - 1;
      if (end >= totalLength) {
        end = totalLength - 1;
      }

      final downloaded = chunkDownloadedBytes[i];
      if (downloaded >= (end - start + 1)) {
        continue; // This chunk is already fully downloaded
      }

      final chunkFuture = () async {
        final chunkClient = HttpClient()
          ..connectionTimeout = const Duration(seconds: 15)
          ..autoUncompress = false;

        activeClients.add(chunkClient);

        try {
          final request = await chunkClient.getUrl(uri);
          if (accessToken != null) {
            request.headers
                .add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
          }

          int requestStart = start + downloaded;
          request.headers
              .add(HttpHeaders.rangeHeader, 'bytes=$requestStart-$end');
          final response = await request.close();

          if (response.statusCode != HttpStatus.partialContent) {
            throw HttpException(
                'Parallel connection $i failed: HTTP ${response.statusCode} (Expected 206 Partial Content)');
          }

          final chunkFile = chunkFiles[i]!;
          final mode = downloaded > 0 ? FileMode.append : FileMode.write;
          final outputSink = chunkFile.openWrite(mode: mode);

          try {
            final stream = response.timeout(
              const Duration(seconds: 30),
              onTimeout: (sink) {
                sink.addError(TimeoutException(
                    'Response timed out while waiting for data on connection $i'));
                sink.close();
              },
            );

            await stream.forEach((data) {
              outputSink.add(data);
              chunkDownloadedBytes[i] += data.length;
              triggerProgress();
            });
          } finally {
            await outputSink.close();
          }
        } finally {
          chunkClient.close();
          activeClients.remove(chunkClient);
        }
      }();

      futures.add(chunkFuture);
    }

    await Future.wait(futures);
    watchdogTimer.cancel();

    // 2. Merge chunk files sequentially into the final file
    if (onProgress != null) {
      print('\nAll chunks downloaded. Merging files...');
    }

    final outputSink = file.openWrite(mode: FileMode.write);
    try {
      for (int i = 0; i < concurrency; i++) {
        final chunkFile = chunkFiles[i]!;
        if (chunkFile.existsSync()) {
          final stream = chunkFile.openRead();
          await stream.forEach((data) {
            outputSink.add(data);
          });
        }
      }
    } finally {
      await outputSink.close();
    }

    // Clean up chunk files after successful merge
    for (int i = 0; i < concurrency; i++) {
      final chunkFile = chunkFiles[i]!;
      if (chunkFile.existsSync()) {
        try {
          chunkFile.deleteSync();
        } catch (_) {}
      }
    }
  } catch (e) {
    watchdogTimer.cancel();
    rethrow;
  }
}

Future<void> downloadFileFallback({
  required Uri uri,
  required String savePath,
  String? accessToken,
  bool force = false,
  void Function(TransferProgress progress)? onProgress,
}) async {
  final file = File(savePath);
  final parentDir = file.parent;
  if (!parentDir.existsSync()) {
    parentDir.createSync(recursive: true);
  }

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..autoUncompress = false;
  final request = await client.getUrl(uri);
  if (accessToken != null) {
    request.headers.add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
  }
  final response = await request.close();

  if (response.statusCode != HttpStatus.ok) {
    client.close();
    throw HttpException(
        'Failed to download file: HTTP status ${response.statusCode}');
  }

  final contentLength = response.contentLength;

  // Prevent duplicate downloading if the file is already completed
  if (!force && contentLength > 0 && file.existsSync()) {
    final metadataFile = File('$savePath.download');
    if (!metadataFile.existsSync() && file.lengthSync() == contentLength) {
      client.close();
      throw StateError('The file is already fully downloaded.');
    }
  }

  int downloadedBytes = 0;

  final stopwatch = Stopwatch()..start();
  int lastTime = stopwatch.elapsedMilliseconds;
  int lastDownloaded = 0;
  double speedMb = 0.0;
  Duration? remaining;

  final outputSink = file.openWrite(mode: FileMode.write);
  try {
    final stream = response.timeout(
      const Duration(seconds: 30),
      onTimeout: (sink) {
        sink.addError(
            TimeoutException('Response timed out while waiting for data'));
        sink.close();
      },
    );
    await stream.forEach((chunk) {
      outputSink.add(chunk);
      downloadedBytes += chunk.length;
      if (onProgress != null && contentLength > 0) {
        final now = stopwatch.elapsedMilliseconds;
        if (now - lastTime >= 500) {
          final diff = downloadedBytes - lastDownloaded;
          final sec = (now - lastTime) / 1000.0;
          final speedBytesPerSec = diff / sec;
          speedMb = speedBytesPerSec / (1024.0 * 1024.0);

          final remainingBytes = contentLength - downloadedBytes;
          final etaSeconds = speedBytesPerSec > 0
              ? (remainingBytes / speedBytesPerSec).round()
              : 0;
          remaining = etaSeconds > 0 ? Duration(seconds: etaSeconds) : null;

          lastDownloaded = downloadedBytes;
          lastTime = now;
        }

        onProgress(TransferProgress(
          downloaded: downloadedBytes,
          total: contentLength,
          speedMb: speedMb,
          elapsed: stopwatch.elapsed,
          remaining: remaining,
        ));
      }
    });
  } finally {
    await outputSink.close();
    client.close();
  }
}
