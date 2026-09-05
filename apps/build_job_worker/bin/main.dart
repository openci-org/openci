import 'dart:io';

import 'package:build_job_worker/build_job_worker.dart';

void main() {
  try {
    Config.fromEnvironment();
    stdout.writeln(
      'Build job worker configuration loaded. Job processing is not enabled yet.',
    );
  } on StateError catch (error) {
    stderr.writeln('Build job worker configuration error: ${error.message}');
    exitCode = 1;
  }
}
