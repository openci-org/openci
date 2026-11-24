import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_cli_plus/src/credential_store/credential_config.dart';
import 'package:openci_cli_plus/src/dataconnect/data_connect_api.dart';
import 'package:test/test.dart';

String _jwtWithAud(String aud) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'aud': aud}))).replaceAll('=', '')}.signature';

void main() {
  final prodToken = _jwtWithAud('openci-b1b91');
  final demoToken = _jwtWithAud('demo-openci');

  test('resolves production endpoint and sends executeQuery payload', () async {
    late http.Request sent;
    final api = DataConnectApi(
      AuthProfile(token: prodToken, authType: 'firebase'),
      client: MockClient((request) async {
        sent = request;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'data': {'message': 'こんにちは'},
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.dispose);

    final data = await api.executeQuery(
      connector: 'logs',
      operationName: 'GetBuildLogs',
      variables: {'teamId': 'team-1', 'runId': 'run-1', 'afterSequence': '0'},
    );

    expect(data, {'message': 'こんにちは'});
    expect(
      sent.url.toString(),
      'https://firebasedataconnect.googleapis.com/v1/projects/openci-b1b91/locations/asia-northeast1/services/openci-b1b91-service/connectors/logs:executeQuery',
    );
    expect(sent.method, 'POST');
    expect(sent.followRedirects, isFalse);
    expect(sent.headers['x-firebase-auth-token'], prodToken);
    expect(jsonDecode(sent.body), {
      'name':
          'projects/openci-b1b91/locations/asia-northeast1/services/openci-b1b91-service/connectors/logs',
      'operationName': 'GetBuildLogs',
      'variables': {'teamId': 'team-1', 'runId': 'run-1', 'afterSequence': '0'},
    });
  });

  test('uses local FSC emulator on port 9399 and demo service ID', () {
    final endpoint = dataConnectQueryEndpoint(
      AuthProfile(
        token: demoToken,
        authType: 'firebase',
        firebaseAuthEmulatorHost: '127.0.0.1:9099',
      ),
      'builds',
    );

    expect(
      endpoint.toString(),
      'http://127.0.0.1:9399/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service/connectors/builds:executeQuery',
    );
  });

  test('rejects non-loopback emulator hosts and non-Firebase tokens', () {
    for (final host in [
      'attacker.test:9399',
      'user:pass@localhost:9399',
      'localhost:9399/path',
      'localhost:9399?x=1',
    ]) {
      expect(
        () => dataConnectQueryEndpoint(
          AuthProfile(token: demoToken, authType: 'firebase'),
          'builds',
          emulatorHost: host,
        ),
        throwsFormatException,
      );
    }

    expect(
      () => dataConnectQueryEndpoint(
        const AuthProfile(token: 'legacy-api-key'),
        'builds',
      ),
      throwsFormatException,
    );
  });

  test('throws DataConnectHttpException on non-200 without leaking body', () {
    final api = DataConnectApi(
      AuthProfile(token: prodToken, authType: 'firebase'),
      client: MockClient(
        (_) async => http.Response('secret internal diagnostic', 403),
      ),
    );
    addTearDown(api.dispose);

    expect(
      () => api.executeQuery(connector: 'builds', operationName: 'GetBuildJob'),
      throwsA(
        isA<DataConnectHttpException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having(
              (e) => e.toString(),
              'toString',
              isNot(contains('secret internal diagnostic')),
            ),
      ),
    );
  });

  test('throws DataConnectGraphQLException when GraphQL errors return', () {
    final api = DataConnectApi(
      AuthProfile(token: prodToken, authType: 'firebase'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'errors': [
              {'message': 'Team access denied'},
            ],
          }),
          200,
        ),
      ),
    );
    addTearDown(api.dispose);

    expect(
      () => api.executeQuery(connector: 'builds', operationName: 'GetBuildJob'),
      throwsA(
        isA<DataConnectGraphQLException>().having(
          (e) => e.messages,
          'messages',
          ['Team access denied'],
        ),
      ),
    );
  });
}
