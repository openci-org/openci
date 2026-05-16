
import 'macos_updater_platform_interface.dart';

class MacosUpdater {
  Future<String?> getPlatformVersion() {
    return MacosUpdaterPlatform.instance.getPlatformVersion();
  }
}
