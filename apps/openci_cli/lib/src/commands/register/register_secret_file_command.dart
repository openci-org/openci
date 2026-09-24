import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../credential_store/credential_store.dart';
import '../../i18n/i18n.dart';
import 'secret_name_for_file.dart';
import 'secret_registration.dart';
import 'select_secret_file.dart';

class RegisterSecretFileCommand extends Command<int> {
  @override
  final String name = 'secretFile';

  @override
  String get description => t.register.secretFile.description;

  final Logger _logger;
  final SecretRegistration _registration;
  final Future<String?> Function() _selectFile;

  RegisterSecretFileCommand({
    required Logger logger,
    CredentialStore? credentialStore,
    @visibleForTesting Future<String?> Function() selectFile = selectSecretFile,
  }) : _logger = logger,
       _registration = SecretRegistration(
         logger: logger,
         credentialStore: credentialStore,
       ),
       _selectFile = selectFile;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.register.secretFile.noArguments);
    }
    final profile = await _registration.readProfile();
    if (profile == null) return 1;

    final String? filePath;
    try {
      filePath = await _selectFile();
    } catch (_) {
      _logger.stderr(t.register.secretFile.inputFailed);
      return 1;
    }
    if (filePath == null || filePath.isEmpty) {
      _logger.stderr(t.register.secretFile.cancelled);
      return 1;
    }

    final List<int> bytes;
    try {
      if (await FileSystemEntity.type(filePath) != FileSystemEntityType.file) {
        _logger.stderr(t.register.secretFile.readFailed);
        return 1;
      }
      bytes = await File(filePath).readAsBytes();
    } catch (_) {
      _logger.stderr(t.register.secretFile.readFailed);
      return 1;
    }
    if (bytes.isEmpty) {
      _logger.stderr(t.register.secretFile.emptyFile);
      return 1;
    }

    return _registration.save(
      profile,
      secretNameForFile(filePath),
      base64Encode(bytes),
    );
  }
}
