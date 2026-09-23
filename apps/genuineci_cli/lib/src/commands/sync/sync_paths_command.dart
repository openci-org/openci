import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as p;

import '../../extensions/file_extensions.dart';
import '../../i18n/i18n.dart';
import 'generate_workspace_paths.dart';
import 'read_workspace_directories.dart';
import 'read_workspace_packages.dart';

class SyncPathsCommand extends Command<int> {
  @override
  final String name = 'paths';

  @override
  String get description => t.sync.paths.description;

  final Logger _logger;
  final Directory? _workingDirectory;

  SyncPathsCommand({required Logger logger, Directory? workingDirectory})
    : _logger = logger,
      _workingDirectory = workingDirectory;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.sync.paths.noArguments);
    }
    try {
      final root = findWorkspaceRoot(_workingDirectory);
      if (root == null) {
        _logger.stderr(t.sync.paths.projectRootNotFound);
        return 1;
      }
      final packages = await readWorkspacePackages(root);
      final paths = await readWorkspaceDirectories(root, packages.values);
      final source = generateWorkspacePaths(paths);
      final file = File(p.join(root.path, 'openci', 'paths.g.dart'));
      await file.writeAsStringAtomic(source);
      _logger.stdout(t.sync.paths.saved(path: file.path));
      return 0;
    } on FormatException catch (error) {
      _logger.stderr(t.common.error(error: error.message));
    } on FileSystemException catch (error) {
      _logger.stderr(t.sync.paths.fileAccessFailed(path: error.path ?? ''));
    }
    return 1;
  }
}
