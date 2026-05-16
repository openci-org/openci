import 'package:flutter_test/flutter_test.dart';
import 'package:macos_updater/macos_updater.dart';
import 'package:macos_updater/macos_updater_platform_interface.dart';
import 'package:macos_updater/macos_updater_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMacosUpdaterPlatform
    with MockPlatformInterfaceMixin
    implements MacosUpdaterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MacosUpdaterPlatform initialPlatform = MacosUpdaterPlatform.instance;

  test('$MethodChannelMacosUpdater is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMacosUpdater>());
  });

  test('getPlatformVersion', () async {
    MacosUpdater macosUpdaterPlugin = MacosUpdater();
    MockMacosUpdaterPlatform fakePlatform = MockMacosUpdaterPlatform();
    MacosUpdaterPlatform.instance = fakePlatform;

    expect(await macosUpdaterPlugin.getPlatformVersion(), '42');
  });
}
