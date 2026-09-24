import 'dart:io';

import 'package:path/path.dart' as p;

Directory? findWorkflowDirectory([Directory? startDirectory]) {
  var directory = (startDirectory ?? Directory.current).absolute;
  while (true) {
    final workflows = Directory(p.join(directory.path, 'openci'));
    if (workflows.existsSync()) return workflows;
    final parent = directory.parent;
    if (parent.path == directory.path) return null;
    directory = parent;
  }
}
