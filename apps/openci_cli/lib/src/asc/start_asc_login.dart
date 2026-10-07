import 'dart:io';

import 'package:meta/meta.dart';

typedef AscLoginProcessStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      required ProcessStartMode mode,
    });

/// Starts interactive Apple login using an already verified asc executable.
///
/// The caller must wait for the returned process to exit.
Future<Process> startAscLogin(
  File executable,
  String appleId, {
  @visibleForTesting AscLoginProcessStarter processStarter = Process.start,
}) => processStarter(executable.absolute.path, [
  'web',
  'auth',
  'login',
  '--apple-id',
  appleId,
  '--output',
  'table',
], mode: ProcessStartMode.inheritStdio);
