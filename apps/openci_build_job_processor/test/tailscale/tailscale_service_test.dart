import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:test/test.dart';

void main() {
  group('TailscaleService', () {
    test('should fetch active macOS IPs', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.tailscale.com/api/v2/tailnet/my-tailnet/devices',
        );
        expect(
          request.headers['Authorization'],
          'Basic ${base64Encode(utf8.encode('my-api-key:'))}',
        );

        final responsePayload = {
          'devices': [
            {
              'os': 'macos',
              'connectedToControl': true,
              'addresses': ['100.66.12.37', 'fd7a:115c:a1e0::8b39:c25'],
            },
            {
              'os': 'macos',
              'connectedToControl': false,
              'addresses': ['100.112.30.120'],
            },
            {
              'os': 'linux',
              'connectedToControl': true,
              'addresses': ['100.83.142.124'],
            },
          ],
        };

        return http.Response(jsonEncode(responsePayload), 200);
      });

      final service = TailscaleService(
        apiKey: 'my-api-key',
        tailnet: 'my-tailnet',
        client: mockClient,
      );

      final ips = await service.getActiveMacOsIps();
      expect(ips, ['100.66.12.37']);
    });

    test('should throw HttpException on error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final service = TailscaleService(
        apiKey: 'invalid-key',
        tailnet: 'my-tailnet',
        client: mockClient,
      );

      expect(() => service.getActiveMacOsIps(), throwsException);
    });
  });
}
