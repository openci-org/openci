import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_job_processor_shared/src/orchard/orchard_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('OrchardApiClient', () {
    test('getControllerInfo returns parsed json on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/info'));
        expect(request.headers['Authorization'], startsWith('Basic '));
        return http.Response(
          jsonEncode({'version': '1.0.0', 'status': 'ok'}),
          200,
        );
      });

      final client = OrchardApiClient(
        baseUrl: 'http://localhost:6120',
        serviceAccountName: 'test-user',
        serviceAccountToken: 'test-token',
        httpClient: mockClient,
      );

      final info = await client.getControllerInfo();
      expect(info['version'], equals('1.0.0'));
      expect(info['status'], equals('ok'));
    });

    test('createLease sends request and returns OrchardLease', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/v1/leases'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['image'], equals('macos-sonoma'));

        return http.Response(
          jsonEncode({
            'id': 'lease-123',
            'vm_name': 'orchard-vm-123',
            'ip_address': '192.168.64.2',
            'ssh_port': 22,
            'status': 'running',
          }),
          201,
        );
      });

      final client = OrchardApiClient(
        baseUrl: 'http://localhost:6120',
        serviceAccountName: 'test-user',
        serviceAccountToken: 'test-token',
        httpClient: mockClient,
      );

      final lease = await client.createLease(imageName: 'macos-sonoma');
      expect(lease.id, equals('lease-123'));
      expect(lease.vmName, equals('orchard-vm-123'));
      expect(lease.ipAddress, equals('192.168.64.2'));
      expect(lease.sshPort, equals(22));
      expect(lease.status, equals('running'));
    });

    test('deleteLease sends DELETE request', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('DELETE'));
        expect(request.url.path, equals('/v1/leases/lease-123'));
        return http.Response('', 204);
      });

      final client = OrchardApiClient(
        baseUrl: 'http://localhost:6120',
        serviceAccountName: 'test-user',
        serviceAccountToken: 'test-token',
        httpClient: mockClient,
      );

      await expectLater(client.deleteLease('lease-123'), completes);
    });
  });
}
