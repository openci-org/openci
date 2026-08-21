import 'dart:convert';
import 'dart:io';

import 'package:genuine_ci_cli/src/config/cli_config.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// {@template config_storage}
/// Handles reading and writing Genuine CI CLI configuration files.
/// {@endtemplate}
class ConfigStorage {
  /// {@macro config_storage}
  ConfigStorage({
    String? homeDir,
    String? workingDirectory,
    Map<String, String>? environment,
  }) : _homeDir = homeDir ?? _resolveHomeDir(),
       _workingDirectory = workingDirectory ?? Directory.current.path,
       _environment = environment ?? Platform.environment;

  final String _homeDir;
  final String _workingDirectory;
  final Map<String, String> _environment;

  static String _resolveHomeDir() {
    return Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
  }

  /// The global configuration file located at `~/.genuineci/config.json`.
  File get globalConfigFile {
    final dir = Directory(p.join(_homeDir, '.genuineci'));
    return File(p.join(dir.path, 'config.json'));
  }

  /// The project configuration file located at `genuineci.yaml`
  /// or `.genuineci.yaml` in current working directory.
  File? get projectConfigFile {
    final candidate1 = File(p.join(_workingDirectory, 'genuineci.yaml'));
    if (candidate1.existsSync()) return candidate1;
    final candidate2 = File(p.join(_workingDirectory, '.genuineci.yaml'));
    if (candidate2.existsSync()) return candidate2;
    return null;
  }

  /// Loads global config from `~/.genuineci/config.json`.
  CliConfig loadGlobalConfig() {
    final file = globalConfigFile;
    if (!file.existsSync()) return const CliConfig();
    try {
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CliConfig.fromJson(json);
    } on Exception catch (_) {
      return const CliConfig();
    }
  }

  /// Saves global config to `~/.genuineci/config.json`.
  void saveGlobalConfig(CliConfig config) {
    final file = globalConfigFile;
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(config.toJson()),
    );
  }

  /// Loads project config from `genuineci.yaml` or `.genuineci.yaml`.
  Map<String, dynamic> loadProjectConfig() {
    final file = projectConfigFile;
    if (file == null || !file.existsSync()) return {};
    try {
      final content = file.readAsStringSync();
      final yaml = loadYaml(content);
      if (yaml is Map) {
        return yaml.cast<String, dynamic>();
      }
      return {};
    } on Exception catch (_) {
      return {};
    }
  }

  /// Resolves the final configuration applying precedence:
  /// 1. Explicit CLI arguments (options)
  /// 2. Environment variables (`OPENCI_SERVER_URL`, `OPENCI_TOKEN`,
  ///    `OPENCI_TEAM_ID`)
  /// 3. Project config (`genuineci.yaml`)
  /// 4. Global config (`~/.genuineci/config.json`)
  /// 5. Defaults
  CliConfig resolveConfig({
    String? serverUrlOption,
    String? tokenOption,
    String? teamIdOption,
  }) {
    final globalConfig = loadGlobalConfig();
    final projectConfig = loadProjectConfig();

    final serverUrl =
        serverUrlOption ??
        _environment['OPENCI_SERVER_URL'] ??
        projectConfig['server_url'] as String? ??
        globalConfig.serverUrl;

    final token =
        tokenOption ??
        _environment['OPENCI_TOKEN'] ??
        projectConfig['token'] as String? ??
        globalConfig.token;

    final teamId =
        teamIdOption ??
        _environment['OPENCI_TEAM_ID'] ??
        projectConfig['team_id'] as String? ??
        globalConfig.teamId;

    return CliConfig(
      serverUrl: serverUrl,
      token: token,
      teamId: teamId,
    );
  }
}
