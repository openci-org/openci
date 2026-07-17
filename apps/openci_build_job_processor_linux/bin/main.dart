import 'dart:async';
import 'dart:io';

Future<void> main() async {
  stderr.writeln('openci_build_job_processor_linux started (mock entrypoint)');
  while (true) {
    await Future.delayed(const Duration(seconds: 60));
  }
}
