import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pub_updater/pub_updater.dart';

import '../i18n/i18n.dart';
import '../version.dart';

typedef UpdateProcessStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      required bool runInShell,
      required ProcessStartMode mode,
    });

class CliUpdater {
  static const packageName = 'genuineci_cli';

  final String currentVersion;
  final http.Client Function() _clientFactory;
  final UpdateProcessStarter _processStarter;

  CliUpdater({
    this.currentVersion = genuineCIVersion,
    @visibleForTesting http.Client Function()? clientFactory,
    @visibleForTesting UpdateProcessStarter processStarter = Process.start,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _processStarter = processStarter;

  Future<String?> getLatestUpdate({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final client = _clientFactory();
    try {
      final latest = Version.parse(
        await PubUpdater(client).getLatestVersion(packageName).timeout(timeout),
      );
      if (latest.isPreRelease || latest <= Version.parse(currentVersion)) {
        return null;
      }
      return latest.toString();
    } finally {
      client.close();
    }
  }

  Future<int> install(String version, Logger logger) async {
    logger.stdout(t.update.updating(version: version));
    try {
      // Keep the dart install location used by our installation instructions.
      // PubUpdater.update uses the separate pub global activation location.
      // Look up Dart on PATH: resolvedExecutable is genuineci in an AOT build.
      final process = await _processStarter(
        'dart',
        ['install', packageName, version],
        runInShell: Platform.isWindows,
        mode: ProcessStartMode.inheritStdio,
      );
      final code = await process.exitCode;
      if (code != 0) {
        logger.stderr(t.update.installFailed);
        return code < 0 ? 128 - code : code;
      }
      logger.stdout(t.update.updated(version: version));
      return 0;
    } on ProcessException {
      logger.stderr(t.update.dartUnavailable);
      return 1;
    }
  }
}
