import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'avf_boot.dart';

class VirtualMachine {
  final Process _process;
  final String name;
  final String? ipAddress;

  VirtualMachine._(this._process, this.name, this.ipAddress);

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

    final bootCompleter = Completer<void>();
    final errorSb = StringBuffer();
    String? resolvedIp;

    // Monitor stdout line by line
    final stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (showLogs) {
        print(line);
      }
      if (!bootCompleter.isCompleted) {
        final ipMatch = RegExp(r'VM started successfully! IP:\s+([0-9.]+)').firstMatch(line);
        if (ipMatch != null) {
          resolvedIp = ipMatch.group(1);
          bootCompleter.complete();
        } else if (line.contains('VM started successfully!')) {
          bootCompleter.complete();
        } else if (line.contains('Error:')) {
          bootCompleter.completeError(StateError(line));
        }
      }
    });

    // Monitor stderr
    final stderrSubscription =
        process.stderr.transform(utf8.decoder).listen((data) {
      if (showLogs) {
        stderr.write(data);
      }
      errorSb.write(data);
      if (!bootCompleter.isCompleted && errorSb.toString().contains('Error:')) {
        final lines = errorSb.toString().split('\n');
        final errorLine = lines.firstWhere((l) => l.contains('Error:'),
            orElse: () => errorSb.toString());
        bootCompleter.completeError(StateError(errorLine.trim()));
      }
    });

    // Monitor process exit in case it terminates before boot success
    process.exitCode.then((code) {
      if (showLogs) {
        print('\nVM "$name" exited with code $code');
      }
      if (!bootCompleter.isCompleted) {
        final errMessage = errorSb.isNotEmpty
            ? errorSb.toString().trim()
            : 'VM process exited prematurely with code $code';
        bootCompleter.completeError(StateError(errMessage));
      }
    });

    try {
      await bootCompleter.future;
    } catch (e) {
      await stdoutSubscription.cancel();
      await stderrSubscription.cancel();
      process.kill(ProcessSignal.sigterm);
      rethrow;
    }

    return VirtualMachine._(process, name, resolvedIp);
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

    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
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

    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .listen(stderr.write)
        .asFuture<void>();

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
        throw FileSystemException(
            'config.json not found in source directory', configFile.path);
      }
      if (!diskFile.existsSync()) {
        throw FileSystemException(
            'disk.img not found in source directory', diskFile.path);
      }
      if (!nvramFile.existsSync()) {
        throw FileSystemException(
            'nvram.bin not found in source directory', nvramFile.path);
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
    bool force = false,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    await _downloadFile(
      uri: uri,
      savePath: savePath,
      concurrency: concurrency,
      force: force,
      onProgress: onProgress,
    );
  }

  static Future<void> _downloadFile({
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
      headReq.headers
          .add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
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
      return _downloadFileFallback(
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
        request.headers
            .add(HttpHeaders.rangeHeader, 'bytes=$requestStart-$end');
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

  static Map<String, dynamic> _createNewMetadata(
      int totalLength, int concurrency) {
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
  static Future<T> synchronizedAsync<T>(
      Object lock, Future<T> Function() fn) async {
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

  static Future<void> _downloadFileFallback({
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
      request.headers
          .add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
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

  /// Lists all local Virtual Machines available in the VM directory.
  static Future<List<LocalVM>> list({String? customVmsDir}) async {
    final vmsDir = Directory(customVmsDir ?? defaultVmsDir);
    if (!vmsDir.existsSync()) {
      return [];
    }

    final list = <LocalVM>[];
    await for (final entity in vmsDir.list()) {
      if (entity is Directory) {
        final name = entity.path.split('/').last;
        final configFile = File('${entity.path}/config.json');
        final diskFile = File('${entity.path}/disk.img');
        final nvramFile = File('${entity.path}/nvram.bin');

        // A directory is considered a valid VM if all core assets are present
        if (configFile.existsSync() &&
            diskFile.existsSync() &&
            nvramFile.existsSync()) {
          final diskSize = diskFile.lengthSync();
          final stat = entity.statSync();
          list.add(LocalVM(
            name: name,
            path: entity.path,
            diskSizeBytes: diskSize,
            created: stat.changed,
          ));
        }
      }
    }
    // Sort alphabetically by name
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Compresses the VM directory and uploads it to Firebase Storage (Google Cloud Storage) via Pure Dart.
  ///
  /// Uses macOS standard `tar -czf` and Google Cloud Storage Resumable Upload protocol.
  static Future<void> push({
    required String name,
    required String bucket,
    required String accessToken,
    String? customVmsDir,
    void Function(String log)? onLog,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    final vmsDir = customVmsDir ?? defaultVmsDir;
    final vmDir = '$vmsDir/$name';

    if (!Directory(vmDir).existsSync()) {
      throw FileSystemException('VM directory does not exist', vmDir);
    }

    final tempDir = Directory.systemTemp.path;
    final tempArchivePath = '$tempDir/$name.tar.gz';
    final metadataFile = File('$tempArchivePath.upload');

    // Helper to safely log messages
    void log(String msg) {
      if (onLog != null) {
        onLog(msg);
      } else {
        print(msg);
      }
    }

    // 1. Archiving VM folder (if temp archive doesn't exist yet)
    final archiveFile = File(tempArchivePath);
    if (!archiveFile.existsSync()) {
      log('Archiving and compressing VM "$name" (maintaining sparse files)...');
      final compressCmd =
          'tar -czf ${escapeShellArg(tempArchivePath)} -C ${escapeShellArg(vmDir)} .';
      final compressResult = await Process.run('/bin/sh', ['-c', compressCmd]);

      if (compressResult.exitCode != 0) {
        throw ProcessException(
            'tar',
            [],
            'Compression failed: ${compressResult.stderr}',
            compressResult.exitCode);
      }
    } else {
      log('Reusing existing archive for upload resume...');
    }

    final totalLength = archiveFile.lengthSync();
    String? sessionUrl;
    int uploadedBytes = 0;

    final client = HttpClient();

    // 2. Resolve Resumable Upload session URL
    if (metadataFile.existsSync()) {
      try {
        final metaContent = metadataFile.readAsStringSync();
        final meta = jsonDecode(metaContent) as Map<String, dynamic>;
        if (meta['totalLength'] == totalLength && meta['sessionUrl'] != null) {
          sessionUrl = meta['sessionUrl'] as String;
          log('Resuming upload session...');

          // Query current upload status from GCS
          final queryReq = await client.putUrl(Uri.parse(sessionUrl));
          queryReq.headers.add(HttpHeaders.contentLengthHeader, '0');
          queryReq.headers.add('Content-Range', 'bytes */$totalLength');

          final queryResp = await queryReq.close();
          if (queryResp.statusCode == 308) {
            final rangeHeader = queryResp.headers.value('range');
            if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
              final parts = rangeHeader.substring(6).split('-');
              if (parts.length > 1) {
                uploadedBytes = (int.tryParse(parts[1]) ?? -1) + 1;
                log('Server already received $uploadedBytes bytes. Resuming...');
              }
            }
          } else if (queryResp.statusCode == 200 ||
              queryResp.statusCode == 201) {
            log('Upload already complete according to GCS server.');
            uploadedBytes = totalLength;
          } else {
            // Session expired (404/410), restart upload
            sessionUrl = null;
          }
        }
      } catch (_) {
        sessionUrl = null;
      }
    }

    if (sessionUrl == null) {
      log('Initiating resumable upload session on GCS...');
      final initUri = Uri.parse(
          'https://storage.googleapis.com/upload/storage/v1/b/$bucket/o?uploadType=resumable&name=$name.tar.gz');
      final initReq = await client.postUrl(initUri);
      initReq.headers
          .add(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      initReq.headers.add('X-Upload-Content-Type', 'application/octet-stream');
      initReq.headers.add(
          HttpHeaders.contentTypeHeader, 'application/json; charset=UTF-8');

      final initResp = await initReq.close();
      if (initResp.statusCode != 200) {
        client.close();
        throw HttpException(
            'Failed to initiate upload session: HTTP ${initResp.statusCode}');
      }

      sessionUrl = initResp.headers.value(HttpHeaders.locationHeader);
      if (sessionUrl == null) {
        client.close();
        throw StateError(
            'GCS did not return a session URL (Location header missing).');
      }

      // Write session details to metadata
      metadataFile.writeAsStringSync(jsonEncode({
        'sessionUrl': sessionUrl,
        'totalLength': totalLength,
      }));
    }

    // 3. Perform chunk uploads
    try {
      final raf = await archiveFile.open(mode: FileMode.read);

      const chunkSize =
          2 * 1024 * 1024; // 2MB chunks (must be a multiple of 256KB)

      final stopwatch = Stopwatch()..start();
      int lastTime = stopwatch.elapsedMilliseconds;
      int lastUploaded = uploadedBytes;
      double speedMb = 0.0;
      Duration? remaining;

      void triggerProgress(int currentUploaded) {
        if (onProgress != null) {
          final now = stopwatch.elapsedMilliseconds;
          if (now - lastTime >= 500) {
            final diff = currentUploaded - lastUploaded;
            final sec = (now - lastTime) / 1000.0;
            final speedBytesPerSec = diff / sec;
            speedMb = speedBytesPerSec / (1024.0 * 1024.0);

            final remainingBytes = totalLength - currentUploaded;
            final etaSeconds = speedBytesPerSec > 0
                ? (remainingBytes / speedBytesPerSec).round()
                : 0;
            remaining = etaSeconds > 0 ? Duration(seconds: etaSeconds) : null;

            lastUploaded = currentUploaded;
            lastTime = now;
          }

          onProgress(TransferProgress(
            downloaded: currentUploaded,
            total: totalLength,
            speedMb: speedMb,
            elapsed: stopwatch.elapsed,
            remaining: remaining,
          ));
        }
      }

      while (uploadedBytes < totalLength) {
        await raf.setPosition(uploadedBytes);
        int currentChunkSize = chunkSize;
        if (uploadedBytes + currentChunkSize > totalLength) {
          currentChunkSize = totalLength - uploadedBytes;
        }

        final data = await raf.read(currentChunkSize);
        final endRange = uploadedBytes + data.length - 1;

        final putReq = await client.putUrl(Uri.parse(sessionUrl));
        putReq.headers
            .add(HttpHeaders.contentLengthHeader, data.length.toString());
        putReq.headers.add(
            'Content-Range', 'bytes $uploadedBytes-$endRange/$totalLength');
        putReq.add(data);

        final putResp = await putReq.close();

        if (putResp.statusCode != 308 &&
            putResp.statusCode != 200 &&
            putResp.statusCode != 201) {
          await raf.close();
          throw HttpException(
              'Upload chunk failed: HTTP ${putResp.statusCode}');
        }

        uploadedBytes += data.length;
        triggerProgress(uploadedBytes);
      }

      await raf.close();
      log('Success: VM "$name" pushed successfully.');

      // 4. Cleanup temporary archive and metadata on success
      if (archiveFile.existsSync()) {
        archiveFile.deleteSync();
      }
      if (metadataFile.existsSync()) {
        metadataFile.deleteSync();
      }
    } finally {
      client.close();
    }
  }

  /// Downloads a VM archive from Firebase Storage and decompresses it locally via Pure Dart.
  ///
  /// Uses HTTP Range requests for resume capability and macOS standard `tar -xzf`.
  static Future<void> pull({
    required String name,
    required String bucket,
    required String accessToken,
    String? customVmsDir,
    void Function(String log)? onLog,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    final vmsDir = customVmsDir ?? defaultVmsDir;
    final targetVmDir = '$vmsDir/$name';

    final tempDir = Directory.systemTemp.path;
    final tempArchivePath = '$tempDir/$name.tar.gz';

    // Helper to safely log messages
    void log(String msg) {
      if (onLog != null) {
        onLog(msg);
      } else {
        print(msg);
      }
    }

    log('Downloading VM "$name" from Firebase Storage (maintaining sparse files)...');

    final downloadUri = Uri.parse(
        'https://storage.googleapis.com/storage/v1/b/$bucket/o/$name.tar.gz?alt=media');

    await _downloadFile(
      uri: downloadUri,
      savePath: tempArchivePath,
      accessToken: accessToken,
      onProgress: onProgress,
    );

    log('Decompressing and extracting VM archive...');

    final targetDir = Directory(targetVmDir);
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    // Command: tar -xzf <tempArchivePath> -C <targetVmDir>
    final decompressCmd =
        'tar -xzf ${escapeShellArg(tempArchivePath)} -C ${escapeShellArg(targetVmDir)}';
    final decompressResult =
        await Process.run('/bin/sh', ['-c', decompressCmd]);

    // Cleanup temporary archive file on extraction success
    final tempFile = File(tempArchivePath);
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
    }

    if (decompressResult.exitCode != 0) {
      throw ProcessException(
          'tar',
          [],
          'Decompression failed: ${decompressResult.stderr}',
          decompressResult.exitCode);
    }

    log('Success: VM "$name" pulled and extracted to $targetVmDir.');
  }

  /// Safely escapes shell arguments by wrapping them in single quotes.
  static String escapeShellArg(String arg) {
    if (Platform.isWindows) {
      return '"${arg.replaceAll('"', '\\"')}"';
    }
    return "'${arg.replaceAll("'", "'\\''")}'";
  }
}

class LocalVM {
  final String name;
  final String path;
  final int diskSizeBytes;
  final DateTime created;

  LocalVM({
    required this.name,
    required this.path,
    required this.diskSizeBytes,
    required this.created,
  });
}

class TransferProgress {
  final int downloaded;
  final int total;
  final double speedMb;
  final Duration elapsed;
  final Duration? remaining;
  final DateTime timestamp;

  TransferProgress({
    required this.downloaded,
    required this.total,
    required this.speedMb,
    required this.elapsed,
    this.remaining,
  }) : timestamp = DateTime.now();

  double get percent => total > 0 ? (downloaded / total) * 100.0 : 0.0;

  String get speedStr =>
      speedMb >= 0 ? '${speedMb.toStringAsFixed(1)} MB/s' : '-- MB/s';

  String get elapsedStr {
    final elapsedMinutes = elapsed.inMinutes;
    final elapsedSeconds = elapsed.inSeconds % 60;
    return '${elapsedMinutes}m ${elapsedSeconds}s';
  }

  DateTime? get eta => remaining != null ? timestamp.add(remaining!) : null;

  String get etaStr {
    if (remaining == null || remaining!.inSeconds <= 0) {
      return '--';
    }
    final remainingSec = remaining!.inSeconds;
    if (remainingSec < 60) {
      return '${remainingSec}s';
    } else if (remainingSec < 3600) {
      return '${remainingSec ~/ 60}m ${remainingSec % 60}s';
    } else {
      final hours = remainingSec ~/ 3600;
      final minutes = (remainingSec % 3600) ~/ 60;
      final seconds = remainingSec % 60;
      return '${hours}h ${minutes}m ${seconds}s';
    }
  }

  @override
  String toString() {
    final percentStr = percent.toStringAsFixed(2);
    return '$percentStr% ($speedStr) [Elapsed: $elapsedStr, ETA: $etaStr]';
  }
}
