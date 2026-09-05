import 'dart:convert';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockHttpClient extends Mock implements http.Client {}

const _config = Config(
  serverUrl: 'http://server:8080',
  internalApiKey: 'test-api-key',
  orchardApiUrl: 'https://orchard.example.com:6120/',
  orchardServiceAccountName: 'worker',
  orchardServiceAccountToken: 'orchard-token',
);

void main() {
  group('OrchardApiClient', () {
    test('creates a VM with its image and resource requirements', () async {
      final client = _createClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://orchard.example.com:6120/v1/vms',
        );
        expect(jsonDecode(request.body), {
          'name': 'vm-1',
          'image': 'base-macos',
          'headless': true,
          'os': 'darwin',
          'cpu': 4,
          'memory': 8192,
          'resources': {
            'org.cirruslabs.logical-cores': 4,
            'org.cirruslabs.memory-mib': 8192,
            'org.cirruslabs.tart-vms': 1,
          },
        });
        return http.Response(
          jsonEncode({
            'id': 'lease-1',
            'vm_name': 'vm-1',
            'status': 'pending',
            'ip_address': '100.64.0.1',
            'ssh_port': 22,
          }),
          201,
        );
      });

      final lease = await client.createLease(
        imageName: 'base-macos',
        vmName: 'vm-1',
        cpuCount: 4,
        memoryGb: 8,
      );

      expect(lease.id, 'lease-1');
      expect(lease.vmName, 'vm-1');
      expect(lease.status, 'pending');
      expect(lease.ipAddress, '100.64.0.1');
      expect(lease.sshPort, 22);
    });

    test('gets VM status and accepts the existing response aliases', () async {
      final client = _createClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/vms/lease-1');
        return http.Response(
          jsonEncode({
            'name': 'lease-1',
            'vmName': 'vm-1',
            'status': 'running',
            'ip': '100.64.0.1',
            'sshPort': 2222,
          }),
          200,
        );
      });

      final lease = await client.getLease('lease-1');

      expect(lease.id, 'lease-1');
      expect(lease.vmName, 'vm-1');
      expect(lease.status, 'running');
      expect(lease.ipAddress, '100.64.0.1');
      expect(lease.sshPort, 2222);
    });

    test('deletes a VM and accepts an empty 204 response', () async {
      final client = _createClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/v1/vms/lease-1');
        return http.Response('', 204);
      });

      await client.deleteLease('lease-1');
    });

    test('encodes the lease ID as a single path segment', () async {
      final client = _createClient((request) async {
        expect(request.url.pathSegments, ['v1', 'vms', 'vm /?#1']);
        expect(request.url.hasQuery, isFalse);
        expect(request.url.hasFragment, isFalse);
        return http.Response('', 204);
      });

      await client.deleteLease('vm /?#1');
    });

    final operations = <String, Future<void> Function(OrchardApiClient)>{
      'createLease': (client) => client.createLease(imageName: 'base-macos'),
      'getLease': (client) => client.getLease('lease-1'),
      'deleteLease': (client) => client.deleteLease('lease-1'),
    };
    for (final operation in operations.entries) {
      test('${operation.key} rejects an HTTP failure', () async {
        final client = _createClient(
          (_) async => http.Response('Unauthorized', 401),
        );

        await expectLater(
          operation.value(client),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('HTTP 401 - Unauthorized'),
            ),
          ),
        );
      });
    }

    test('propagates connection failures', () async {
      final error = http.ClientException('Connection failed');
      final client = _createClient((_) async => throw error);

      await expectLater(client.getLease('lease-1'), throwsA(same(error)));
    });

    test('rejects a malformed JSON response', () async {
      final client = _createClient((_) async => http.Response('invalid', 200));

      await expectLater(client.getLease('lease-1'), throwsFormatException);
    });

    test('closes the injected HTTP client', () {
      final httpClient = _MockHttpClient();
      final client = OrchardApiClient(config: _config, httpClient: httpClient);

      client.close();

      verify(() => httpClient.close()).called(1);
    });
  });
}

OrchardApiClient _createClient(MockClientHandler handler) {
  final client = OrchardApiClient(
    config: _config,
    httpClient: MockClient((request) async {
      expect(
        request.headers['authorization'],
        'Basic ${base64Encode(utf8.encode('worker:orchard-token'))}',
      );
      expect(request.headers['content-type'], 'application/json');
      return handler(request);
    }),
  );
  addTearDown(client.close);
  return client;
}
