import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'asc_license.dart';
import 'find_cached_asc_executable.dart';

// https://github.com/rorkai/App-Store-Connect-CLI/releases/download/5.11.0/asc_5.11.0_checksums.txt
const _ascChecksum =
    '180f77a17dd81a4392bd4a8055d5544918961a0c3ea9bc184a1b16b8aaf1695e';
final _ascDownloadUrl = Uri.https(
  'github.com',
  '/rorkai/App-Store-Connect-CLI/releases/download/'
      '$ascVersion/asc_${ascVersion}_macOS_arm64',
);

enum AscInstallFailure { download, checksum, permission }

class AscInstallException implements Exception {
  const AscInstallException(this.failure);

  final AscInstallFailure failure;
}

/// Installs a missing asc binary without running it.
Future<File> installAsc({
  @visibleForTesting Directory? cacheDirectory,
  @visibleForTesting Abi? abi,
  @visibleForTesting String expectedChecksum = _ascChecksum,
  @visibleForTesting http.Client Function() clientFactory = http.Client.new,
  @visibleForTesting
  Future<ProcessResult> Function(String, List<String>) processRunner =
      Process.run,
  @visibleForTesting Duration downloadTimeout = const Duration(seconds: 30),
}) async {
  final executable = ascCacheFile(cacheDirectory: cacheDirectory, abi: abi);
  final type = await FileSystemEntity.type(executable.path, followLinks: false);
  if (type == FileSystemEntityType.file) return executable;
  if (type != FileSystemEntityType.notFound) {
    throw FileSystemException(
      'The asc cache path is not a regular file.',
      executable.path,
    );
  }

  await executable.parent.create(recursive: true);
  // Stage on the same filesystem so the final rename publishes a complete file.
  final temporary = await executable.parent.createTemp('.download-');
  try {
    final downloaded = File(p.join(temporary.path, 'asc'));
    await _download(downloaded, clientFactory(), downloadTimeout);
    final checksum = (await sha256.bind(downloaded.openRead()).first)
        .toString();
    if (checksum != expectedChecksum) {
      throw const AscInstallException(AscInstallFailure.checksum);
    }

    try {
      final result = await processRunner('/bin/chmod', [
        '700',
        downloaded.path,
      ]);
      if (result.exitCode != 0) {
        throw const AscInstallException(AscInstallFailure.permission);
      }
    } on ProcessException {
      throw const AscInstallException(AscInstallFailure.permission);
    }

    final license = File(p.join(temporary.path, 'LICENSE'));
    await license.writeAsString(ascLicense);
    await license.rename(p.join(executable.parent.path, 'LICENSE'));
    await downloaded.rename(executable.path);
    return executable;
  } finally {
    await temporary.delete(recursive: true);
  }
}

Future<void> _download(
  File destination,
  http.Client client,
  Duration timeout,
) async {
  try {
    final response = await client
        .send(
          http.Request('GET', _ascDownloadUrl)
            ..headers['Accept'] = 'application/octet-stream',
        )
        .timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      throw const AscInstallException(AscInstallFailure.download);
    }
    final file = await destination.open(mode: FileMode.write);
    try {
      // Write chunks directly to distinguish network errors from disk errors.
      await for (final chunk in response.stream.timeout(timeout)) {
        await file.writeFrom(chunk);
      }
    } finally {
      await file.close();
    }
  } on TimeoutException {
    throw const AscInstallException(AscInstallFailure.download);
  } on http.ClientException {
    throw const AscInstallException(AscInstallFailure.download);
  } on IOException catch (error) {
    if (error is FileSystemException) rethrow;
    throw const AscInstallException(AscInstallFailure.download);
  } finally {
    client.close();
  }
}
