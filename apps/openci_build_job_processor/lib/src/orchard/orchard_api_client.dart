import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class OrchardLease {
  final String id;
  final String vmName;
  final String? ipAddress;
  final int? sshPort;
  final String status;

  OrchardLease({
    required this.id,
    required this.vmName,
    this.ipAddress,
    this.sshPort,
    required this.status,
  });

  factory OrchardLease.fromJson(Map<String, dynamic> json) {
    return OrchardLease(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      vmName: json['vm_name'] as String? ?? json['vmName'] as String? ?? '',
      ipAddress: json['ip_address'] as String? ?? json['ip'] as String?,
      sshPort: json['ssh_port'] as int? ?? json['sshPort'] as int?,
      status: json['status'] as String? ?? 'unknown',
    );
  }
}

class OrchardApiClient {
  final String baseUrl;
  final String serviceAccountName;
  final String serviceAccountToken;
  final http.Client _httpClient;

  OrchardApiClient({
    required this.baseUrl,
    required this.serviceAccountName,
    required this.serviceAccountToken,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? _createHttpClient();

  static http.Client _createHttpClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    return IOClient(ioClient);
  }

  Map<String, String> get _headers {
    final credentials = '$serviceAccountName:$serviceAccountToken';
    final encoded = base64Encode(utf8.encode(credentials));
    return {
      'Authorization': 'Basic $encoded',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getControllerInfo() async {
    final uri = Uri.parse('$baseUrl/v1/info');
    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to get Orchard controller info: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<OrchardLease> createLease({
    required String imageName,
    String? vmName,
    int? cpuCount,
    int? memoryGb,
    bool headless = true,
    String os = 'darwin',
  }) async {
    final targetName =
        vmName ?? 'openci-vm-${DateTime.now().millisecondsSinceEpoch}';
    final uri = Uri.parse('$baseUrl/v1/vms');
    final payload = <String, dynamic>{
      'name': targetName,
      'image': imageName,
      'headless': headless,
      'os': os,
    };
    final defaultCpu =
        int.tryParse(Platform.environment['ORCHARD_VM_CPU'] ?? '2') ?? 2;
    final defaultMemoryGb =
        int.tryParse(Platform.environment['ORCHARD_VM_MEMORY_GB'] ?? '4') ?? 4;
    final cpu = cpuCount ?? defaultCpu;
    final memMib = (memoryGb ?? defaultMemoryGb) * 1024;
    payload['cpu'] = cpu;
    payload['memory'] = memMib;
    payload['resources'] = {
      'org.cirruslabs.logical-cores': cpu,
      'org.cirruslabs.memory-mib': memMib,
      'org.cirruslabs.tart-vms': 1,
    };

    final response = await _httpClient.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OrchardLease.fromJson(json);
    } else {
      throw Exception(
        'Failed to create Orchard VM: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<OrchardLease> getLease(String leaseId) async {
    final uri = Uri.parse('$baseUrl/v1/vms/$leaseId');
    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OrchardLease.fromJson(json);
    } else {
      throw Exception(
        'Failed to get Orchard VM ($leaseId): ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> deleteLease(String leaseId) async {
    final uri = Uri.parse('$baseUrl/v1/vms/$leaseId');
    final response = await _httpClient.delete(uri, headers: _headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to delete Orchard VM ($leaseId): ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<OrchardLease> waitForVmRunning(
    String leaseId, {
    Duration timeout = const Duration(minutes: 5),
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < timeout) {
      try {
        final lease = await getLease(leaseId);
        if (lease.status.toLowerCase() == 'running' ||
            lease.status.toLowerCase() == 'active') {
          return lease;
        }
      } catch (_) {}
      await Future.delayed(pollInterval);
    }
    throw TimeoutException(
      'Timed out waiting for Orchard VM ($leaseId) to reach running status.',
    );
  }

  Future<int> execCommandWebSocket({
    required String vmName,
    required String command,
    required void Function(String line) onLog,
    required Future<bool> Function() isCancelled,
    int waitSeconds = 300,
  }) async {
    final httpUri = Uri.parse(baseUrl);
    final wsScheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    final encodedCommand = Uri.encodeComponent(command);
    final wsUri = Uri.parse(
      '$wsScheme://${httpUri.host}:${httpUri.port}/v1/vms/$vmName/exec?command=$encodedCommand&wait=$waitSeconds',
    );

    final credentials = '$serviceAccountName:$serviceAccountToken';
    final encodedAuth = base64Encode(utf8.encode(credentials));
    final headers = <String, String>{'Authorization': 'Basic $encodedAuth'};

    final customClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    try {
      final socket = await WebSocket.connect(
        wsUri.toString(),
        headers: headers,
        customClient: customClient,
      );

      final completer = Completer<int>();

      final subscription = socket.listen(
        (data) {
          try {
            final jsonStr = data is String
                ? data
                : utf8.decode(data as List<int>);
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            final type = map['type'] as String?;

            if (type == 'stdout' || type == 'stderr') {
              final rawData = map['data'] as String?;
              if (rawData != null && rawData.isNotEmpty) {
                final decodedText = utf8.decode(base64Decode(rawData));
                for (final line in decodedText.split('\n')) {
                  if (line.isNotEmpty) onLog(line);
                }
              }
            } else if (type == 'exit') {
              final exitInfo = map['exit'] as Map<String, dynamic>?;
              final code = exitInfo?['code'] as int? ?? 0;
              if (!completer.isCompleted) completer.complete(code);
            } else if (type == 'error') {
              final errMsg = map['error'] as String? ?? 'Exec error';
              onLog('Orchard Exec Error: $errMsg');
              if (!completer.isCompleted) completer.complete(-1);
            }
          } catch (_) {
            if (data is String) onLog(data);
          }
        },
        onError: (err) {
          onLog('Orchard Exec WebSocket Error: $err');
          if (!completer.isCompleted) completer.completeError(err);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(0);
        },
      );

      unawaited(
        Future.microtask(() async {
          while (!completer.isCompleted) {
            if (await isCancelled()) {
              await socket.close(WebSocketStatus.normalClosure, 'Cancelled');
              await subscription.cancel();
              if (!completer.isCompleted) completer.complete(-1);
              break;
            }
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }),
      );

      return await completer.future;
    } catch (e) {
      onLog('Failed to connect to Orchard Exec WebSocket: $e');
      rethrow;
    }
  }
}
