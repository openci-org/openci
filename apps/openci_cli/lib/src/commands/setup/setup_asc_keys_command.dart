import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../asc/asc_release.dart';
import '../../asc/find_cached_asc_executable.dart';
import '../../asc/install_asc.dart';
import '../../asc/verify_asc_executable.dart';
import '../../i18n/i18n.dart';
import 'read_apple_id.dart';

class SetupAscKeysCommand extends Command<int> {
  @override
  final String name = 'asc-keys';

  @override
  String get description => t.setup.ascKeys.description;

  final Logger _logger;
  final Future<File?> Function() _findCachedExecutable;
  final Future<File> Function() _installExecutable;
  final Future<void> Function(File) _verifyExecutable;
  final Future<String?> Function() _readAppleId;

  SetupAscKeysCommand({
    required Logger logger,
    @visibleForTesting
    Future<File?> Function() findCachedExecutable = findCachedAscExecutable,
    @visibleForTesting Future<File> Function() installExecutable = installAsc,
    @visibleForTesting
    Future<void> Function(File) verifyExecutable = verifyAscExecutable,
    @visibleForTesting
    Future<String?> Function() readAppleIdInput = readAppleId,
  }) : _logger = logger,
       _findCachedExecutable = findCachedExecutable,
       _installExecutable = installExecutable,
       _verifyExecutable = verifyExecutable,
       _readAppleId = readAppleIdInput;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.setup.ascKeys.noArguments);
    }

    try {
      var executable = await _findCachedExecutable();
      if (executable == null) {
        _logger.stdout(t.setup.ascKeys.installing(version: ascVersion));
        executable = await _installExecutable();
        _logger.stdout(
          t.setup.ascKeys.installed(version: ascVersion, path: executable.path),
        );
      } else {
        _logger.stdout(
          t.setup.ascKeys.cacheFound(
            version: ascVersion,
            path: executable.path,
          ),
        );
      }
      await _verifyExecutable(executable);
      _logger.stdout(t.setup.ascKeys.versionVerified(version: ascVersion));
    } on UnsupportedError {
      _logger.stderr(t.setup.ascKeys.unsupportedPlatform);
      return 1;
    } on AscInstallException catch (error) {
      _logger.stderr(switch (error.failure) {
        AscInstallFailure.download => t.setup.ascKeys.downloadFailed,
        AscInstallFailure.checksum => t.setup.ascKeys.checksumFailed,
        AscInstallFailure.permission => t.setup.ascKeys.permissionFailed,
      });
      return 1;
    } on AscVerificationException catch (error) {
      _logger.stderr(switch (error.failure) {
        AscVerificationFailure.checksum => t.setup.ascKeys.cachedChecksumFailed,
        AscVerificationFailure.execution => t.setup.ascKeys.executionFailed,
        AscVerificationFailure.timeout => t.setup.ascKeys.versionTimedOut,
        AscVerificationFailure.version => t.setup.ascKeys.versionMismatch(
          version: ascVersion,
        ),
      });
      return 1;
    } on FileSystemException {
      _logger.stderr(t.setup.ascKeys.cacheFailed);
      return 1;
    }

    try {
      final appleId = await _readAppleId();
      if (appleId == null) {
        _logger.stderr(t.setup.ascKeys.appleIdRequired);
        return 1;
      }
      _logger.stdout(t.setup.ascKeys.appleIdReceived);
    } on AppleIdInputException catch (error) {
      _logger.stderr(switch (error.failure) {
        AppleIdInputFailure.notInteractive => t.setup.ascKeys.terminalRequired,
        AppleIdInputFailure.read => t.setup.ascKeys.appleIdInputFailed,
      });
      return 1;
    }

    _logger.stderr(t.setup.ascKeys.notImplemented);
    return 1;
  }
}
