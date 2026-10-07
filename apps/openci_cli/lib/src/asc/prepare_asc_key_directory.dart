import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Reserves an owner-only directory that survives cache and temporary cleanup.
Future<Directory> prepareAscKeyDirectory({
  @visibleForTesting Directory? dataDirectory,
}) async {
  final data =
      dataDirectory ?? Directory(BaseDirectories('genuineci').dataHome);
  final parent = Directory(p.join(data.absolute.path, 'asc-api-keys'));
  await parent.create(recursive: true);
  // createTemp makes a unique directory with mode 0700 on macOS.
  return parent.createTemp('key-');
}
