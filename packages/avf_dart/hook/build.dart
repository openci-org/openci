import 'dart:io';

import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageRoot = input.packageRoot;
    final helperSource =
        packageRoot.resolve('hook/avf_helper.m').toFilePath();
    final entitlements =
        packageRoot.resolve('hook/entitlements.plist').toFilePath();

    // Determine cache output directory
    final outputDir =
        Directory(packageRoot.resolve('.dart_tool/avf_dart').toFilePath());
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
    final helperBinary = '${outputDir.path}/avf_helper';

    print('=== Build Hook: Compiling avf_helper ===');
    final compileResult = await Process.run('clang', [
      '-framework',
      'Foundation',
      '-framework',
      'Virtualization',
      '-fobjc-arc',
      helperSource,
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
