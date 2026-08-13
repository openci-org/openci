import 'dart:io';

import 'command_runner.dart';

class Workspace {
  Workspace._(this.path);

  final String path;

  static Future<Workspace> create() async {
    final directory = await Directory.systemTemp.createTemp('genuine_ci_');
    return Workspace._(directory.path);
  }

  Future<void> checkout({
    required String url,
    required String branch,
  }) async {
    stdout.writeln('[INFO] workspace: $path');
    await runCommand(
      'git clone --branch $branch --single-branch --progress $url .',
      workingDirectory: path,
    );
  }

  String resolve([String? relativeCwd]) {
    if (relativeCwd == null || relativeCwd.isEmpty) return path;
    return '$path${Platform.pathSeparator}$relativeCwd';
  }
}
