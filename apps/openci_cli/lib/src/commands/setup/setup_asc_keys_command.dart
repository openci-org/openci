import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../asc/asc_api_key.dart';
import '../../asc/asc_authentication_status.dart';
import '../../asc/asc_release.dart';
import '../../asc/check_asc_authentication.dart';
import '../../asc/create_asc_api_key.dart';
import '../../asc/find_cached_asc_executable.dart';
import '../../asc/install_asc.dart';
import '../../asc/prepare_asc_key_directory.dart';
import '../../asc/start_asc_login.dart';
import '../../asc/verify_asc_executable.dart';
import '../../i18n/i18n.dart';
import 'confirm_asc_key_creation.dart';
import 'read_apple_id.dart';

class SetupAscKeysCommand extends Command<int> {
  @override
  final String name = 'asc-keys';

  @override
  String get description => t.setup.ascKeys.description;

  final Logger _logger;
  final Future<File?> Function() _findCachedExecutable;
  final Future<File> Function() _installExecutable;
  final Future<void> Function(File) _verifyExecutable;
  final Future<String?> Function() _readAppleId;
  final Future<Process> Function(File, String) _startLogin;
  final Future<AscAuthenticationStatus> Function(File, String)
  _checkAuthentication;
  final Future<bool> Function() _confirmCreation;
  final Future<Directory> Function() _prepareKeyDirectory;
  final Future<AscApiKey> Function(
    File,
    String,
    AscAuthenticationStatus,
    Directory,
  )
  _createKey;

  SetupAscKeysCommand({
    required Logger logger,
    @visibleForTesting
    Future<File?> Function() findCachedExecutable = findCachedAscExecutable,
    @visibleForTesting Future<File> Function() installExecutable = installAsc,
    @visibleForTesting
    Future<void> Function(File) verifyExecutable = verifyAscExecutable,
    @visibleForTesting
    Future<String?> Function() readAppleIdInput = readAppleId,
    @visibleForTesting
    Future<Process> Function(File, String) startLogin = startAscLogin,
    @visibleForTesting
    Future<AscAuthenticationStatus> Function(File, String) checkAuthentication =
        checkAscAuthentication,
    @visibleForTesting
    Future<bool> Function() confirmCreation = confirmAscKeyCreation,
    @visibleForTesting
    Future<Directory> Function() prepareKeyDirectory = prepareAscKeyDirectory,
    @visibleForTesting
    Future<AscApiKey> Function(File, String, AscAuthenticationStatus, Directory)
        createKey =
        createAscApiKey,
  }) : _logger = logger,
       _findCachedExecutable = findCachedExecutable,
       _installExecutable = installExecutable,
       _verifyExecutable = verifyExecutable,
       _readAppleId = readAppleIdInput,
       _startLogin = startLogin,
       _checkAuthentication = checkAuthentication,
       _confirmCreation = confirmCreation,
       _prepareKeyDirectory = prepareKeyDirectory,
       _createKey = createKey;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.setup.ascKeys.noArguments);
    }

    final File executable;
    try {
      final cachedExecutable = await _findCachedExecutable();
      if (cachedExecutable == null) {
        _logger.stdout(t.setup.ascKeys.installing(version: ascVersion));
        executable = await _installExecutable();
        _logger.stdout(
          t.setup.ascKeys.installed(version: ascVersion, path: executable.path),
        );
      } else {
        executable = cachedExecutable;
        _logger.stdout(
          t.setup.ascKeys.cacheFound(
            version: ascVersion,
            path: executable.path,
          ),
        );
      }
      await _verifyExecutable(executable);
      _logger.stdout(t.setup.ascKeys.versionVerified(version: ascVersion));
    } on UnsupportedError {
      _logger.stderr(t.setup.ascKeys.unsupportedPlatform);
      return 1;
    } on AscInstallException catch (error) {
      _logger.stderr(switch (error.failure) {
        AscInstallFailure.download => t.setup.ascKeys.downloadFailed,
        AscInstallFailure.checksum => t.setup.ascKeys.checksumFailed,
        AscInstallFailure.permission => t.setup.ascKeys.permissionFailed,
      });
      return 1;
    } on AscVerificationException catch (error) {
      _logger.stderr(switch (error.failure) {
        AscVerificationFailure.checksum => t.setup.ascKeys.cachedChecksumFailed,
        AscVerificationFailure.execution => t.setup.ascKeys.executionFailed,
        AscVerificationFailure.timeout => t.setup.ascKeys.versionTimedOut,
        AscVerificationFailure.version => t.setup.ascKeys.versionMismatch(
          version: ascVersion,
        ),
      });
      return 1;
    } on FileSystemException {
      _logger.stderr(t.setup.ascKeys.cacheFailed);
      return 1;
    }

    try {
      final appleId = await _readAppleId();
      if (appleId == null) {
        _logger.stderr(t.setup.ascKeys.appleIdRequired);
        return 1;
      }
      _logger.stdout(t.setup.ascKeys.appleIdReceived);

      final process = await _startLogin(executable, appleId);
      final code = await process.exitCode;
      if (code != 0) return code < 0 ? 128 - code : code;

      final status = await _checkAuthentication(executable, appleId);
      if (!status.authenticated) {
        _logger.stderr(t.setup.ascKeys.notAuthenticated);
        return 1;
      }
      _logger.stdout(t.setup.ascKeys.authenticationVerified);
      final providerId = status.providerId;
      final publicProviderId = status.publicProviderId;
      if (providerId == null && publicProviderId == null) {
        _logger.stderr(t.setup.ascKeys.providerUnavailable);
        return 1;
      }
      _logger.stdout(t.setup.ascKeys.selectedProvider);
      if (providerId != null) {
        _logger.stdout(t.setup.ascKeys.providerId(id: providerId));
      }
      if (publicProviderId != null) {
        _logger.stdout(t.setup.ascKeys.publicProviderId(id: publicProviderId));
      }
      if (!await _confirmCreation()) {
        _logger.stdout(t.setup.ascKeys.keyCreationCancelled);
        return 0;
      }

      final directory = await _prepareKeyDirectory();
      // Print the recovery path before the one-time download, even if the
      // process is interrupted before returning its result.
      _logger.stdout(t.setup.ascKeys.keyOutputDirectory(path: directory.path));
      try {
        final key = await _createKey(executable, appleId, status, directory);
        _logger.stdout(t.setup.ascKeys.keyCreated);
        _logger.stdout(t.setup.ascKeys.keyId(id: key.keyId));
        _logger.stdout(t.setup.ascKeys.issuerId(id: key.issuerId));
        _logger.stdout(
          t.setup.ascKeys.privateKeySaved(path: key.privateKeyFile.path),
        );
        _logger.stdout(t.setup.ascKeys.serverStoragePending);
        return 0;
      } on AscApiKeyException catch (error) {
        _logger.stderr(switch (error.failure) {
          AscApiKeyFailure.start => t.setup.ascKeys.keyCreationStartFailed,
          AscApiKeyFailure.execution => t.setup.ascKeys.keyCreationFailed,
          AscApiKeyFailure.response => t.setup.ascKeys.keyCreationInvalid,
          AscApiKeyFailure.storage => t.setup.ascKeys.keyStorageFailed,
        });
        if (error.failure != AscApiKeyFailure.start) {
          _logger.stderr(t.setup.ascKeys.keyRecovery(path: directory.path));
        }
        return 1;
      }
    } on AscKeyConfirmationException {
      _logger.stderr(t.setup.ascKeys.keyConfirmationFailed);
      return 1;
    } on FileSystemException {
      _logger.stderr(t.setup.ascKeys.keyDirectoryFailed);
      return 1;
    } on AppleIdInputException catch (error) {
      _logger.stderr(switch (error.failure) {
        AppleIdInputFailure.notInteractive => t.setup.ascKeys.terminalRequired,
        AppleIdInputFailure.read => t.setup.ascKeys.appleIdInputFailed,
      });
      return 1;
    } on AscAuthenticationException catch (error) {
      _logger.stderr(switch (error.failure) {
        AscAuthenticationFailure.execution => t.setup.ascKeys.authStatusFailed,
        AscAuthenticationFailure.timeout => t.setup.ascKeys.authStatusTimedOut,
        AscAuthenticationFailure.response => t.setup.ascKeys.authStatusInvalid,
      });
      return 1;
    } on ProcessException {
      _logger.stderr(t.setup.ascKeys.loginStartFailed);
      return 1;
    }
  }
}
