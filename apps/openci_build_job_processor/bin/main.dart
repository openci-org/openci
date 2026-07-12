import 'dart:io';

Future<void> main() async {
  final serverUrl = Platform.environment['OPENCI_SERVER_URL'];
  if (serverUrl == null || serverUrl.isEmpty) {
    throw StateError('OPENCI_SERVER_URL environment variable is required.');
  }

  final runsOnPattern = Platform.environment['OPENCI_RUNS_ON_PATTERN'];
  if (runsOnPattern == null || runsOnPattern.isEmpty) {
    throw StateError(
      'OPENCI_RUNS_ON_PATTERN environment variable is required.',
    );
  }

  final baseVmName = Platform.environment['LUME_BASE_VM_NAME'];
  if (baseVmName == null || baseVmName.isEmpty) {
    throw StateError('LUME_BASE_VM_NAME environment variable is required.');
  }

  final lumeServerUrlsStr = Platform.environment['LUME_SERVER_URLS'];
  if (lumeServerUrlsStr == null || lumeServerUrlsStr.isEmpty) {
    throw StateError('LUME_SERVER_URLS environment variable is required.');
  }

  final lumeServerUrls = lumeServerUrlsStr
      .split(',')
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();

  if (lumeServerUrls.isEmpty) {
    throw StateError('LUME_SERVER_URLS must contain at least one URL.');
  }
}
