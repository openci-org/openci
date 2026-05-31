import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

class AppleVirtualization {
  /// Launches the virtualization helper binary with the given macOS configuration.
  static Future<Process> boot({
    required String diskImgPath,
    required String nvramPath,
    required String hardwareModelB64,
    required String machineIdentifierB64,
  }) async {
    // 1. Resolve packages/avf_dart to locate helper
    final packageUri = Uri.parse('package:avf_dart/avf_dart.dart');
    final resolvedUri = await Isolate.resolvePackageUri(packageUri);
    if (resolvedUri == null) {
      throw StateError('Could not resolve package:avf_dart URI. Ensure the package is properly imported and resolved.');
    }

    // We get the directory containing avf_dart.dart, which is packages/avf_dart/lib
    final libDir = File(resolvedUri.toFilePath()).parent;
    final packageRoot = libDir.parent;
    final helperBinary = '${packageRoot.path}/.dart_tool/avf_dart/avf_helper';

    if (!File(helperBinary).existsSync()) {
      throw StateError(
        'avf_helper binary not found at $helperBinary.\n'
        'Please ensure build hooks have run by running "dart pub get" or "dart test" in the avf_dart directory.'
      );
    }

    // 2. Start VM process using the helper binary with macOS arguments
    final Process process;
    try {
      process = await Process.start(helperBinary, [
        'boot',
        diskImgPath,
        nvramPath,
        hardwareModelB64,
        machineIdentifierB64,
      ]);
    } catch (e) {
      rethrow;
    }

    return process;
  }

  /// Searches for config.json, disk.img, and nvram.bin inside the given [directoryPath],
  /// parses macOS machine metadata, and boots the macOS VM.
  static Future<Process> bootFromDirectory(String directoryPath) async {
    final configFile = File('$directoryPath/config.json');
    if (!configFile.existsSync()) {
      throw FileSystemException('config.json not found in VM directory', configFile.path);
    }

    final configData = jsonDecode(configFile.readAsStringSync());
    if (configData['os'] != 'macOS') {
      throw StateError('Only macOS VMs are supported. Found OS: ${configData['os']}');
    }

    final diskImgPath = '$directoryPath/disk.img';
    final nvramPath = '$directoryPath/nvram.bin';
    final hardwareModelB64 = configData['hardwareModel'] as String?;
    final machineIdentifierB64 = configData['machineIdentifier'] as String?;

    if (hardwareModelB64 == null || machineIdentifierB64 == null) {
      throw StateError('hardwareModel or machineIdentifier missing in config.json');
    }

    if (!File(diskImgPath).existsSync()) {
      throw FileSystemException('Disk image not found', diskImgPath);
    }
    if (!File(nvramPath).existsSync()) {
      throw FileSystemException('NVRAM file not found', nvramPath);
    }

    return boot(
      diskImgPath: diskImgPath,
      nvramPath: nvramPath,
      hardwareModelB64: hardwareModelB64,
      machineIdentifierB64: machineIdentifierB64,
    );
  }

  /// Contacts Apple's servers using the Virtualization framework API to retrieve
  /// the URL for the latest supported macOS restore image (IPSW).
  static Future<Uri> fetchLatestIpswUrl() async {
    final packageUri = Uri.parse('package:avf_dart/avf_dart.dart');
    final resolvedUri = await Isolate.resolvePackageUri(packageUri);
    if (resolvedUri == null) {
      throw StateError('Could not resolve package:avf_dart URI.');
    }
    final libDir = File(resolvedUri.toFilePath()).parent;
    final packageRoot = libDir.parent;
    final helperBinary = '${packageRoot.path}/.dart_tool/avf_dart/avf_helper';

    if (!File(helperBinary).existsSync()) {
      throw StateError('avf_helper binary not found at $helperBinary.');
    }

    final tmpFile = File('${Directory.systemTemp.path}/avf_ipsw_url.txt');
    if (tmpFile.existsSync()) {
      tmpFile.deleteSync();
    }

    final processResult = await Process.run(helperBinary, ['fetch-ipsw-url', tmpFile.path]);
    if (processResult.exitCode != 0) {
      throw StateError('Failed to fetch IPSW URL: ${processResult.stderr}');
    }

    if (!tmpFile.existsSync()) {
      throw StateError('IPSW URL file was not created by helper.');
    }

    final urlStr = tmpFile.readAsStringSync().trim();
    try {
      tmpFile.deleteSync();
    } catch (_) {}

    return Uri.parse(urlStr);
  }

  /// Starts the macOS installation process onto a blank virtual disk.
  /// Standard output of the returned process can be parsed for progress updates.
  static Future<Process> install({
    required String ipswPath,
    required String diskImgPath,
    required String nvramPath,
    required String configJsonPath,
  }) async {
    final packageUri = Uri.parse('package:avf_dart/avf_dart.dart');
    final resolvedUri = await Isolate.resolvePackageUri(packageUri);
    if (resolvedUri == null) {
      throw StateError('Could not resolve package:avf_dart URI.');
    }
    final libDir = File(resolvedUri.toFilePath()).parent;
    final packageRoot = libDir.parent;
    final helperBinary = '${packageRoot.path}/.dart_tool/avf_dart/avf_helper';

    if (!File(helperBinary).existsSync()) {
      throw StateError('avf_helper binary not found at $helperBinary.');
    }

    final process = await Process.start(helperBinary, [
      'install',
      ipswPath,
      diskImgPath,
      nvramPath,
      configJsonPath,
    ]);

    return process;
  }
}
