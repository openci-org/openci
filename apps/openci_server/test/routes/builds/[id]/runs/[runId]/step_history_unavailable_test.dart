import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:test/test.dart';

import '../../../../../../routes/builds/[id]/runs/[runId]/steps/[stepId]/logs.dart'
    as logs;
import '../../../../../../routes/builds/[id]/runs/[runId]/steps/index.dart'
    as steps;
import '../../../../../../routes/builds/[id]/runs/[runId]/stream.dart'
    as stream;

void main() {
  for (final (method, path, handler)
      in <(HttpMethod, String, FutureOr<Response> Function(RequestContext))>[
        (
          HttpMethod.get,
          '/builds/job/runs/run/steps',
          (context) => steps.onRequest(context, 'job', 'run'),
        ),
        (
          HttpMethod.post,
          '/builds/job/runs/run/steps',
          (context) => steps.onRequest(context, 'job', 'run'),
        ),
        (
          HttpMethod.get,
          '/builds/job/runs/run/steps/step/logs',
          (context) => logs.onRequest(context, 'job', 'run', 'step'),
        ),
        (
          HttpMethod.get,
          '/builds/job/runs/run/stream',
          (context) => stream.onRequest(context, 'job', 'run'),
        ),
      ]) {
    test(
      '$method $path explicitly reports unavailable functionality',
      () async {
        final context = TestRequestContext(path: path, method: method);
        final response = await handler(context.context);

        expect(response.statusCode, HttpStatus.notImplemented);
        expect(await response.json(), containsPair('success', false));
      },
    );
  }
}
