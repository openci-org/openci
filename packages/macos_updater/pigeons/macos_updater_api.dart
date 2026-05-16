import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'macos_updater',
    dartOut: 'lib/src/macos_updater_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut:
        'macos/macos_updater/Sources/macos_updater/MacosUpdaterApi.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
@HostApi()
abstract class MacosUpdaterHostApi {
  void setFeedUrl(String url);

  void checkForUpdates();

  void setScheduledCheckInterval(int seconds);
}
