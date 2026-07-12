// ignore_for_file: unused_local_variable

import 'dart:io';

Future<void> main() async {
  final serverUrl = Platform.environment['OPENCI_SERVER_URL'];
  final runsOnPattern = Platform.environment['OPENCI_RUNS_ON_PATTERN'];
  final baseVmName = Platform.environment['LUME_BASE_VM_NAME'];
  final lumeServerUrlsStr = Platform.environment['LUME_SERVER_URLS'];

  final lumeServerUrls = lumeServerUrlsStr!
      .split(',')
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();

  if (lumeServerUrls.isEmpty) {
    throw StateError('LUME_SERVER_URLS must contain at least one URL.');
  }
}
