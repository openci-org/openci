import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../asc/find_cached_asc_executable.dart';
import '../../i18n/i18n.dart';

class SetupAscKeysCommand extends Command<int> {
  @override
  final String name = 'asc-keys';

  @override
  String get description => t.setup.ascKeys.description;

  final Logger _logger;
  final Future<File?> Function() _findCachedExecutable;

  SetupAscKeysCommand({
    required Logger logger,
    @visibleForTesting
    Future<File?> Function() findCachedExecutable = findCachedAscExecutable,
  }) : _logger = logger,
       _findCachedExecutable = findCachedExecutable;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.setup.ascKeys.noArguments);
    }

    final File? executable;
    try {
      executable = await _findCachedExecutable();
    } on UnsupportedError {
      _logger.stderr(t.setup.ascKeys.unsupportedPlatform);
      return 1;
    } on FileSystemException {
      _logger.stderr(t.setup.ascKeys.cacheCheckFailed);
      return 1;
    }
    if (executable == null) {
      _logger.stderr(t.setup.ascKeys.cacheMissing(version: ascVersion));
      return 1;
    }

    _logger.stdout(
      t.setup.ascKeys.cacheFound(version: ascVersion, path: executable.path),
    );
    _logger.stderr(t.setup.ascKeys.notImplemented);
    return 1;
  }
}
