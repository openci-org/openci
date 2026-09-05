import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../config.dart';

class OrchardLease {
  const OrchardLease({
    required this.id,
    required this.vmName,
    required this.status,
    this.ipAddress,
    this.sshPort,
  });

  factory OrchardLease.fromJson(Map<String, dynamic> json) {
    return OrchardLease(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      vmName: json['vm_name'] as String? ?? json['vmName'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      ipAddress: json['ip_address'] as String? ?? json['ip'] as String?,
      sshPort: json['ssh_port'] as int? ?? json['sshPort'] as int?,
    );
  }

  final String id;
  final String vmName;
  final String status;
  final String? ipAddress;
  final int? sshPort;
}

class OrchardApiClient {
  OrchardApiClient({required Config config, http.Client? httpClient})
    : _config = config,
      _httpClient = httpClient ?? _createHttpClient(config.orchardApiUrl);

  final Config _config;
  final http.Client _httpClient;

  Map<String, String> get _headers {
    final credentials =
        '${_config.orchardServiceAccountName}:${_config.orchardServiceAccountToken}';
    return {
      'Authorization': 'Basic ${base64Encode(utf8.encode(credentials))}',
      'Content-Type': 'application/json',
    };
  }

  Future<OrchardLease> createLease({
    required String imageName,
    String? vmName,
    int? cpuCount,
    int? memoryGb,
    bool headless = true,
    String os = 'darwin',
  }) async {
    final cpu =
        cpuCount ??
        int.tryParse(Platform.environment['ORCHARD_VM_CPU'] ?? '') ??
        2;
    final memoryMiB =
        (memoryGb ??
            int.tryParse(Platform.environment['ORCHARD_VM_MEMORY_GB'] ?? '') ??
            4) *
        1024;
    final response = await _httpClient.post(
      _vmUri(),
      headers: _headers,
      body: jsonEncode({
        'name': vmName ?? 'openci-vm-${DateTime.now().millisecondsSinceEpoch}',
        'image': imageName,
        'headless': headless,
        'os': os,
        'cpu': cpu,
        'memory': memoryMiB,
        'resources': {
          'org.cirruslabs.logical-cores': cpu,
          'org.cirruslabs.memory-mib': memoryMiB,
          'org.cirruslabs.tart-vms': 1,
        },
      }),
    );
    _checkResponse(response, 'create Orchard VM');
    return OrchardLease.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<OrchardLease> getLease(String leaseId) async {
    final response = await _httpClient.get(_vmUri(leaseId), headers: _headers);
    _checkResponse(response, 'get Orchard VM ($leaseId)');
    return OrchardLease.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteLease(String leaseId) async {
    final response = await _httpClient.delete(
      _vmUri(leaseId),
      headers: _headers,
    );
    _checkResponse(response, 'delete Orchard VM ($leaseId)');
  }

  Future<OrchardLease> waitForVmRunning(
    String leaseId, {
    Duration timeout = const Duration(minutes: 5),
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    final stopwatch = Stopwatch()..start();
    final timeoutError = TimeoutException(
      'Timed out waiting for Orchard VM ($leaseId) to reach running status.',
      timeout,
    );

    while (stopwatch.elapsed < timeout) {
      final lease = await getLease(leaseId).timeout(
        timeout - stopwatch.elapsed,
        onTimeout: () => throw timeoutError,
      );
      final status = lease.status.toLowerCase();
      if (status == 'running' || status == 'active') return lease;

      final remaining = timeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) break;
      await Future<void>.delayed(
        pollInterval < remaining ? pollInterval : remaining,
      );
    }
    throw timeoutError;
  }

  Future<int> execCommandWebSocket({
    required String vmName,
    required String command,
    required void Function(String line, String stream) onLog,
    int waitSeconds = 300,
  }) async {
    final vmUri = _vmUri(vmName);
    final uri = vmUri.replace(
      scheme: vmUri.scheme == 'https' ? 'wss' : 'ws',
      pathSegments: [...vmUri.pathSegments, 'exec'],
      queryParameters: {'command': command, 'wait': '$waitSeconds'},
    );
    final client = _createIoClient(_config.orchardApiUrl);
    WebSocket? socket;
    final outputSinks = {
      for (final type in ['stdout', 'stderr'])
        type: utf8.decoder.startChunkedConversion(
          const LineSplitter().startChunkedConversion(
            _LogSink((line) => onLog(line, type)),
          ),
        ),
    };

    try {
      socket = await WebSocket.connect(
        uri.toString(),
        headers: _headers,
        customClient: client,
      );
      await for (final data in socket) {
        final message = jsonDecode(
          data is String ? data : utf8.decode(data as List<int>),
        );
        if (message is! Map<String, dynamic>) {
          throw const FormatException('Invalid Orchard exec message.');
        }
        switch (message['type']) {
          case 'stdout' || 'stderr':
            final encoded = message['data'];
            if (encoded is! String) {
              throw const FormatException('Invalid Orchard exec output.');
            }
            outputSinks[message['type']]!.add(base64Decode(encoded));
          case 'exit':
            final exit = message['exit'];
            if (exit is! Map<String, dynamic> || exit['code'] is! int) {
              throw const FormatException('Invalid Orchard exec exit code.');
            }
            return exit['code'] as int;
          case 'error':
            throw StateError(
              'Orchard exec failed ($vmName): ${message['error']}',
            );
        }
      }
      throw StateError('Orchard exec connection closed before exit ($vmName).');
    } finally {
      try {
        for (final sink in outputSinks.values) {
          sink.close();
        }
      } finally {
        try {
          await socket?.close();
        } finally {
          client.close(force: true);
        }
      }
    }
  }

  /// Closes the HTTP client, including an injected client.
  void close() => _httpClient.close();

  Uri _vmUri([String? leaseId]) {
    final baseUri = Uri.parse(_config.orchardApiUrl);
    return baseUri.replace(
      pathSegments: [
        ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
        'v1',
        'vms',
        ?leaseId,
      ],
    );
  }

  static void _checkResponse(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed to $action: HTTP ${response.statusCode} - ${response.body}',
      );
    }
  }

  static http.Client _createHttpClient(String baseUrl) =>
      IOClient(_createIoClient(baseUrl));

  static HttpClient _createIoClient(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    // Local Orchard uses --no-pki; allow its certificate for this endpoint.
    return HttpClient()
      ..badCertificateCallback = (_, host, port) =>
          host == uri.host && port == uri.port;
  }
}

class _LogSink implements Sink<String> {
  _LogSink(this.onLog);

  final void Function(String line) onLog;

  @override
  void add(String line) {
    if (line.isNotEmpty) onLog(line);
  }

  @override
  void close() {}
}
