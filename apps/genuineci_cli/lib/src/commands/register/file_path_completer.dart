import 'dart:io';

import 'package:path/path.dart' as p;

class FilePathCompleter {
  final String workingDirectory;
  final String? homeDirectory;

  FilePathCompleter({String? workingDirectory, String? homeDirectory})
    : workingDirectory = workingDirectory ?? Directory.current.path,
      homeDirectory =
          homeDirectory ??
          Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'];

  String resolve(String input) {
    var path = _unquote(input);
    final parts = p.split(path);
    if (parts.isNotEmpty && parts.first == '~' && homeDirectory != null) {
      path = p.joinAll([homeDirectory!, ...parts.skip(1)]);
    }
    return p.normalize(p.join(workingDirectory, path));
  }

  List<String> complete(String input) {
    final path = _unquote(input);
    if (path == '~' && homeDirectory != null) return ['~${p.separator}'];
    final inDirectory = path.isEmpty || path.endsWith(p.separator);
    final parent = inDirectory ? path : p.dirname(path);
    final prefix = inDirectory ? '' : p.basename(path);
    final matches = <({String path, bool directory})>[];
    for (final entry in Directory(resolve(parent)).listSync()) {
      final name = p.basename(entry.path);
      if (!name.toLowerCase().startsWith(prefix.toLowerCase()) ||
          (name.startsWith('.') && !prefix.startsWith('.'))) {
        continue;
      }
      final directory = entry is Directory;
      if (!directory && entry is! File) continue;
      final candidate = p.normalize(p.join(parent, name));
      matches.add((
        path: directory ? '$candidate${p.separator}' : candidate,
        directory: directory,
      ));
    }
    matches.sort((a, b) {
      if (a.directory != b.directory) return a.directory ? -1 : 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
    return matches.map((match) => match.path).toList();
  }

  String _unquote(String input) {
    if (input.length >= 2 &&
        ((input.startsWith('"') && input.endsWith('"')) ||
            (input.startsWith("'") && input.endsWith("'")))) {
      return input.substring(1, input.length - 1);
    }
    return input;
  }
}
