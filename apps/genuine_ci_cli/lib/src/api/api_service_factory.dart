import 'package:genuine_ci_cli/src/config/cli_config.dart';
import 'package:openci_shared/openci_shared.dart';

/// Factory function signature for creating an [OpenCiApiService].
typedef ApiServiceFactory = OpenCiApiService Function(CliConfig config);

/// Default [ApiServiceFactory] implementation creating Chopper client.
OpenCiApiService defaultApiServiceFactory(CliConfig config) {
  final client = createOpenCiChopperClient(
    baseUrl: config.serverUrl,
    tokenProvider: () => config.token,
    services: [OpenCiApiService.create()],
  );
  return client.getService<OpenCiApiService>();
}
