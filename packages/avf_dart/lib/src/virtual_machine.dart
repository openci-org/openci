import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'avf_boot.dart';

class VirtualMachine {
  final Process _process;
  final String name;

  VirtualMachine._(this._process, this.name);

  /// Default directory where Virtual Machines are stored.
  /// Standard path on macOS: `~/Library/Application Support/avf_dart/vms`
  static String get defaultVmsDir {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;
    if (Platform.isMacOS) {
      return '$home/Library/Application Support/avf_dart/vms';
    }
    return '$home/.local/share/avf_dart/vms';
  }

  /// Launches the macOS virtualization helper for the VM with the given [name].
  ///
  /// Under the hood, this resolves the VM directory, reads the machine metadata,
  /// and executes the helper binary.
  /// If [showLogs] is true, VM status updates and output logs will be printed to stdout.
  static Future<VirtualMachine> boot({
    required String name,
    String? customVmsDir,
    bool showLogs = true,
  }) async {
    if (showLogs) {
      print('Booting macOS VM "$name"...');
    }

    final vmsDir = customVmsDir ?? defaultVmsDir;
    final vmDir = '$vmsDir/$name';
    final Process process;
    try {
      process = await AppleVirtualization.bootFromDirectory(vmDir);
    } catch (e) {
      if (showLogs) {
        print('Failed to boot VM: $e');
      }
      rethrow;
    }

    if (showLogs) {
      process.stdout.transform(utf8.decoder).listen(stdout.write);
      process.stderr.transform(utf8.decoder).listen(stderr.write);

      process.exitCode.then((code) {
        print('\nVM "$name" exited with code $code');
      });
    }

    return VirtualMachine._(process, name);
  }

  /// Stops the VM process gracefully (sends SIGTERM).
  Future<void> stop() async {
    _process.kill(ProcessSignal.sigterm);
    await _process.exitCode;
  }

  /// Returns the future that completes when the VM process terminates.
  Future<int> get exitCode => _process.exitCode;

  /// Starts a new macOS VM installation using the provided IPSW image file.
  ///
  /// This creates the installation directory under [customVmsDir] (or [defaultVmsDir]),
  /// allocates a blank disk image, and runs the macOS installer.
  /// The progress update (0.0 to 1.0) is notified via the [onProgress] callback.
  static Future<void> install({
    required String name,
    required String ipswPath,
    String? customVmsDir,
    void Function(double progress)? onProgress,
  }) async {
    final vmsDir = customVmsDir ?? defaultVmsDir;
    final vmDir = '$vmsDir/$name';

    final targetDir = Directory(vmDir);
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final diskImgPath = '$vmDir/disk.img';
    final nvramPath = '$vmDir/nvram.bin';
    final configJsonPath = '$vmDir/config.json';

    final process = await AppleVirtualization.install(
      ipswPath: ipswPath,
      diskImgPath: diskImgPath,
      nvramPath: nvramPath,
      configJsonPath: configJsonPath,
    );

    // Parse progress from standard output: "Progress: XX.XX%"
    final progressRegExp = RegExp(r'Progress:\s+(\d+\.\d+)%');

    final stdoutDone = process.stdout.transform(utf8.decoder).transform(const LineSplitter()).forEach((line) {
      final match = progressRegExp.firstMatch(line);
      if (match != null && onProgress != null) {
        final progressVal = double.tryParse(match.group(1) ?? '');
        if (progressVal != null) {
          onProgress(progressVal / 100.0);
        }
      } else {
        print(line);
      }
    });

    final stderrDone = process.stderr.transform(utf8.decoder).listen(stderr.write).asFuture();

    final exitCode = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);

    if (exitCode != 0) {
      throw StateError('macOS installation failed with exit code $exitCode');
    }
  }

  /// Clones the VM assets from [sourceName] to [targetName].
  ///
  /// It clones the config.json, disk.img, and nvram.bin from the existing VM directory
  /// under [customVmsDir] (or [defaultVmsDir]).
  /// If [showLogs] is true, status updates will be printed.
  static Future<void> clone({
    required String sourceName,
    required String targetName,
    String? customVmsDir,
    bool showLogs = true,
  }) async {
    if (showLogs) {
      print('Cloning macOS VM "$sourceName" to "$targetName"...');
    }

    try {
      final vmsDir = customVmsDir ?? defaultVmsDir;
      final sourceDir = '$vmsDir/$sourceName';
      final targetDir = '$vmsDir/$targetName';

      final srcDir = Directory(sourceDir);
      if (!srcDir.existsSync()) {
        throw FileSystemException('Source directory does not exist', sourceDir);
      }

      final target = Directory(targetDir);
      if (!target.existsSync()) {
        await target.create(recursive: true);
      }

      final configFile = File('$sourceDir/config.json');
      final diskFile = File('$sourceDir/disk.img');
      final nvramFile = File('$sourceDir/nvram.bin');

      if (!configFile.existsSync()) {
        throw FileSystemException('config.json not found in source directory', configFile.path);
      }
      if (!diskFile.existsSync()) {
        throw FileSystemException('disk.img not found in source directory', diskFile.path);
      }
      if (!nvramFile.existsSync()) {
        throw FileSystemException('nvram.bin not found in source directory', nvramFile.path);
      }

      await configFile.copy('$targetDir/config.json');
      await diskFile.copy('$targetDir/disk.img');
      await nvramFile.copy('$targetDir/nvram.bin');
    } catch (e) {
      if (showLogs) {
        print('Failed to clone VM assets: $e');
      }
      rethrow;
    }
  }

  /// Deletes the VM directory with the given [name] under [customVmsDir] (or [defaultVmsDir]).
  ///
  /// If [showLogs] is true, status updates will be printed.
  static Future<void> delete(
    String name, {
    String? customVmsDir,
    bool showLogs = true,
  }) async {
    if (showLogs) {
      print('Cleaning up VM "$name"...');
    }

    try {
      final vmsDir = customVmsDir ?? defaultVmsDir;
      final vmDir = Directory('$vmsDir/$name');
      if (vmDir.existsSync()) {
        await vmDir.delete(recursive: true);
      }
      if (showLogs) {
        print('Cleanup complete.');
      }
    } catch (e) {
      if (showLogs) {
        print('Cleanup failed: $e');
      }
      rethrow;
    }
  }

  /// Downloads a file from the given [uri] to [savePath] with progress notifications.
  /// Supports parallel connections and resuming from partial download state.
  ///
  /// The progress (0.0 to 1.0) is notified via the [onProgress] callback.
  static Future<void> downloadIpsw({
    required Uri uri,
    required String savePath,
    int concurrency = 8,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    final client = HttpClient();

    // 1. Fetch file size and Range support verification via HEAD request
    final headReq = await client.headUrl(uri);
    final headResp = await headReq.close();

    if (headResp.statusCode != HttpStatus.ok) {
      throw HttpException('Failed to fetch file metadata: HTTP ${headResp.statusCode}');
    }

    final totalLength = headResp.contentLength;
    final acceptRanges = headResp.headers.value(HttpHeaders.acceptRangesHeader);

    // If Range is not supported or total length is unknown, fallback to single-connection download
    if (totalLength <= 0 || acceptRanges != 'bytes') {
      client.close();
      return _downloadIpswFallback(uri: uri, savePath: savePath, onProgress: onProgress);
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
          metadata = _createNewMetadata(totalLength, concurrency);
        }
      } catch (_) {
        metadata = _createNewMetadata(totalLength, concurrency);
      }
    } else {
      metadata = _createNewMetadata(totalLength, concurrency);
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

    final chunks = (metadata['chunks'] as List).map((c) => Map<String, dynamic>.from(c)).toList();

    // Calculate total already downloaded bytes
    int overallDownloaded = chunks.fold(0, (sum, c) => sum + (c['downloaded'] as int));

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

    void updateProgress(int chunkIndex, int bytesReceived) {
      overallDownloaded += bytesReceived;
      chunks[chunkIndex]['downloaded'] = (chunks[chunkIndex]['downloaded'] as int) + bytesReceived;

      if (onProgress != null && totalLength > 0) {
        onProgress(overallDownloaded, totalLength);
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
        
        int requestStart = start + downloaded;
        request.headers.add(HttpHeaders.rangeHeader, 'bytes=$requestStart-$end');
        final response = await request.close();

        if (response.statusCode != HttpStatus.partialContent && response.statusCode != HttpStatus.ok) {
          throw HttpException('Parallel connection $i failed: HTTP ${response.statusCode}');
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

  static Map<String, dynamic> _createNewMetadata(int totalLength, int concurrency) {
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
  static final _asyncLocks = <Object, Future<void>>{};
  static Future<T> synchronizedAsync<T>(Object lock, Future<T> Function() fn) async {
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

  static Future<void> _downloadIpswFallback({
    required Uri uri,
    required String savePath,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    final file = File(savePath);
    final parentDir = file.parent;
    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }

    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Failed to download file: HTTP status ${response.statusCode}');
    }

    final contentLength = response.contentLength;
    int downloadedBytes = 0;

    final outputSink = file.openWrite(mode: FileMode.write);
    try {
      await response.forEach((chunk) {
        outputSink.add(chunk);
        downloadedBytes += chunk.length;
        if (onProgress != null && contentLength > 0) {
          onProgress(downloadedBytes, contentLength);
        }
      });
    } finally {
      await outputSink.close();
      client.close();
    }
  }
}
