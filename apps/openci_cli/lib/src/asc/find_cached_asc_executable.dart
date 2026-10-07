import 'dart:ffi';
import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:path/path.dart' as p;

const ascVersion = '5.11.0';

/// Finds the cached file for Apple Silicon Macs without validating or running it.
Future<File?> findCachedAscExecutable({
  Directory? cacheDirectory,
  Abi? abi,
}) async {
  if ((abi ?? Abi.current()) != Abi.macosArm64) {
    throw UnsupportedError('asc cache checks currently require macOS arm64.');
  }
  final cache =
      cacheDirectory ?? Directory(BaseDirectories('genuineci').cacheHome);
  final executable = File(
    p.join(cache.path, 'tools', 'asc', ascVersion, 'macOS_arm64', 'asc'),
  ).absolute;

  final type = await FileSystemEntity.type(executable.path, followLinks: false);
  return type == FileSystemEntityType.file ? executable : null;
}
