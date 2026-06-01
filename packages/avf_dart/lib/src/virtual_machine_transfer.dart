import 'dart:convert';
import 'dart:io';

import 'file_transfer.dart';
import 'transfer_progress.dart';
import 'virtual_machine.dart';

class VirtualMachineTransfer {
  /// Downloads a file from the given [uri] to [savePath] with progress notifications.
  static Future<void> downloadIpsw({
    required Uri uri,
    required String savePath,
    int concurrency = 8,
    bool force = false,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    await downloadFile(
      uri: uri,
      savePath: savePath,
      concurrency: concurrency,
      force: force,
      onProgress: onProgress,
    );
  }

  /// Compresses the VM directory and uploads it to Firebase Storage (Google Cloud Storage) via Pure Dart.
  static Future<void> push({
    required String name,
    required String bucket,
    required String accessToken,
    String? customVmsDir,
    void Function(String log)? onLog,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    final vmsDir = customVmsDir ?? VirtualMachine.defaultVmsDir;
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
  static Future<void> pull({
    required String name,
    required String bucket,
    required String accessToken,
    String? customVmsDir,
    void Function(String log)? onLog,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    final vmsDir = customVmsDir ?? VirtualMachine.defaultVmsDir;
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

    await downloadFile(
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
