import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:http/http.dart' as http;

import '../credential_store/credential_store.dart';
import '../credential_store/read_authenticated_profile.dart';
import '../i18n/i18n.dart';
import '../mcp/open_ci_mcp_server.dart';

class McpCommand extends Command<int> {
  @override
  String get name => 'mcp';

  @override
  String get description => t.cli.mcpDescription;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException('openci mcp takes no arguments.');
    }
    final client = http.Client();
    final store = CredentialStore();
    try {
      final server = OpenCiMcpServer(
        stdioChannel(input: stdin, output: stdout),
        () => readAuthenticatedProfile(store),
        client,
      );
      await server.done;
      return 0;
    } finally {
      client.close();
    }
  }
}
