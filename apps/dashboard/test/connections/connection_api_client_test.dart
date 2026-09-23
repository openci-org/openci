import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:dashboard/connections/connection_api_client.dart';
import 'package:dashboard/connections/connection_firebase_auth.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';

class _User extends Fake implements User {
  _User(this.token);
  String token;
  Object? error;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (error != null) throw error!;
    return token;
  }
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.currentUser);

  @override
  User? currentUser;
}

class _HttpClient extends MockClient {
  _HttpClient(super.fn);
  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

ConnectionProfile profile(String id) => ConnectionProfile(
  id: id,
  name: id,
  apiUrl: 'https://$id.example.com',
  firebase: {
    'web': SelfHostedConfig(
      apiKey: '$id-key',
      appId: '1:123:web:$id',
      projectId: id,
    ),
  },
);

void main() {
  final cloud = profile('cloud');
  final selfHosted = profile('self-hosted');
  late _Auth cloudAuth;
  late _Auth selfHostedAuth;
  late Future<FirebaseAuth> selfHostedAuthResult;
  late ProviderContainer container;
  late List<http.Request> requests;
  late List<_HttpClient> httpClients;

  setUp(() {
    cloudAuth = _Auth(_User('cloud-token'));
    selfHostedAuth = _Auth(_User('self-hosted-token'));
    selfHostedAuthResult = Future.value(selfHostedAuth);
    requests = [];
    httpClients = [];
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        connectionFirebaseAuthProvider(
          cloud.id,
          cloud.firebase['web']!,
        ).overrideWith((ref) => cloudAuth),
        connectionFirebaseAuthProvider(
          selfHosted.id,
          selfHosted.firebase['web']!,
        ).overrideWith((ref) => selfHostedAuthResult),
      ],
    );
  });

  ChopperClient clientFor(ConnectionProfile profile) => http.runWithClient(
    () => container
        .listen(
          connectionApiClientProvider(profile, profile.firebase['web']!),
          (_, _) {},
        )
        .read(),
    () {
      final client = _HttpClient((request) async {
        requests.add(request);
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      httpClients.add(client);
      return client;
    },
  );

  test('each API URL receives only its own profile token', () async {
    final cloudClient = clientFor(cloud);
    final selfHostedClient = clientFor(selfHosted);

    await Future.wait([
      OpenCIApiService.create(cloudClient).getTeams(),
      OpenCIApiService.create(selfHostedClient).getTeams(),
    ]);

    expect(requests, hasLength(2));
    expect(
      {
        for (final request in requests)
          request.url.toString(): request.headers['Authorization'],
      },
      {
        'https://cloud.example.com/teams': 'Bearer cloud-token',
        'https://self-hosted.example.com/teams': 'Bearer self-hosted-token',
      },
    );
  });

  test('reads the current user and token on every request', () async {
    final api = OpenCIApiService.create(clientFor(selfHosted));
    await api.getTeams();

    (selfHostedAuth.currentUser! as _User).token = 'renewed-token';
    await api.getTeams();
    selfHostedAuth.currentUser = null;
    await api.getTeams();
    selfHostedAuth.currentUser = _User('new-user-token');
    await api.getTeams();

    expect(requests.map((request) => request.headers['Authorization']), [
      'Bearer self-hosted-token',
      'Bearer renewed-token',
      null,
      'Bearer new-user-token',
    ]);
  });

  test('changing the API URL retains the profile authentication', () async {
    final original = clientFor(selfHosted);
    final updated = clientFor(
      selfHosted.copyWith(apiUrl: 'https://updated.example.com'),
    );

    expect(updated, isNot(same(original)));
    await OpenCIApiService.create(original).getTeams();
    await OpenCIApiService.create(updated).getTeams();

    expect(requests.map((request) => request.url.host), [
      'self-hosted.example.com',
      'updated.example.com',
    ]);
    expect(
      requests.map((request) => request.headers['Authorization']),
      everyElement('Bearer self-hosted-token'),
    );
  });

  test('waits for profile authentication before sending', () async {
    final ready = Completer<FirebaseAuth>();
    selfHostedAuthResult = ready.future;
    final api = OpenCIApiService.create(clientFor(selfHosted));
    final response = api.getTeams();
    await Future<void>.delayed(Duration.zero);
    expect(requests, isEmpty);

    ready.complete(selfHostedAuth);
    await response;
    expect(
      requests.single.headers['Authorization'],
      'Bearer self-hosted-token',
    );
  });

  test('token errors prevent the request from being sent', () async {
    final error = StateError('Token refresh failed');
    (selfHostedAuth.currentUser! as _User).error = error;
    final api = OpenCIApiService.create(clientFor(selfHosted));

    await expectLater(api.getTeams(), throwsA(same(error)));
    expect(requests, isEmpty);
  });

  test('disposes the HTTP clients with their providers', () {
    clientFor(cloud);
    clientFor(selfHosted);
    container.dispose();

    expect(httpClients, hasLength(2));
    expect(httpClients.every((client) => client.closed), isTrue);
  });
}
