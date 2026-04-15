import 'package:dart_functions/github/webhook_event.dart';
import 'package:dart_functions/github/webhook_router.dart';
import 'package:test/test.dart';

WebhookEvent _createEvent(
  String event, {
  String? action,
  String? ref,
  String? refType,
  int? installationId,
}) {
  return WebhookEvent.fromRequest(
    event: event,
    body: {
      'action': ?action,
      'ref': ?ref,
      'ref_type': ?refType,
      'installation': ?switch (installationId) {
        int id => {'id': id},
        _ => null,
      },
      'repository': {
        'full_name': 'org/repo',
        'name': 'repo',
        'default_branch': 'main',
      },
      'sender': {'login': 'testuser'},
    },
  );
}

void main() {
  late List<String> calls;
  late WebhookRouter router;

  setUp(() {
    calls = [];
    router = WebhookRouter(
      onBuildTrigger: (event) async => calls.add('build'),
      onSyncWorkflowFiles: ({
        required String repository,
        required String branch,
        required int installationId,
      }) async =>
          calls.add('sync'),
      onUpdateWorkerCliVersion: (event) async => calls.add('updateCli'),
    );
  });

  group('skip conditions', () {
    test('pull_request closed does nothing', () async {
      await router.route(_createEvent('pull_request', action: 'closed'));
      expect(calls, isEmpty);
    });

    test('push with tag does nothing', () async {
      await router.route(_createEvent('push', ref: 'refs/tags/v1.0.0'));
      expect(calls, isEmpty);
    });

    test('create with branch does nothing', () async {
      await router.route(_createEvent('create', refType: 'branch'));
      expect(calls, isEmpty);
    });

    test('release edited does nothing', () async {
      await router.route(_createEvent('release', action: 'edited'));
      expect(calls, isEmpty);
    });

    test('issue_comment edited does nothing', () async {
      await router.route(_createEvent('issue_comment', action: 'edited'));
      expect(calls, isEmpty);
    });

    test('unknown event does nothing', () async {
      await router.route(_createEvent('ping'));
      expect(calls, isEmpty);
    });
  });

  group('trigger conditions', () {
    test('pull_request opened triggers build', () async {
      await router.route(
        _createEvent('pull_request', action: 'opened', installationId: 1),
      );
      expect(calls, ['build']);
    });

    test('pull_request synchronize triggers build', () async {
      await router.route(
        _createEvent('pull_request', action: 'synchronize', installationId: 1),
      );
      expect(calls, ['build']);
    });

    test('push to branch triggers build and sync', () async {
      await router.route(
        _createEvent('push', ref: 'refs/heads/main', installationId: 1),
      );
      expect(calls, ['build', 'sync']);
    });

    test('create tag triggers build', () async {
      await router.route(
        _createEvent('create', refType: 'tag', ref: 'v1.0.0'),
      );
      expect(calls, ['build']);
    });

    test('release published triggers build and updateCli', () async {
      await router.route(
        _createEvent('release', action: 'published'),
      );
      expect(calls, ['build', 'updateCli']);
    });
  });
}
