import 'dart:io';

import 'package:meta/meta.dart';

Directory? findProjectRoot([Directory? startDir]) {
  var dir = startDir ?? Directory.current;
  while (true) {
    if (isOpenciProjectRoot(dir)) {
      return dir;
    }
    if (dir.path == dir.parent.path) {
      return null;
    }
    dir = dir.parent;
  }
}

@visibleForTesting
bool isOpenciProjectRoot(Directory dir) {
  final composeFile = File('${dir.path}/docker-compose.yml');
  final serverDir = Directory('${dir.path}/apps/openci_server');
  return composeFile.existsSync() && serverDir.existsSync();
}
