import 'dart:io';

import 'package:path/path.dart' as p;

const _excludedDirectories = {'build', 'coverage', 'node_modules', 'Pods'};

/// Collects workspace packages and their immediate, visible subdirectories.
///
/// Build outputs, dependencies, hidden directories and symlinks are excluded.
Future<List<String>> readWorkspaceDirectories(
  Directory root,
  Iterable<String> packagePaths,
) async {
  final paths = <String>[];
  for (final packagePath in packagePaths) {
    paths.add(packagePath);
    final directory = Directory(p.join(root.path, packagePath));
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final name = p.basename(entry.path);
      if (name.startsWith('.') || _excludedDirectories.contains(name)) continue;
      paths.add(p.posix.join(packagePath.replaceAll(r'\', '/'), name));
    }
  }
  return paths;
}
