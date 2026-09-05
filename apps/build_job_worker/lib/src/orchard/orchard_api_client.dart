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

  static http.Client _createHttpClient(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    // Local Orchard uses --no-pki; allow its certificate for this endpoint.
    final client = HttpClient()
      ..badCertificateCallback = (_, host, port) =>
          host == uri.host && port == uri.port;
    return IOClient(client);
  }
}
