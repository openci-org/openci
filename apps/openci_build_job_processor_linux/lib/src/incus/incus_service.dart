import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logging/logging.dart';

final _log = Logger('IncusService');

class IncusService {
  IncusService({
    required this.apiUrl,
    bool acceptSelfSignedCertificates = true,
  }) {
    if (acceptSelfSignedCertificates) {
      final ioClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      _client = IOClient(ioClient);
    } else {
      _client = http.Client();
    }
  }

  final String apiUrl;
  late final http.Client _client;

  Future<Map<String, dynamic>> _waitForOperation(String operationPath) async {
    final url = Uri.parse('$apiUrl$operationPath/wait');
    final response = await _client
        .get(url)
        .timeout(const Duration(minutes: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to wait for operation $operationPath: ${response.statusCode} - ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final metadata = body['metadata'] as Map<String, dynamic>?;
    final statusCode = body['status_code'] as int? ?? 0;

    if (statusCode == 200) {
      return metadata ?? {};
    } else {
      final err =
          body['err'] as String? ??
          metadata?['err'] as String? ??
          'Unknown error';
      throw Exception('Operation $operationPath failed: $err. Raw body: $body');
    }
  }

  Future<void> cloneContainer(String sourceName, String targetName) async {
    final url = Uri.parse('$apiUrl/1.0/instances');
    final body = jsonEncode({
      'name': targetName,
      'source': {'type': 'copy', 'source': sourceName},
    });

    _log.info('Cloning container $sourceName to $targetName...');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 202) {
      throw Exception(
        'Failed to clone container: ${response.statusCode} - ${response.body}',
      );
    }

    final resBody = jsonDecode(response.body) as Map<String, dynamic>;
    final operationPath = resBody['operation'] as String?;
    if (operationPath == null) {
      throw Exception('No operation URL returned from clone request');
    }

    await _waitForOperation(operationPath);
    _log.info('Container cloned successfully.');
  }

  Future<void> startContainer(String name) async {
    final url = Uri.parse('$apiUrl/1.0/instances/$name/state');
    final body = jsonEncode({'action': 'start', 'timeout': 30, 'force': true});

    _log.info('Starting container $name...');
    final response = await _client.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 202) {
      throw Exception(
        'Failed to start container: ${response.statusCode} - ${response.body}',
      );
    }

    final resBody = jsonDecode(response.body) as Map<String, dynamic>;
    final operationPath = resBody['operation'] as String?;
    if (operationPath == null) {
      throw Exception('No operation URL returned from start request');
    }

    await _waitForOperation(operationPath);
    _log.info('Container $name started.');
  }

  Future<void> stopContainer(String name, {bool force = true}) async {
    final url = Uri.parse('$apiUrl/1.0/instances/$name/state');
    final body = jsonEncode({'action': 'stop', 'timeout': 30, 'force': force});

    _log.info('Stopping container $name (force=$force)...');
    final response = await _client.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 400) {
      final resBody = jsonDecode(response.body) as Map<String, dynamic>;
      final error = resBody['error'] as String? ?? '';
      if (error.contains('already stopped') ||
          error.contains('is not running')) {
        _log.info('Container $name is already stopped.');
        return;
      }
    }

    if (response.statusCode != 202) {
      throw Exception(
        'Failed to stop container: ${response.statusCode} - ${response.body}',
      );
    }

    final resBody = jsonDecode(response.body) as Map<String, dynamic>;
    final operationPath = resBody['operation'] as String?;
    if (operationPath == null) {
      throw Exception('No operation URL returned from stop request');
    }

    try {
      await _waitForOperation(operationPath);
    } catch (e) {
      if (e.toString().contains('already stopped') ||
          e.toString().contains('is not running')) {
        _log.info('Container $name is stopped.');
      } else {
        rethrow;
      }
    }
    _log.info('Container $name stopped.');
  }

  Future<void> deleteContainer(String name) async {
    final url = Uri.parse('$apiUrl/1.0/instances/$name');

    _log.info('Deleting container $name...');
    final response = await _client.delete(url);

    if (response.statusCode == 404) {
      _log.info('Container $name does not exist, skipping deletion.');
      return;
    }

    if (response.statusCode != 202) {
      throw Exception(
        'Failed to delete container: ${response.statusCode} - ${response.body}',
      );
    }

    final resBody = jsonDecode(response.body) as Map<String, dynamic>;
    final operationPath = resBody['operation'] as String?;
    if (operationPath == null) {
      throw Exception('No operation URL returned from delete request');
    }

    await _waitForOperation(operationPath);
    _log.info('Container $name deleted.');
  }

  Future<void> writeFile(
    String containerName,
    String remotePath,
    String content, {
    String mode = '0600',
  }) async {
    final encodedPath = Uri.encodeComponent(remotePath);
    final url = Uri.parse(
      '$apiUrl/1.0/instances/$containerName/files?path=$encodedPath',
    );

    _log.info('Writing file to $containerName:$remotePath...');
    final response = await _client.post(
      url,
      headers: {
        'X-Incus-mode': mode,
        'Content-Type': 'application/octet-stream',
      },
      body: utf8.encode(content),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to write file to container: ${response.statusCode} - ${response.body}',
      );
    }
    _log.info('File written successfully.');
  }

  Future<int> executeCommandStreaming({
    required String containerName,
    required List<String> command,
    required void Function(String log) onLog,
    required FutureOr<bool> Function() isCancelled,
    Map<String, String>? environment,
  }) async {
    final url = Uri.parse('$apiUrl/1.0/instances/$containerName/exec');
    final body = jsonEncode({
      'command': command,
      'environment': environment ?? {},
      'wait-for-variables': false,
      'record-output': false,
      'interactive': false,
      'wait-for-websocket': true,
    });

    _log.info('Executing command in $containerName: $command');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 202) {
      throw Exception(
        'Failed to initiate exec: ${response.statusCode} - ${response.body}',
      );
    }

    final resBody = jsonDecode(response.body) as Map<String, dynamic>;
    final operationPath = resBody['operation'] as String?;
    if (operationPath == null) {
      throw Exception('No operation URL returned from exec request');
    }

    final metadata = resBody['metadata'] as Map<String, dynamic>?;
    if (metadata == null) {
      throw Exception('No metadata returned from exec request');
    }

    final opMetadata = metadata['metadata'] as Map<String, dynamic>?;
    final fds = opMetadata?['fds'] as Map<String, dynamic>?;
    if (fds == null) {
      throw Exception(
        'No file descriptors (fds) returned from exec request. Raw response: $resBody',
      );
    }

    final stdinSecret = fds['0'] as String?;
    final stdoutSecret = fds['1'] as String?;
    final stderrSecret = fds['2'] as String?;

    if (stdoutSecret == null) {
      throw Exception('Missing stdout secret in fds');
    }

    final wsBaseUrl = apiUrl.replaceFirst(RegExp(r'^http'), 'ws');

    final futures = <Future<void>>[];
    final stdinCompleter = Completer<void>();
    final stdoutCompleter = Completer<void>();
    final stderrCompleter = Completer<void>();

    if (stdinSecret != null) {
      final stdinWsUrl =
          '$wsBaseUrl$operationPath/websocket?secret=$stdinSecret';
      futures.add(
        _connectAndStream(stdinWsUrl, (_) {}, stdinCompleter, isCancelled),
      );
    } else {
      stdinCompleter.complete();
    }

    final stdoutWsUrl =
        '$wsBaseUrl$operationPath/websocket?secret=$stdoutSecret';
    futures.add(
      _connectAndStream(stdoutWsUrl, onLog, stdoutCompleter, isCancelled),
    );

    if (stderrSecret != null) {
      final stderrWsUrl =
          '$wsBaseUrl$operationPath/websocket?secret=$stderrSecret';
      futures.add(
        _connectAndStream(stderrWsUrl, onLog, stderrCompleter, isCancelled),
      );
    } else {
      stderrCompleter.complete();
    }

    final execResultFuture = _waitForOperation(operationPath);
    final completer = Completer<int>();

    unawaited(() async {
      unawaited(() async {
        while (!completer.isCompleted) {
          await Future.delayed(const Duration(seconds: 1));
          if (await isCancelled()) {
            if (!completer.isCompleted) {
              completer.completeError(
                TimeoutException('Command cancelled by user'),
              );
            }
            break;
          }
        }
      }());

      try {
        final results = await Future.wait([...futures, execResultFuture]);

        final execMetadata = results.last as Map<String, dynamic>;
        final returnCode = execMetadata['return'] as int? ?? 0;

        if (!completer.isCompleted) {
          completer.complete(returnCode);
        }
      } catch (e, s) {
        if (!completer.isCompleted) {
          completer.completeError(e, s);
        }
      }
    }());

    return completer.future;
  }

  Future<void> _connectAndStream(
    String wsUrl,
    void Function(String) onLog,
    Completer<void> completer,
    FutureOr<bool> Function() isCancelled,
  ) async {
    WebSocket? ws;
    try {
      _log.fine('Connecting to WebSocket: $wsUrl');
      ws = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 10));

      final subscription = ws.listen(
        (data) {
          if (data is List<int>) {
            onLog(utf8.decode(data));
          } else if (data is String) {
            onLog(data);
          }
        },
        onError: (err) {
          _log.warning('WebSocket error on $wsUrl: $err');
          completer.complete();
        },
        onDone: () {
          completer.complete();
        },
        cancelOnError: true,
      );

      unawaited(() async {
        while (!completer.isCompleted) {
          await Future.delayed(const Duration(seconds: 1));
          if (await isCancelled()) {
            await subscription.cancel();
            await ws?.close();
            break;
          }
        }
      }());
    } catch (e) {
      _log.warning('Failed to connect to WebSocket $wsUrl: $e');
      completer.complete();
    }
  }

  Future<List<String>> getActiveBuildInstances() async {
    final url = Uri.parse('$apiUrl/1.0/instances');
    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get instances: ${response.statusCode} - ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final metadata = body['metadata'] as List<dynamic>? ?? [];

    final instances = <String>[];
    for (final item in metadata) {
      if (item is String) {
        final name = item.split('/').last;
        if (name.startsWith('openci-vm-')) {
          instances.add(name);
        }
      } else if (item is Map<String, dynamic>) {
        final name = item['name'] as String?;
        if (name != null && name.startsWith('openci-vm-')) {
          instances.add(name);
        }
      }
    }

    return instances;
  }

  Future<int> getRunningVmCount() async {
    final url = Uri.parse('$apiUrl/1.0/instances?recursion=1');
    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get instances details: ${response.statusCode} - ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final metadata = body['metadata'] as List<dynamic>? ?? [];

    int runningCount = 0;
    for (final item in metadata) {
      if (item is Map<String, dynamic>) {
        final status = item['status'] as String?;
        final name = item['name'] as String? ?? '';
        if (status == 'Running' && name.startsWith('openci-vm-')) {
          runningCount++;
        }
      }
    }

    return runningCount;
  }

  void close() {
    _client.close();
  }
}
