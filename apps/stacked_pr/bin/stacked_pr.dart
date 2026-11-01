import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:stacked_pr_app/src/environment.dart';
import 'package:stacked_pr_app/src/state_admin.dart';

Future<void> main(List<String> args) async {
  try {
    final env = loadEnvironment();
    if (args.firstOrNull == 'healthcheck') {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      try {
        final request = await client.getUrl(
          Uri.parse('http://127.0.0.1:${env['PORT'] ?? '3000'}/healthz'),
        );
        final response = await request.close().timeout(const Duration(seconds: 3));
        exitCode = response.statusCode == 200 ? 0 : 1;
        await response.drain<void>();
      } finally {
        client.close(force: true);
      }
      return;
    }
    if (args.firstOrNull != 'state') {
      throw const FormatException(
        'Usage: stacked_pr healthcheck|state [status|retry-failed|discard-operation ID]',
      );
    }
    final result = manageState(
      p.join(env['DATA_DIR'] ?? 'data', 'stacked-pr.sqlite'),
      args.length > 1 ? args[1] : 'status',
      args.length > 2 ? args[2] : null,
    );
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
  } catch (error) {
    stderr.writeln(
      error is FormatException
          ? error.message
          : 'Command failed. Check configuration and data directory.',
    );
    exitCode = 1;
  }
}
