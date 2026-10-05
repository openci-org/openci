import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

Future<List<String>> readWorkspaceDirectories(
  Directory root,
  Iterable<String> packagePaths,
) async {
  final paths = <String>[];
  for (final packagePath in packagePaths) {
    paths.addAll(
      await readDirectoryPaths(
        Directory(p.join(root.path, packagePath)),
        workspaceRoot: root,
      ),
    );
  }
  return paths;
}

@visibleForTesting
Future<List<String>> readDirectoryPaths(
  Directory directory, {
  required Directory workspaceRoot,
}) async {
  const excludedDirectories = {
    'build',
    'coverage',
    'node_modules',
    'Pods',
    'ephemeral',
    'xcuserdata',
  };
  final relativePath = p.relative(directory.path, from: workspaceRoot.path);
  final paths = [p.posix.joinAll(p.split(relativePath))];
  await for (final entry in directory.list(followLinks: false)) {
    if (entry is! Directory) continue;
    final name = p.basename(entry.path);
    if (name.startsWith('.') || excludedDirectories.contains(name)) continue;
    if (p.equals(
      entry.path,
      p.join(workspaceRoot.path, 'openci', 'generated'),
    )) {
      continue;
    }
    paths.addAll(await readDirectoryPaths(entry, workspaceRoot: workspaceRoot));
  }
  return paths;
}
