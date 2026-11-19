import 'dart:convert';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Firebase Functions CD',
    flutterVersion: '3.47.8',
    ciTriggers: [CITrigger.push(branch: 'develop')],
  );

  final context = ci.context;
  if (context is! PushContext ||
      context.branch != 'develop' ||
      context.repository.owner != 'openci-org' ||
      context.repository.name != 'openci' ||
      context.repository.githubBaseUrl.toString() != 'https://github.com') {
    throw StateError('Functions CD requires an OpenCI develop push.');
  }

  final package =
      jsonDecode(await File('package.json').readAsString())
          as Map<String, dynamic>;
  final npmVersion = package['packageManager'] as String;
  if (!RegExp(r'^npm@\d+\.\d+\.\d+$').hasMatch(npmVersion)) {
    throw StateError('Functions CD requires a pinned npm version.');
  }
  final tools =
      'bash openci/tool/with_node.sh npm exec --yes --package=$npmVersion --';

  await ci.run('$tools npm ci --workspace firebase --include-workspace-root');
  await ci.run(
    '$tools npm run fmt:check --workspace firebase -- healthcheck.ts functions scripts',
  );
  await ci.run('$tools npm run check --workspace firebase');
  await ci.run('$tools npm test --workspace firebase');
  await ci.run('$tools npm run test:workflow-context --workspace firebase');
  final planner = WorkspacePaths.root.firebase.dartFunctions;
  await ci.dart.analyze(dir: planner, fatalInfos: true);
  await ci.dart.test(dir: planner);
  await ci.run(
    '$tools node firebase/scripts/deploy-functions.mjs',
  );
}
