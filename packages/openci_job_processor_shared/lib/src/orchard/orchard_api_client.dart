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
  }) async {
    final targetName =
        vmName ?? 'openci-vm-${DateTime.now().millisecondsSinceEpoch}';
    final uri = Uri.parse('$baseUrl/v1/vms');
    final payload = <String, dynamic>{'name': targetName, 'image': imageName};
    if (cpuCount != null) payload['cpu'] = cpuCount;
    if (memoryGb != null) payload['memory'] = memoryGb * 1024;

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
}
