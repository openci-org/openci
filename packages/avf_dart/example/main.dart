import 'dart:io';

import 'package:avf_dart/avf_dart.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage:');
    print('  dart run example/main.dart boot [<vm-name>]');
    print('  dart run example/main.dart fetch-ipsw');
    print('  dart run example/main.dart download [<save-path>]');
    print('  dart run example/main.dart install <ipsw-path> [<vm-name>]');
    print('  dart run example/main.dart list');
    print('  dart run example/main.dart push <vm-name> <bucket-name>');
    print('  dart run example/main.dart pull <vm-name> <bucket-name>');
    print('\nDefaulting to booting "tahoe-base" if available...');
    await _boot('tahoe-base');
    return;
  }

  final command = args[0];
  switch (command) {
    case 'boot':
      final name = args.length > 1 ? args[1] : 'tahoe-base';
      await _boot(name);
      break;

    case 'fetch-ipsw':
      print('Fetching latest supported macOS IPSW URL from Apple...');
      try {
        final url = await AppleVirtualization.fetchLatestIpswUrl();
        print('\nLatest supported IPSW URL:\n$url');
        print('\nYou can download this IPSW automatically by running:');
        print('  dart run example/main.dart download');
      } catch (e) {
        print('Error fetching IPSW URL: $e');
      }
      break;

    case 'download':
      final hasForce = args.contains('--force') || args.contains('-f');
      final cleanArgs = args.where((arg) => arg != '--force' && arg != '-f').toList();

      print('Fetching latest supported macOS IPSW URL from Apple...');
      try {
        final url = await AppleVirtualization.fetchLatestIpswUrl();
        final savePath = cleanArgs.length > 1
            ? cleanArgs[1]
            : '${VirtualMachine.defaultVmsDir}/../downloads/${url.pathSegments.last}';

        print('Downloading IPSW to $savePath...');
        final metadataFile = File('$savePath.download');
        if (metadataFile.existsSync()) {
          print('Resuming download from previous state...');
        }

        await VirtualMachine.downloadIpsw(
          uri: url,
          savePath: savePath,
          concurrency: 8,
          force: hasForce,
          onProgress: (progress) {
            stdout.write(
                '\rDownloading... ${progress.percent.toStringAsFixed(2)}% (${progress.speedStr}) [Elapsed: ${progress.elapsedStr}, ETA: ${progress.etaStr}]');
          },
        );
        print('\nSuccess: IPSW downloaded successfully to $savePath');
      } catch (e) {
        if (e is StateError && e.message == 'The file is already fully downloaded.') {
          print('\n[Skip] IPSW is already fully downloaded.');
          print('If you want to re-download, please delete the file or run with --force / -f flag.');
          return;
        }
        print('\nError downloading IPSW: $e');
      }
      break;

    case 'install':
      if (args.length < 2) {
        print('Error: Missing IPSW file path.');
        print(
            'Usage: dart run example/main.dart install <ipsw-path> [<vm-name>]');
        exit(1);
      }
      final ipswPath = args[1];
      final name = args.length > 2 ? args[2] : 'tahoe-base';

      print(
          'Starting macOS installation onto VM "$name" using IPSW "$ipswPath"...');
      try {
        await VirtualMachine.install(
          name: name,
          ipswPath: ipswPath,
          onProgress: (progress) {
            stdout.write(
                '\rInstalling macOS... ${(progress * 100.0).toStringAsFixed(2)}%');
          },
        );
        print('\nSuccess: macOS installation complete!');
      } catch (e) {
        print('\nError during installation: $e');
      }
      break;

    case 'list':
      print('Local Virtual Machines:');
      try {
        final list = await VirtualMachine.list();
        if (list.isEmpty) {
          print('  No local VMs found.');
        } else {
          print(
              '  ${"Name".padRight(20)} ${"Disk Size".padRight(12)} ${"Created"}');
          print('  ${"-" * 60}');
          for (final vm in list) {
            final sizeGb =
                (vm.diskSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
            final sizeStr = '$sizeGb GB';
            print(
                '  ${vm.name.padRight(20)} ${sizeStr.padRight(12)} ${vm.created.toLocal()}');
          }
        }
      } catch (e) {
        print('Error listing VMs: $e');
      }
      break;

    case 'push':
      if (args.length < 3) {
        print('Error: Missing arguments.');
        print('Usage: dart run example/main.dart push <vm-name> <bucket-name>');
        exit(1);
      }
      final vmName = args[1];
      final bucket = args[2];
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
      break;

    case 'pull':
      if (args.length < 3) {
        print('Error: Missing arguments.');
        print('Usage: dart run example/main.dart pull <vm-name> <bucket-name>');
        exit(1);
      }
      final vmName = args[1];
      final bucket = args[2];
      try {
        final token = await _getGcloudAccessToken();
        await VirtualMachine.pull(
          name: vmName,
          bucket: bucket,
          accessToken: token,
          onLog: (msg) => print(msg),
          onProgress: (progress) {
            stdout.write(
                '\rDownloading... ${progress.percent.toStringAsFixed(2)}% (${progress.speedStr}) [Elapsed: ${progress.elapsedStr}, ETA: ${progress.etaStr}]');
          },
        );
        print('\nSuccess: VM pulled successfully.');
      } catch (e) {
        print('Error pulling VM: $e');
      }
      break;

    default:
      print('Unknown command: $command');
      exit(1);
  }
}

Future<void> _boot(String name) async {
  try {
    final vm = await VirtualMachine.boot(name: name);
    final code = await vm.exitCode;
    print('VM exited with code: $code');
  } catch (e) {
    print('Failed to boot VM: $e');
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
