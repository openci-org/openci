import 'dart:io';

import 'package:avf_dart/avf_dart.dart';

void main(List<String> args) async {
  if (args.length < 2) {
    print('Error: Missing arguments.');
    print('Usage: dart run example/push.dart <vm-name> <bucket-name>');
    exit(1);
  }
  final vmName = args[0];
  final bucket = args[1];
  try {
    final token = await _getGcloudAccessToken();
    await VirtualMachine.push(
      name: vmName,
      bucket: bucket,
      accessToken: token,
      onLog: (msg) => print(msg),
      onProgress: (progress) {
        stdout.write(
            '\rUploading... ${progress.percent.toStringAsFixed(2)}% (${progress.speedStr}) [Elapsed: ${progress.elapsedStr}, ETA: ${progress.etaStr}]');
      },
    );
    print('\nSuccess: VM pushed successfully.');
  } catch (e) {
    print('Error pushing VM: $e');
  }
}

Future<String> _getGcloudAccessToken() async {
  final result = await Process.run('gcloud', ['auth', 'print-access-token']);
  if (result.exitCode != 0) {
    throw StateError(
        'Failed to retrieve gcloud access token: ${result.stderr}');
  }
  return result.stdout.toString().trim();
}
