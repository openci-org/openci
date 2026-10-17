import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../config.dart';
import 'calculate_max_concurrent_jobs.dart' show calculateMaxConcurrentJobs;

part 'orchard_api_client.freezed.dart';

@freezed
abstract class OrchardLease with _$OrchardLease {
  const factory OrchardLease({
    required String id,
    required String vmName,
    required String status,
    String? ipAddress,
    int? sshPort,
  }) = _OrchardLease;

  factory OrchardLease.fromJson(Map<String, dynamic> json) {
    return OrchardLease(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      vmName: json['vm_name'] as String? ?? json['vmName'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      ipAddress: json['ip_address'] as String? ?? json['ip'] as String?,
      sshPort: json['ssh_port'] as int? ?? json['sshPort'] as int?,
    );
  }
}

class OrchardApiClient {
  OrchardApiClient({required Config config, http.Client? httpClient})
    : _config = config,
      _httpClient = httpClient ?? _createHttpClient(config.orchardApiUrl);

  final Config _config;
  final http.Client _httpClient;

  int get _defaultCpuCount =>
      int.tryParse(Platform.environment['ORCHARD_VM_CPU'] ?? '') ?? 2;

  int get _defaultMemoryGb =>
      int.tryParse(Platform.environment['ORCHARD_VM_MEMORY_GB'] ?? '') ?? 4;

  Map<String, String> get _headers {
    final credentials =
        '${_config.orchardServiceAccountName}:${_config.orchardServiceAccountToken}';
    return {
      'Authorization': 'Basic ${base64Encode(utf8.encode(credentials))}',
      'Content-Type': 'application/json',
    };
  }

  Future<List<Map<String, dynamic>>> listWorkers({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final response = await _httpClient
        .get(_apiUri('workers'), headers: _headers)
        .timeout(timeout);
    _checkResponse(response, 'list Orchard workers');
    final workers = jsonDecode(response.body);
    if (workers is! List<dynamic> ||
        workers.any((worker) => worker is! Map<String, dynamic>)) {
      throw const FormatException('Orchard workers must be a list of objects.');
    }
    return workers.cast<Map<String, dynamic>>();
  }

  /// Total job capacity using the same VM size defaults as [createLease].
  /// Currently running jobs must be counted by the caller.
  Future<int> getMaxConcurrentJobs({
    int? cpuCount,
    int? memoryGb,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final workers = await listWorkers(timeout: timeout);
    return calculateMaxConcurrentJobs(
      workers: workers,
      cpuCount: cpuCount ?? _defaultCpuCount,
      memoryGb: memoryGb ?? _defaultMemoryGb,
      now: DateTime.now().toUtc(),
    );
  }

  Future<OrchardLease> createLease({
    required String imageName,
    String? vmName,
    int? cpuCount,
    int? memoryGb,
    bool headless = true,
    String os = 'darwin',
  }) async {
    final cpu = cpuCount ?? _defaultCpuCount;
    final memoryMiB = (memoryGb ?? _defaultMemoryGb) * 1024;
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

  Uri _vmUri([String? leaseId]) => _apiUri('vms', leaseId);

  Uri _apiUri(String resource, [String? id]) {
    final baseUri = Uri.parse(_config.orchardApiUrl);
    return baseUri.replace(
      pathSegments: [
        ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
        'v1',
        resource,
        ?id,
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
