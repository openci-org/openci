import 'package:flutter_test/flutter_test.dart';
import 'package:macos_updater/macos_updater.dart';
import 'package:macos_updater/src/macos_updater_api.g.dart';

class _FakeMacosUpdaterHostApi extends MacosUpdaterHostApi {
  String? feedUrl;
  bool checkedForUpdates = false;
  int? scheduledCheckIntervalSeconds;

  @override
  Future<void> checkForUpdates() async {
    checkedForUpdates = true;
  }

  @override
  Future<void> setFeedUrl(String url) async {
    feedUrl = url;
  }

  @override
  Future<void> setScheduledCheckInterval(int seconds) async {
    scheduledCheckIntervalSeconds = seconds;
  }
}

void main() {
  test('delegates updater calls to host api', () async {
    final api = _FakeMacosUpdaterHostApi();
    final updater = MacosUpdater(api: api);

    await updater.setFeedUrl('https://example.com/appcast.xml');
    await updater.setScheduledCheckInterval(const Duration(hours: 12));
    await updater.checkForUpdates();

    expect(api.feedUrl, 'https://example.com/appcast.xml');
    expect(api.scheduledCheckIntervalSeconds, 43200);
    expect(api.checkedForUpdates, isTrue);
  });
}
