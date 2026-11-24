import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:stream_channel/stream_channel.dart';

import '../credential_store/credential_store.dart';
import '../i18n/i18n.dart';
import '../mcp/openci_mcp_server.dart';

class McpCommand extends Command<int> {
  @override
  final String name = 'mcp';

  @override
  String get description => t.mcp.description;

  final CredentialStore _credentialStore;
  final StreamChannel<String> Function()? _channelFactory;

  McpCommand({
    CredentialStore? credentialStore,
    StreamChannel<String> Function()? channelFactory,
  }) : _credentialStore = credentialStore ?? CredentialStore(),
       _channelFactory = channelFactory;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.mcp.noArguments);
    }

    // Redirect any accidental print() calls to stderr so stdout remains
    // exclusively JSON-RPC frames for MCP stdio transport.
    final completer = Completer<int>();
    runZonedGuarded(
      () async {
        final channel =
            _channelFactory?.call() ??
            stdioChannel(input: stdin, output: stdout);
        final server = OpenCIMcpServer(
          channel,
          credentialStore: _credentialStore,
        );
        await server.done;
        if (!completer.isCompleted) {
          completer.complete(0);
        }
      },
      (error, stackTrace) {
        stderr.writeln('OpenCI MCP server error: $error');
        if (!completer.isCompleted) {
          completer.complete(1);
        }
      },
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => stderr.writeln(line),
      ),
    );
    return completer.future;
  }
}
