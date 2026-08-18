import 'package:build_job_dispatcher/build_job_dispatcher.dart';
import 'package:openci_shared/initialize_sentry.dart';
import 'package:openci_shared/openci_shared.dart';

Future<void> main() async => genuineCiRunZonedGuarded(() async {
  final config = Config.fromEnvironment();

  await initializeSentry(config.sentryDsn);
});
