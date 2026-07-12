// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:openci_build_job_processor/openci_build_job_processor.dart';

Future<void> main() async {
  final serverUrl = Platform.environment['OPENCI_SERVER_URL'];
  final runsOnPattern = Platform.environment['OPENCI_RUNS_ON_PATTERN'];
  final baseVmName = Platform.environment['LUME_BASE_VM_NAME'];
  final lumeServerUrls = Platform.environment['LUME_SERVER_URLS'];
  final lumeServerUrlList = parseLumeServerUrls(lumeServerUrls);

  if (lumeServerUrlList.isEmpty) {
    throw StateError('LUME_SERVER_URLS must contain at least one URL.');
  }
}
