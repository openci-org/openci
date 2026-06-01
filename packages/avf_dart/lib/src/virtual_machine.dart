import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

import 'avf_boot.dart';
import 'file_transfer.dart';
import 'local_vm.dart';
import 'transfer_progress.dart';

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
        final ipMatch = RegExp(r'VM started successfully! IP:\s+([0-9.]+)')
            .firstMatch(line);
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

      if (Platform.isMacOS) {
        // Use copy-on-write clone on macOS for instant copy and sparse file support
        final result = await Process.run('cp', [
          '-c',
          configFile.path,
          '$targetDir/config.json',
        ]);
        if (result.exitCode != 0) {
          throw StateError('Failed to clone config.json: ${result.stderr}');
        }

        final diskResult = await Process.run('cp', [
          '-c',
          diskFile.path,
          '$targetDir/disk.img',
        ]);
        if (diskResult.exitCode != 0) {
          throw StateError('Failed to clone disk.img: ${diskResult.stderr}');
        }

        final nvramResult = await Process.run('cp', [
          '-c',
          nvramFile.path,
          '$targetDir/nvram.bin',
        ]);
        if (nvramResult.exitCode != 0) {
          throw StateError('Failed to clone nvram.bin: ${nvramResult.stderr}');
        }
      } else {
        await configFile.copy('$targetDir/config.json');
        await diskFile.copy('$targetDir/disk.img');
        await nvramFile.copy('$targetDir/nvram.bin');
      }
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
    await downloadFile(
      uri: uri,
      savePath: savePath,
      concurrency: concurrency,
      force: force,
      onProgress: onProgress,
    );
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
          int diskSizeUsed = diskSize;

          if (Platform.isMacOS) {
            try {
              final statResult =
                  await Process.run('stat', ['-f', '%b', diskFile.path]);
              if (statResult.exitCode == 0) {
                final blocks =
                    int.tryParse(statResult.stdout.toString().trim());
                if (blocks != null) {
                  diskSizeUsed = blocks * 512;
                }
              }
            } catch (_) {
              // Fallback to logical size on error
            }
          }

          final stat = entity.statSync();
          list.add(LocalVM(
            name: name,
            path: entity.path,
            diskSizeBytes: diskSize,
            diskSizeUsedBytes: diskSizeUsed,
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

  /// Executes a [command] on the guest VM via SSH, streaming standard output
  /// and standard error to the optional [onStdout] and [onStderr] callbacks.
  ///
  /// Returns the exit code of the command when it finishes.
  Future<int> executeStream(
    String command, {
    String username = 'admin',
    String? password,
    String? privateKeyPath,
    int port = 22,
    void Function(String data)? onStdout,
    void Function(String data)? onStderr,
  }) async {
    final ip = ipAddress;
    if (ip == null) {
      throw StateError(
          'Cannot execute SSH command because the VM does not have an allocated IP address. Ensure the VM is booted successfully.');
    }

    final List<SSHKeyPair>? keyPairs;
    if (privateKeyPath != null) {
      final keyFile = File(privateKeyPath);
      if (!keyFile.existsSync()) {
        throw FileSystemException('Private key file not found', privateKeyPath);
      }
      final pem = await keyFile.readAsString();
      keyPairs = SSHKeyPair.fromPem(pem);
    } else {
      keyPairs = null;
    }

    final socket = await SSHSocket.connect(ip, port);
    final client = SSHClient(
      socket,
      username: username,
      onPasswordRequest: password != null ? () => password : null,
      identities: keyPairs,
    );

    try {
      final session = await client.execute(command);

      StreamSubscription<String>? stdoutSub;
      StreamSubscription<String>? stderrSub;

      if (onStdout != null) {
        stdoutSub = session.stdout
            .cast<List<int>>()
            .transform(utf8.decoder)
            .listen(onStdout);
      }
      if (onStderr != null) {
        stderrSub = session.stderr
            .cast<List<int>>()
            .transform(utf8.decoder)
            .listen(onStderr);
      }

      await session.done;

      await stdoutSub?.cancel();
      await stderrSub?.cancel();

      return session.exitCode ?? -1;
    } finally {
      client.close();
      await client.done;
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
