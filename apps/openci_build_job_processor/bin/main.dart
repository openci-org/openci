import 'package:openci_build_job_processor/openci_build_job_processor.dart';

Future<void> main() async {
  final config = ProcessorConfig.fromEnvironment();

  await initializeSentry(config.sentryDsn);

  final jobPoller = JobPoller(config: config);
  await jobPoller.startPolling(config.runsOnPattern);
}
