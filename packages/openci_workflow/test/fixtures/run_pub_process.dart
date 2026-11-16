import 'dart:async';
import 'dart:io';

import 'package:openci_workflow/src/dart/pub_process.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.first == 'child') {
    if (arguments[1] == 'timeout') {
      stdout.writeln('child-pid=$pid');
      await Future<void>.delayed(const Duration(minutes: 5));
    } else {
      stdout.write('fake.identity.');
      await stdout.flush();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      stdout.writeln('token');
      stderr.write('fake.identity.token');
      exit(7);
    }
    return;
  }
  try {
    final code = await runPubProcess(
      switch (arguments.first) {
        'missing' => '/missing/openci-dart',
        'timeout' => 'sh',
        _ => Platform.resolvedExecutable,
      },
      arguments.first == 'timeout'
          ? ['-c', r'echo child-pid=$$; exec sleep 300']
          : [Platform.script.toFilePath(), 'child', arguments.first],
      workingDirectory: Directory.current.path,
      environment: {},
      secrets: ['fake.identity.token'],
      timeout: Duration(seconds: arguments.first == 'timeout' ? 2 : 20),
    );
    stdout.writeln('exit-code=$code');
  } on TimeoutException catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 3;
  }
}
