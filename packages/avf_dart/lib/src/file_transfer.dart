import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'transfer_progress.dart';

/// Downloads a file from the given [uri] to [savePath] with progress notifications.
/// Supports parallel connections and resuming from partial download state.
Future<void> downloadFile({
  required Uri uri,
  required String savePath,
  String? accessToken,
  int concurrency = 8,
  bool force = false,
  void Function(TransferProgress progress)? onProgress,
}) async {
  final client = HttpClient();

  // 1. Fetch file size and Range support verification via HEAD request
  final headReq = await client.headUrl(uri);
  if (accessToken != null) {
    headReq.headers.add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
  }
  final headResp = await headReq.close();

  if (headResp.statusCode != HttpStatus.ok) {
    throw HttpException(
        'Failed to fetch file metadata: HTTP ${headResp.statusCode}');
  }

  final totalLength = headResp.contentLength;
  final acceptRanges = headResp.headers.value(HttpHeaders.acceptRangesHeader);

  // Prevent duplicate downloading if the file is already completed
  if (!force && totalLength > 0) {
    final file = File(savePath);
    final metadataFile = File('$savePath.download');
    if (file.existsSync() &&
        !metadataFile.existsSync() &&
        file.lengthSync() == totalLength) {
      client.close();
      throw StateError('The file is already fully downloaded.');
    }
  }

  // If Range is not supported or total length is unknown, fallback to single-connection download
  if (totalLength <= 0 || acceptRanges != 'bytes') {
    client.close();
    return downloadFileFallback(
        uri: uri,
        savePath: savePath,
        accessToken: accessToken,
        force: force,
        onProgress: onProgress);
  }
  client.close();

  final file = File(savePath);
  final metadataFile = File('$savePath.download');

  Map<String, dynamic> metadata;
  bool isResumed = false;

  // Check if metadata exists and is compatible
  if (metadataFile.existsSync() && file.existsSync()) {
    try {
      final content = metadataFile.readAsStringSync();
      metadata = jsonDecode(content) as Map<String, dynamic>;
      if (metadata['totalLength'] == totalLength &&
          metadata['concurrency'] == concurrency &&
          metadata['chunks'] != null) {
        isResumed = true;
      } else {
        metadata = createNewMetadata(totalLength, concurrency);
      }
    } catch (_) {
      metadata = createNewMetadata(totalLength, concurrency);
    }
  } else {
    metadata = createNewMetadata(totalLength, concurrency);
  }

  // Open file for shared random-access writing
  final raf = await file.open(mode: FileMode.write);
  if (!isResumed) {
    final parentDir = file.parent;
    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }
    await raf.truncate(totalLength);
  }

  final chunks = (metadata['chunks'] as List)
      .map((c) => Map<String, dynamic>.from(c as Map))
      .toList();

  // Calculate total already downloaded bytes
  int overallDownloaded =
      chunks.fold(0, (sum, c) => sum + (c['downloaded'] as int));

  // Throttle progress metadata saving
  int lastSavedTime = DateTime.now().millisecondsSinceEpoch;
  void saveProgress() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastSavedTime > 1000) {
      try {
        metadata['chunks'] = chunks;
        metadataFile.writeAsStringSync(jsonEncode(metadata));
      } catch (_) {}
      lastSavedTime = now;
    }
  }

  final stopwatch = Stopwatch()..start();
  int lastTime = stopwatch.elapsedMilliseconds;
  int lastDownloaded = overallDownloaded;
  double speedMb = 0.0;
  Duration? remaining;

  void updateProgress(int chunkIndex, int bytesReceived) {
    overallDownloaded += bytesReceived;
    chunks[chunkIndex]['downloaded'] =
        (chunks[chunkIndex]['downloaded'] as int) + bytesReceived;

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
    saveProgress();
  }

  final futures = <Future<void>>[];
  final rafLock = Object();

  for (int i = 0; i < concurrency; i++) {
    final chunk = chunks[i];
    final start = chunk['start'] as int;
    final end = chunk['end'] as int;
    final downloaded = chunk['downloaded'] as int;

    // Skip fully downloaded chunks
    if (downloaded >= (end - start + 1)) {
      continue;
    }

    final chunkFuture = () async {
      final chunkClient = HttpClient();
      final request = await chunkClient.getUrl(uri);
      if (accessToken != null) {
        request.headers
            .add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      }

      int requestStart = start + downloaded;
      request.headers.add(HttpHeaders.rangeHeader, 'bytes=$requestStart-$end');
      final response = await request.close();

      if (response.statusCode != HttpStatus.partialContent &&
          response.statusCode != HttpStatus.ok) {
        throw HttpException(
            'Parallel connection $i failed: HTTP ${response.statusCode}');
      }

      try {
        final buffer = BytesBuilder(copy: false);
        int bufferOffset = requestStart;
        const writeBufferSize = 2 * 1024 * 1024; // 2MB buffer

        Future<void> flushBuffer() async {
          if (buffer.isEmpty) return;
          final dataToWrite = buffer.takeBytes();
          final offset = bufferOffset;
          bufferOffset += dataToWrite.length;

          await synchronizedAsync(rafLock, () async {
            await raf.setPosition(offset);
            await raf.writeFrom(dataToWrite);
          });
        }

        await for (final data in response) {
          buffer.add(data);
          updateProgress(i, data.length);

          if (buffer.length >= writeBufferSize) {
            await flushBuffer();
          }
        }
        await flushBuffer();
      } finally {
        chunkClient.close();
      }
    }();

    futures.add(chunkFuture);
  }

  try {
    await Future.wait(futures);
  } finally {
    await raf.close();
  }

  // Save final progress state and clean up metadata file
  try {
    if (metadataFile.existsSync()) {
      metadataFile.deleteSync();
    }
  } catch (_) {}
}

Map<String, dynamic> createNewMetadata(int totalLength, int concurrency) {
  final chunkSize = (totalLength / concurrency).ceil();
  final chunks = <Map<String, dynamic>>[];

  for (int i = 0; i < concurrency; i++) {
    final start = i * chunkSize;
    int end = start + chunkSize - 1;
    if (end >= totalLength) {
      end = totalLength - 1;
    }
    chunks.add({
      'start': start,
      'end': end,
      'downloaded': 0,
    });
  }

  return {
    'totalLength': totalLength,
    'concurrency': concurrency,
    'chunks': chunks,
  };
}

// Simple asynchronous serialization helper
final _asyncLocks = <Object, Future<void>>{};
Future<T> synchronizedAsync<T>(Object lock, Future<T> Function() fn) async {
  final previous = _asyncLocks[lock];
  final completer = Completer<void>();
  _asyncLocks[lock] = completer.future;

  if (previous != null) {
    try {
      await previous;
    } catch (_) {}
  }
  try {
    return await fn();
  } finally {
    completer.complete();
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

  final client = HttpClient();
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
    await response.forEach((chunk) {
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
