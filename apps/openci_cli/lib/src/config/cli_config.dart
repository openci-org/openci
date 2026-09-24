import 'package:meta/meta.dart';

import '../json_file_store/json_file_store.dart';
import 'cli_config_data.dart';

export 'cli_config_data.dart';

class CliConfig {
  final JsonFileStore<CliConfigData> _store;

  CliConfig({@visibleForTesting String? customFilePath})
    : _store = JsonFileStore<CliConfigData>(
        filePath: customFilePath ?? JsonFileStore.defaultPath('config.json'),
        fromJson: CliConfigData.fromJson,
        toJson: (data) => data.toJson(),
      );

  String get filePath => _store.filePath;

  Future<CliConfigData> get() async {
    return (await _store.get()) ?? const CliConfigData();
  }

  Future<void> set(CliConfigData data) async {
    await _store.set(data);
  }
}
