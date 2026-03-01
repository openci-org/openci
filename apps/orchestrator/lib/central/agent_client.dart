import 'dart:convert';

import 'package:http/http.dart' as http;

class AgentClient {
  final String agentId;
  final String baseUrl;
  final http.Client _client;

  AgentClient({required this.agentId, required this.baseUrl})
    : _client = http.Client();

  Future<Map<String, dynamic>> health() async {
    final response = await _client.get(Uri.parse('$baseUrl/health'));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listVMs() async {
    final response = await _client.get(Uri.parse('$baseUrl/vms'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['vms'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createVM() async {
    final response = await _client.post(Uri.parse('$baseUrl/vms'));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getVM(String vmId) async {
    final response = await _client.get(Uri.parse('$baseUrl/vms/$vmId'));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> execCommand(String vmId, String command) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/vms/$vmId/exec'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'command': command}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteVM(String vmId) async {
    final response = await _client.delete(Uri.parse('$baseUrl/vms/$vmId'));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}
