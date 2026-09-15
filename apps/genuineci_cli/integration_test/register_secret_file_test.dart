@TestOn('mac-os')
library;

import 'dart:io';

import 'package:cli_util/cli_util.dart' as cli;
import 'package:genuineci_cli/src/commands/sync/read_workspace_packages.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'file registration exits cleanly in a real terminal',
    () async {
      final fixtures = p.absolute('integration_test', 'fixtures');
      final packageConfig = p.join(
        findWorkspaceRoot()!.path,
        '.dart_tool',
        'package_config.json',
      );
      // Use the JIT runtime, as used by pub global run. An AOT-only test missed
      // dart_console's macOS ARM64 memory corruption during VM shutdown.
      final result = await Process.run('python3', [
        p.join(fixtures, 'register_secret_file_pty.py'),
        p.join(cli.sdkPath, 'bin', 'dart'),
        '--packages=$packageConfig',
        p.join(fixtures, 'register_secret_file_cli.dart'),
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
