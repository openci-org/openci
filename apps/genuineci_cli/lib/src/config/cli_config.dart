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

  Map<String, dynamic> _readSync() {
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

  void _writeSync(Map<String, dynamic> data) {
    final file = File(_configFilePath);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(data)}\n');
  }

  /// Gets the configured language code (e.g. 'ja', 'en') or null.
  String? getLanguage() {
    final data = _readSync();
    return data['language'] as String?;
  }

  /// Sets and saves the language code.
  void setLanguage(String languageCode) {
    final data = _readSync();
    data['language'] = languageCode;
    _writeSync(data);
  }
}
