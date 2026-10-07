import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../asc/find_cached_asc_executable.dart';
import '../../asc/install_asc.dart';
import '../../i18n/i18n.dart';

class SetupAscKeysCommand extends Command<int> {
  @override
  final String name = 'asc-keys';

  @override
  String get description => t.setup.ascKeys.description;

  final Logger _logger;
  final Future<File?> Function() _findCachedExecutable;
  final Future<File> Function() _installExecutable;

  SetupAscKeysCommand({
    required Logger logger,
    @visibleForTesting
    Future<File?> Function() findCachedExecutable = findCachedAscExecutable,
    @visibleForTesting Future<File> Function() installExecutable = installAsc,
  }) : _logger = logger,
       _findCachedExecutable = findCachedExecutable,
       _installExecutable = installExecutable;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.setup.ascKeys.noArguments);
    }

    try {
      final executable = await _findCachedExecutable();
      if (executable == null) {
        _logger.stdout(t.setup.ascKeys.installing(version: ascVersion));
        final installed = await _installExecutable();
        _logger.stdout(
          t.setup.ascKeys.installed(version: ascVersion, path: installed.path),
        );
      } else {
        _logger.stdout(
          t.setup.ascKeys.cacheFound(
            version: ascVersion,
            path: executable.path,
          ),
        );
      }
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
    } on FileSystemException {
      _logger.stderr(t.setup.ascKeys.cacheFailed);
      return 1;
    }

    _logger.stderr(t.setup.ascKeys.notImplemented);
    return 1;
  }
}
