import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

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

  Map<String, dynamic> readSync() {
    final file = File(_configFilePath);
    if (!file.existsSync()) {
      return {};
    }
    try {
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void writeSync(Map<String, dynamic> data) {
    final file = File(_configFilePath);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(data)}\n');
  }
}
