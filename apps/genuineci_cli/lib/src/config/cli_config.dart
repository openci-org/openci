import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'cli_config_data.dart';

export 'cli_config_data.dart';

class CliConfig {
  final String _configFilePath;

  CliConfig({@visibleForTesting String? customFilePath})
    : _configFilePath = customFilePath ?? _defaultConfigFilePath();

  static String _defaultConfigFilePath() {
    const productName = 'genuineci';
    const configFileName = 'config.json';

    final homeDir = applicationConfigHome(productName);
    final configFilePath = p.join(homeDir, configFileName);
    return configFilePath;
  }

  Future<CliConfigData> get() async {
    final file = File(_configFilePath);
    if (!await file.exists()) {
      return const CliConfigData();
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      throw FormatException('Config file at $_configFilePath is empty.');
    }

    final json = jsonDecode(content);
    if (json is! Map<String, dynamic>) {
      throw FormatException(
        'Invalid JSON format in config file at $_configFilePath.',
      );
    }
    return CliConfigData.fromJson(json);
  }

  Future<void> write(CliConfigData data) async {
    final file = File(_configFilePath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(data.toJson()));
  }
}
