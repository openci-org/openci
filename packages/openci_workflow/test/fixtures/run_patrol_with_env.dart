import 'package:openci_workflow/openci_workflow.dart';

Future<void> main(List<String> arguments) async {
  final ci = await OpenCI.init(workflowName: 'Patrol fixture', ciTriggers: []);
  await ci.patrol.test(
    device: 'device',
    env: const [
      Secret('PATROL_FIXTURE_EMAIL'),
      Secret('PATROL_FIXTURE_PASSWORD'),
    ],
    additionalArguments: arguments,
  );
}
