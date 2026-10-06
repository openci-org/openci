import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../extensions/file_extensions.dart';
import 'asc_license.dart';
import 'asc_release.dart';

enum AscCliFailure {
  unsupportedPlatform,
  cache,
  download,
  checksum,
  permission,
}

class AscCliException implements Exception {
  const AscCliException(this.failure);

  final AscCliFailure failure;
}

class AscCli {
  AscCli({
    @visibleForTesting Directory? cacheDirectory,
    @visibleForTesting Abi? abi,
    @visibleForTesting AscRelease? release,
    @visibleForTesting http.Client Function()? clientFactory,
    @visibleForTesting
    Future<ProcessResult> Function(String executable, List<String> arguments)?
    processRunner,
    @visibleForTesting Duration downloadTimeout = const Duration(seconds: 30),
  }) : _cacheDirectory = cacheDirectory,
       _abi = abi,
       _release = release,
       _clientFactory = clientFactory ?? http.Client.new,
       _processRunner = processRunner ?? Process.run,
       _downloadTimeout = downloadTimeout;

  final Directory? _cacheDirectory;
  final Abi? _abi;
  final AscRelease? _release;
  final http.Client Function() _clientFactory;
  final Future<ProcessResult> Function(String, List<String>) _processRunner;
  final Duration _downloadTimeout;

  Future<File> ensureAvailable() async {
    final release = _release ?? AscRelease.forAbi(_abi ?? Abi.current());
    if (release == null) {
      throw const AscCliException(AscCliFailure.unsupportedPlatform);
    }

    try {
      final cache =
          _cacheDirectory ?? Directory(BaseDirectories('genuineci').cacheHome);
      final directory = Directory(
        p.join(cache.path, 'tools', 'asc', AscRelease.version, release.target),
      ).absolute;
      await directory.create(recursive: true);
      final executable = File(p.join(directory.path, release.executableName));
      final type = await FileSystemEntity.type(
        executable.path,
        followLinks: false,
      );
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.file) {
        throw const AscCliException(AscCliFailure.cache);
      }

      if (type == FileSystemEntityType.file &&
          await _matchesChecksum(executable, release)) {
        await _makeExecutable(executable, release);
        await _writeLicense(directory);
        return executable;
      }

      // A separate file prevents an interrupted or concurrent download from
      // exposing a partial executable at the stable cache path.
      final temporary = await directory.createTemp('.download-');
      try {
        final downloaded = File(p.join(temporary.path, release.executableName));
        await _download(release.downloadUrl, downloaded);
        if (!await _matchesChecksum(downloaded, release)) {
          throw const AscCliException(AscCliFailure.checksum);
        }
        await _makeExecutable(downloaded, release);
        await _writeLicense(directory);
        await downloaded.rename(executable.path);
        return executable;
      } finally {
        await temporary.delete(recursive: true);
      }
    } on AscCliException {
      rethrow;
    } on FileSystemException {
      throw const AscCliException(AscCliFailure.cache);
    } on EnvironmentNotFoundException {
      throw const AscCliException(AscCliFailure.cache);
    }
  }

  Future<bool> _matchesChecksum(File file, AscRelease release) async =>
      (await sha256.bind(file.openRead()).first).toString() == release.checksum;

  Future<void> _download(Uri url, File destination) async {
    // This client has no GenuineCI bearer token or Apple credentials.
    final client = _clientFactory();
    try {
      final response = await client
          .send(
            http.Request('GET', url)
              ..headers['Accept'] = 'application/octet-stream',
          )
          .timeout(_downloadTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw const AscCliException(AscCliFailure.download);
      }
      final file = await destination.open(mode: FileMode.write);
      try {
        // Writing chunks directly preserves network errors; IOSink.addStream
        // can wrap upstream failures as FileSystemException.
        await for (final chunk in response.stream.timeout(_downloadTimeout)) {
          await file.writeFrom(chunk);
        }
      } finally {
        await file.close();
      }
    } on TimeoutException {
      throw const AscCliException(AscCliFailure.download);
    } on http.ClientException {
      throw const AscCliException(AscCliFailure.download);
    } on IOException catch (error) {
      if (error is FileSystemException) rethrow;
      throw const AscCliException(AscCliFailure.download);
    } finally {
      client.close();
    }
  }

  Future<void> _makeExecutable(File file, AscRelease release) async {
    if (release.isWindows) return;
    try {
      final result = await _processRunner('/bin/chmod', ['700', file.path]);
      if (result.exitCode != 0) {
        throw const AscCliException(AscCliFailure.permission);
      }
    } on ProcessException {
      throw const AscCliException(AscCliFailure.permission);
    }
  }

  Future<void> _writeLicense(Directory directory) =>
      File(p.join(directory.path, 'LICENSE')).writeAsStringAtomic(ascLicense);
}
