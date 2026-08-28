import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class CliConfig {
  final String _filePath;

  CliConfig({String? customFilePath})
    : _filePath = customFilePath ?? _defaultConfigPath();

  static String _defaultConfigPath() {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return p.join(home, '.genuineci', 'config.json');
  }

  Map<String, dynamic> _readSync() {
    final file = File(_filePath);
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
    final file = File(_filePath);
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
