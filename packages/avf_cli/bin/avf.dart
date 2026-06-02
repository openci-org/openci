import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:avf_dart/avf_dart.dart';

void main(List<String> args) async {
  final runner = CommandRunner<void>(
    'avf',
    'CLI tool for managing Apple Virtualization.framework macOS VMs.',
  )
    ..addCommand(ListCommand())
    ..addCommand(BootCommand())
    ..addCommand(InstallCommand())
    ..addCommand(DeleteCommand())
    ..addCommand(CloneCommand())
    ..addCommand(PullCommand())
    ..addCommand(PushCommand())
    ..addCommand(DownloadIpswCommand())
    ..addCommand(FetchIpswCommand())
    ..addCommand(VersionCommand());

  try {
    await runner.run(args);
  } catch (error) {
    if (error is UsageException) {
      stderr.writeln(error.message);
      stderr.writeln();
      stderr.writeln(error.usage);
      exit(64);
    }
    stderr.writeln('Error: $error');
    exit(1);
  }
}

class ListCommand extends Command<void> {
  @override
  final name = 'list';
  @override
  final description = 'List all local virtual machines.';

  @override
  void run() async {
    print('Local Virtual Machines:');
    try {
      final list = await VirtualMachine.list();
      if (list.isEmpty) {
        print('  No local VMs found.');
      } else {
        print(
            '  ${"Name".padRight(20)} ${"Disk Size".padRight(24)} ${"Created"}');
        print('  ${"-" * 72}');
        for (final vm in list) {
          final sizeGb =
              (vm.diskSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
          final usedGb =
              (vm.diskSizeUsedBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
          final sizeStr = '$usedGb GB / $sizeGb GB';
          print(
              '  ${vm.name.padRight(20)} ${sizeStr.padRight(24)} ${vm.created.toLocal()}');
        }
      }
    } catch (e) {
      print('Error listing VMs: $e');
      exit(1);
    }
  }
}

class BootCommand extends Command<void> {
  @override
  final name = 'boot';
  @override
  final description = 'Boot a local virtual machine.';

  BootCommand() {
    argParser.addOption(
      'username',
      abbr: 'u',
      defaultsTo: 'admin',
      help: 'Username for SSH verification',
    );
    argParser.addOption(
      'password',
      abbr: 'p',
      defaultsTo: 'admin',
      help: 'Password for SSH verification',
    );
    argParser.addOption(
      'private-key',
      abbr: 'i',
      help: 'SSH private key file path for verification',
    );
    argParser.addOption(
      'run-command',
      abbr: 'c',
      help: 'Optional command to run on VM via SSH after successful boot',
    );
  }

  @override
  void run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      print('Error: Missing VM name.');
      print('Usage: avf boot <vm-name>');
      exit(1);
    }
    final vmName = rest[0];
    final username = argResults?['username'] as String;
    final password = argResults?['password'] as String?;
    final privateKey = argResults?['private-key'] as String?;
    final commandToRun = argResults?['run-command'] as String?;

    try {
      final vm = await VirtualMachine.boot(name: vmName);
      print('VM booted successfully! Guest IP Address: ${vm.ipAddress}');

      if (commandToRun != null) {
        print('Executing command inside VM: $commandToRun');
        final exitStatus = await vm.executeStream(
          commandToRun,
          username: username,
          password: password,
          privateKeyPath: privateKey,
          onStdout: (data) => stdout.write(data),
          onStderr: (data) => stderr.write(data),
        );
        print('Command finished with exit code: $exitStatus');
      }

      print('Waiting for VM process to terminate (Press Ctrl+C to stop)...');
      final code = await vm.exitCode;
      print('VM exited with code: $code');
    } catch (e) {
      print('Error booting VM: $e');
      exit(1);
    }
  }
}

class InstallCommand extends Command<void> {
  @override
  final name = 'install';
  @override
  final description = 'Install macOS onto a new VM using an IPSW file.';

  InstallCommand() {
    argParser.addOption(
      'ipsw',
      abbr: 'i',
      help: 'Path to the IPSW file (required)',
    );
  }

  @override
  void run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      print('Error: Missing VM name.');
      print('Usage: avf install <vm-name> --ipsw <ipsw-path>');
      exit(1);
    }
    final vmName = rest[0];
    final ipswPath = argResults?['ipsw'] as String?;

    if (ipswPath == null || ipswPath.isEmpty) {
      print('Error: --ipsw is required.');
      print('Usage: avf install <vm-name> --ipsw <ipsw-path>');
      exit(1);
    }

    print(
        'Starting macOS installation onto VM "$vmName" using IPSW "$ipswPath"...');
    try {
      await VirtualMachine.install(
        name: vmName,
        ipswPath: ipswPath,
        onProgress: (progress) {
          stdout.write(
              '\rInstalling macOS... ${(progress * 100.0).toStringAsFixed(2)}%');
        },
      );
      print('\nSuccess: macOS installation complete!');
    } catch (e) {
      print('\nError during installation: $e');
      exit(1);
    }
  }
}

class DeleteCommand extends Command<void> {
  @override
  final name = 'delete';
  @override
  final description = 'Delete a local virtual machine.';

  @override
  void run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      print('Error: Missing VM name.');
      print('Usage: avf delete <vm-name>');
      exit(1);
    }
    final vmName = rest[0];

    try {
      await VirtualMachine.delete(vmName);
      print('VM "$vmName" deleted successfully.');
    } catch (e) {
      print('Error deleting VM: $e');
      exit(1);
    }
  }
}

class CloneCommand extends Command<void> {
  @override
  final name = 'clone';
  @override
  final description = 'Clone an existing local virtual machine.';

  @override
  void run() async {
    final rest = argResults?.rest ?? [];
    if (rest.length < 2) {
      print('Error: Missing arguments.');
      print('Usage: avf clone <source-vm> <target-vm>');
      exit(1);
    }
    final source = rest[0];
    final target = rest[1];

    try {
      await VirtualMachine.clone(sourceName: source, targetName: target);
      print('VM cloned successfully from "$source" to "$target".');
    } catch (e) {
      print('Error cloning VM: $e');
      exit(1);
    }
  }
}

class PullCommand extends Command<void> {
  @override
  final name = 'pull';
  @override
  final description = 'Pull a VM archive from GCS bucket.';

  PullCommand() {
    argParser.addOption(
      'bucket',
      abbr: 'b',
      help: 'GCS bucket name (required)',
    );
  }

  @override
  void run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      print('Error: Missing VM name.');
      print('Usage: avf pull <vm-name> --bucket <bucket-name>');
      exit(1);
    }
    final vmName = rest[0];
    final bucket = argResults?['bucket'] as String?;

    if (bucket == null || bucket.isEmpty) {
      print('Error: --bucket is required.');
      print('Usage: avf pull <vm-name> --bucket <bucket-name>');
      exit(1);
    }

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
      print('\nError pulling VM: $e');
      exit(1);
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
}

class PushCommand extends Command<void> {
  @override
  final name = 'push';
  @override
  final description = 'Push a VM archive to GCS bucket.';

  PushCommand() {
    argParser.addOption(
      'bucket',
      abbr: 'b',
      help: 'GCS bucket name (required)',
    );
  }

  @override
  void run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      print('Error: Missing VM name.');
      print('Usage: avf push <vm-name> --bucket <bucket-name>');
      exit(1);
    }
    final vmName = rest[0];
    final bucket = argResults?['bucket'] as String?;

    if (bucket == null || bucket.isEmpty) {
      print('Error: --bucket is required.');
      print('Usage: avf push <vm-name> --bucket <bucket-name>');
      exit(1);
    }

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
      print('\nError pushing VM: $e');
      exit(1);
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
}

class DownloadIpswCommand extends Command<void> {
  @override
  final name = 'download-ipsw';
  @override
  final description = 'Download the macOS IPSW image.';

  DownloadIpswCommand() {
    argParser.addOption(
      'url',
      help: 'Optional IPSW URL (if omitted, fetches the latest from Apple)',
    );
    argParser.addOption(
      'out',
      abbr: 'o',
      help: 'Optional save path (defaults to standard downloads directory)',
    );
  }

  @override
  void run() async {
    final urlStr = argResults?['url'] as String?;
    final outPath = argResults?['out'] as String?;

    try {
      final Uri url;
      if (urlStr != null && urlStr.isNotEmpty) {
        url = Uri.parse(urlStr);
      } else {
        print('Fetching latest supported macOS IPSW URL from Apple...');
        url = await AppleVirtualization.fetchLatestIpswUrl();
      }

      final savePath = outPath ??
          '${VirtualMachine.defaultVmsDir}/../downloads/${url.pathSegments.last}';

      print('Downloading IPSW from $url to $savePath...');
      final metadataFile = File('$savePath.download');
      if (metadataFile.existsSync()) {
        print('Resuming download from previous state...');
      }

      await VirtualMachine.downloadIpsw(
        uri: url,
        savePath: savePath,
        concurrency: 4,
        onProgress: (progress) {
          stdout.write(
            '\rDownloading... ${progress.percent.toStringAsFixed(2)}% (${progress.speedStr}) [Elapsed: ${progress.elapsedStr}, ETA: ${progress.etaStr}]',
          );
        },
      );
      print('\nSuccess: IPSW downloaded successfully to $savePath');
    } catch (e) {
      if (e is StateError &&
          e.message == 'The file is already fully downloaded.') {
        print('\n[Skip] IPSW is already fully downloaded.');
        return;
      }
      print('\nError downloading IPSW: $e');
      exit(1);
    }
  }
}

class FetchIpswCommand extends Command<void> {
  @override
  final name = 'fetch-ipsw';
  @override
  final description = 'Fetch the latest supported macOS IPSW URL from Apple.';

  @override
  void run() async {
    print('Fetching latest supported macOS IPSW URL from Apple...');
    try {
      final url = await AppleVirtualization.fetchLatestIpswUrl();
      print('\nLatest supported IPSW URL:\n$url');
    } catch (e) {
      print('Error fetching IPSW URL: $e');
      exit(1);
    }
  }
}

class VersionCommand extends Command<void> {
  @override
  final name = 'version';
  @override
  final description = 'Print the version of avf_cli.';

  @override
  void run() {
    print('avf_cli version 0.1.5');
  }
}
