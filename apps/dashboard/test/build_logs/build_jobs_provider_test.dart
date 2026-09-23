import 'dart:async';
import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/connections/active_connection_api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late FakeFirebaseUser user;
  late FakeFirebaseAuth auth;
  late List<http.Request> requests;
  final job = BuildJob(
    id: 'job-1',
    status: BuildJobStatus.QUEUED,
    owner: 'openci-org',
    repo: 'openci',
    workflowName: 'CI',
    workflowFileName: 'ci.dart',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final provider = buildJobByIdProvider(job.id);

  setUp(() {
    user = FakeFirebaseUser();
    auth = FakeFirebaseAuth(user);
    requests = [];
  });

  Future<ProviderContainer> createContainer(
    Future<http.Response> Function(http.Request) respond, {
    Future<void>? apiReady,
  }) async {
    final httpClient = MockClient((request) async {
      requests.add(request);
      return respond(request);
    });
    addTearDown(httpClient.close);
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWith((ref) async => auth),
        activeConnectionApiClientProvider.overrideWith(
          (ref) => http.runWithClient(
            () async {
              if (apiReady != null) await apiReady;
              final client = createOpenCIChopperClient(
                baseUrl: 'https://api.openci.test',
                tokenProvider: () => auth.currentUser.getIdToken(),
              );
              ref.onDispose(client.dispose);
              return client;
            },
            () => httpClient,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(authStateChangesProvider, (_, _) {});
    await container.read(authStateChangesProvider.future);
    container.listen(provider, (_, _) {});
    return container;
  }

  http.Response jobResponse(BuildJob value) => http.Response(
    jsonEncode(value.toJson()),
    200,
    headers: {'content-type': 'application/json'},
  );

  testWidgets('waits for API initialization before fetching the build job', (
    tester,
  ) async {
    final ready = Completer<void>();
    final container = await createContainer(
      (_) async => jobResponse(job),
      apiReady: ready.future,
    );
    await tester.pump();
    expect(container.read(provider).isLoading, isTrue);
    expect(requests, isEmpty);

    ready.complete();
    await tester.pump();
    expect(container.read(provider).requireValue, job);
    expect(
      requests.single.url.toString(),
      'https://api.openci.test/builds/job-1',
    );
    expect(requests.single.headers['Authorization'], 'Bearer initial-token');
    container.dispose();
    await tester.pump();
  });

  testWidgets('polls with the current token and recovers from HTTP failures', (
    tester,
  ) async {
    var currentJob = job;
    var offline = false;
    final container = await createContainer((_) async {
      if (offline) throw http.ClientException('Connection unavailable');
      return jobResponse(currentJob);
    });

    expect(await container.read(provider.future), job);
    expect(requests.single.url.path, '/builds/job-1');

    user.token = 'renewed-token';
    currentJob = job.copyWith(status: BuildJobStatus.IN_PROGRESS);
    await tester.pump(const Duration(seconds: 5));
    expect(container.read(provider).value, currentJob);
    expect(requests.last.headers['Authorization'], 'Bearer renewed-token');

    offline = true;
    await tester.pump(const Duration(seconds: 5));
    expect(container.read(provider).value, currentJob);
    expect(auth.currentUser, same(user));

    offline = false;
    user.token = 'next-token';
    currentJob = job.copyWith(status: BuildJobStatus.SUCCESS);
    await tester.pump(const Duration(seconds: 5));
    expect(container.read(provider).value, currentJob);
    expect(requests, hasLength(4));
    expect(requests.last.headers['Authorization'], 'Bearer next-token');
    container.dispose();
    await tester.pump();
  });
}

class FakeFirebaseUser extends Fake implements User {
  String token = 'initial-token';

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => token;
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  FakeFirebaseAuth(this.currentUser);

  @override
  final User currentUser;

  @override
  Stream<User?> authStateChanges() => Stream.value(currentUser);
}
