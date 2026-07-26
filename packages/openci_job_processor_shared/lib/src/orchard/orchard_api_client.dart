import 'dart:convert';
import 'package:http/http.dart' as http;

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
  }) : _httpClient = httpClient ?? http.Client();

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
    int? cpuCount,
    int? memoryGb,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/leases');
    final payload = <String, dynamic>{'image': imageName};
    if (cpuCount != null) payload['cpus'] = cpuCount;
    if (memoryGb != null) payload['memory_gb'] = memoryGb;

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
        'Failed to create Orchard lease: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<OrchardLease> getLease(String leaseId) async {
    final uri = Uri.parse('$baseUrl/v1/leases/$leaseId');
    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OrchardLease.fromJson(json);
    } else {
      throw Exception(
        'Failed to get Orchard lease ($leaseId): ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> deleteLease(String leaseId) async {
    final uri = Uri.parse('$baseUrl/v1/leases/$leaseId');
    final response = await _httpClient.delete(uri, headers: _headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to delete Orchard lease ($leaseId): ${response.statusCode} ${response.body}',
      );
    }
  }
}
