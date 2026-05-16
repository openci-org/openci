import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'macos_updater_method_channel.dart';

abstract class MacosUpdaterPlatform extends PlatformInterface {
  /// Constructs a MacosUpdaterPlatform.
  MacosUpdaterPlatform() : super(token: _token);

  static final Object _token = Object();

  static MacosUpdaterPlatform _instance = MethodChannelMacosUpdater();

  /// The default instance of [MacosUpdaterPlatform] to use.
  ///
  /// Defaults to [MethodChannelMacosUpdater].
  static MacosUpdaterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MacosUpdaterPlatform] when
  /// they register themselves.
  static set instance(MacosUpdaterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
