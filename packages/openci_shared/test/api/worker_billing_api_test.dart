import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  for (final endpoint in ['start', 'report']) {
    test(
      '$endpoint sends worker identity and preserves acknowledgements',
      () async {
        const payload = {
          'jobId': 'job-1',
          'runId': 'run-1',
          'admissionId': 'admission-1',
          'workerHost': 'worker-1',
        };
        late ChopperClient client;
        client = http.runWithClient(
          () => createOpenCIChopperClient(
            baseUrl: 'https://server.example',
            tokenProvider: () async => 'worker-key',
            services: [OpenCIApiService.create()],
          ),
          () => MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.path, '/worker/billing/$endpoint');
            expect(request.headers['Authorization'], 'Bearer worker-key');
            expect(jsonDecode(request.body), payload);
            return http.Response(
              '{"active":true,"measurementIncomplete":false}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(client.dispose);
        final api = client.getService<OpenCIApiService>();
        final response = await (endpoint == 'start'
            ? api.startBillingExecution(payload)
            : api.reportBillingExecution(payload));
        expect(response.body, {'active': true, 'measurementIncomplete': false});
      },
    );
  }
}
