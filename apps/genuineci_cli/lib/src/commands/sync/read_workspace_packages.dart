import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'generate_workspace_paths.dart';

Directory? findWorkspaceRoot([Directory? startDirectory]) {
  var directory = (startDirectory ?? Directory.current).absolute;
  while (true) {
    if (File(p.join(directory.path, 'pubspec.yaml')).existsSync() &&
        Directory(p.join(directory.path, 'openci')).existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) return null;
    directory = parent;
  }
}

Future<Map<String, String>> readWorkspacePackages(Directory root) async {
  final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
  final pubspec = await _readPubspec(pubspecFile);
  final workspace = pubspec['workspace'];
  if (workspace is! List || workspace.any((path) => path is! String)) {
    throw FormatException(
      '${pubspecFile.path}: workspace must be a list of relative package paths.',
    );
  }

  final packages = <String, String>{};
  for (final path in workspace.cast<String>()) {
    validateWorkspacePath(path);
    final file = File(p.join(root.path, path, 'pubspec.yaml'));
    final package = await _readPubspec(file);
    final name = package['name'];
    if (name is! String || name.isEmpty) {
      throw FormatException('${file.path}: name must be a non-empty string.');
    }
    final previous = packages[name];
    if (previous != null) {
      throw FormatException(
        'Package ${jsonEncode(name)} is declared by both '
        '${jsonEncode(previous)} and ${jsonEncode(path)}.',
      );
    }
    packages[name] = path;
  }
  return packages;
}

Future<YamlMap> _readPubspec(File file) async {
  final content = await file.readAsString();
  final Object? pubspec;
  try {
    pubspec = loadYaml(content);
  } on YamlException {
    throw FormatException('${file.path}: invalid YAML.');
  }
  if (pubspec is! YamlMap) {
    throw FormatException('${file.path}: expected a YAML map.');
  }
  return pubspec;
}
