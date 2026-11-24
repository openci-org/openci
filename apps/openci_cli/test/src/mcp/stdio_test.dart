import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:test/test.dart';

void main() {
  test(
    'the CLI speaks MCP over pipes and validates input before authentication',
    () async {
      final library = await Isolate.resolvePackageUri(
        Uri.parse('package:openci_cli_plus/openci_cli_plus.dart'),
      );
      final main = library!.resolve('../bin/openci_cli_plus.dart').toFilePath();
      final process = await Process.start(Platform.resolvedExecutable, [
        main,
        'mcp',
      ]);
      addTearDown(() => process.kill());
      final errors = utf8.decoder.bind(process.stderr).join();
      final client = MCPClient(Implementation(name: 'test', version: '1'));
      final connection = client.connectServer(
        stdioChannel(input: process.stdout, output: process.stdin),
      );
      final init = await connection.initialize(
        InitializeRequest(
          protocolVersion: ProtocolVersion.latestSupported,
          capabilities: client.capabilities,
          clientInfo: client.implementation,
        ),
      );
      expect(init.serverInfo.name, 'openci');
      connection.notifyInitialized();
      final tools = await connection.listTools(ListToolsRequest());
      expect(tools.tools.map((t) => t.name), contains('get_job_logs'));
      final invalid = await connection.callTool(
        CallToolRequest(name: 'get_job_logs', arguments: {}),
      );
      expect(invalid.isError, isTrue);
      await connection.shutdown();
      expect(await process.exitCode, 0);
      expect(await errors, isEmpty);
    },
  );
}
