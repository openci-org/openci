import 'dart:io';

import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageRoot = input.packageRoot;
    final hookDir = Directory(packageRoot.resolve('hook').toFilePath());
    final swiftFiles = hookDir
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.swift'))
        .map((entity) => entity.path)
        .toList();
    if (swiftFiles.isEmpty) {
      throw Exception('No Swift source files found in hook/ directory');
    }

    final entitlements =
        packageRoot.resolve('hook/entitlements.plist').toFilePath();

    // Determine cache output directory
    final outputDir =
        Directory(packageRoot.resolve('.dart_tool/avf_dart').toFilePath());
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
    final helperBinary = '${outputDir.path}/avf_helper';

    // Get macOS SDK path
    final sdkResult = await Process.run('xcrun', ['--show-sdk-path']);
    if (sdkResult.exitCode != 0) {
      throw Exception('Failed to locate macOS SDK: ${sdkResult.stderr}');
    }
    final sdkPath = sdkResult.stdout.toString().trim();

    print('=== Build Hook: Compiling avf_helper ===');
    final compileResult = await Process.run('swiftc', [
      '-O',
      '-sdk',
      sdkPath,
      ...swiftFiles,
      '-o',
      helperBinary,
    ]);

    if (compileResult.exitCode != 0) {
      throw Exception('Compilation failed: ${compileResult.stderr}');
    }

    print('=== Build Hook: Signing avf_helper ===');
    final signResult = await Process.run('codesign', [
      '--entitlements',
      entitlements,
      '-s',
      '-',
      helperBinary,
    ]);

    if (signResult.exitCode != 0) {
      throw Exception('Signing failed: ${signResult.stderr}');
    }

    print('=== Build Hook: avf_helper successfully built at $helperBinary ===');
  });
}
