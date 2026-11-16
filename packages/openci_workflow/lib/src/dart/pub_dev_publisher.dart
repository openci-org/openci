import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'pub_process.dart';
import 'pub_publish_result.dart';

const _host = 'https://pub.dev';
const _tokenEndpoint = 'https://oauth2.googleapis.com/token';
const _tokenVariable = 'OPENCI_PUB_DEV_ID_TOKEN';

/// Internal publisher with injectable HTTP and process boundaries for tests.
class PubDevPublisher {
  PubDevPublisher({
    http.Client? client,
    PubProcessRunner runProcess = runPubProcess,
    this.executable = 'dart',
    this.requestTimeout = const Duration(seconds: 60),
    this.commandTimeout = const Duration(minutes: 10),
  }) : _client = client ?? http.Client(),
       _runProcess = runProcess;

  final http.Client _client;
  final PubProcessRunner _runProcess;
  final String executable;
  final Duration requestTimeout;
  final Duration commandTimeout;

  Future<PubPublishResult> publish({
    required String workingDirectory,
    required String serviceAccountJsonBase64,
    required bool skipIfPublished,
  }) async {
    Directory? temporary;
    try {
      final directory = await Directory(
        workingDirectory,
      ).resolveSymbolicLinks();
      final package = await _readPackage(directory);
      if (await _exists(package)) {
        if (!skipIfPublished) {
          throw StateError(
            '${package.name} ${package.version} is already published.',
          );
        }
        return PubPublishResult(
          name: package.name,
          version: package.version,
          status: PubPublishStatus.alreadyPublished,
        );
      }

      final token = await _identityToken(serviceAccountJsonBase64);
      temporary = await Directory.systemTemp.createTemp('openci-pub-auth-');
      final temporaryPath = await temporary.resolveSymbolicLinks();
      if (p.isWithin(directory, temporaryPath) ||
          p.equals(directory, temporaryPath)) {
        throw StateError(
          'The temporary authentication directory must be outside the package.',
        );
      }
      final environment = _environment(temporaryPath, token);
      Future<int> run(List<String> arguments) => _runProcess(
        executable,
        arguments,
        workingDirectory: directory,
        environment: environment,
        secrets: [token, serviceAccountJsonBase64],
        timeout: commandTimeout,
      );

      final registration = await run([
        'pub',
        'token',
        'add',
        _host,
        '--env-var',
        _tokenVariable,
      ]);
      if (registration != 0) {
        throw StateError(
          'Could not configure the temporary pub.dev token (exit $registration).',
        );
      }
      // Publish performs its own validation. There is deliberately no dry-run
      // or --skip-validation step. --force accepts warnings without a prompt.
      final exitCode = await run(['pub', 'publish', '--force']);
      if (exitCode != 0) {
        throw StateError(
          'Publishing ${package.name} ${package.version} failed (exit $exitCode). '
          'Check pub.dev before retrying; a lost response may follow an accepted upload.',
        );
      }
      return PubPublishResult(
        name: package.name,
        version: package.version,
        status: PubPublishStatus.published,
      );
    } finally {
      _client.close();
      if (temporary != null) await temporary.delete(recursive: true);
    }
  }

  Future<bool> _exists(_Package package) async {
    final response = await _request(
      http.Request(
        'GET',
        Uri.https(
          'pub.dev',
          '/api/packages/${package.name}/versions/${package.version}',
        ),
      ),
      'version lookup',
    );
    if (response.statusCode == 404) return false;
    if (response.statusCode != 200) {
      throw HttpException(
        'pub.dev version lookup failed (HTTP ${response.statusCode}).',
      );
    }
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final pubspec = data['pubspec'] as Map<String, dynamic>;
      if (data['version'] == package.version &&
          pubspec['name'] == package.name &&
          pubspec['version'] == package.version) {
        return true;
      }
    } catch (_) {
      // Never treat malformed or unrelated metadata as a successful skip.
    }
    throw StateError('pub.dev returned invalid version metadata.');
  }

  Future<String> _identityToken(String encoded) async {
    final String assertion;
    try {
      final data =
          jsonDecode(utf8.decode(base64Decode(encoded)))
              as Map<String, dynamic>;
      final email = data['client_email'] as String;
      if (data['type'] != 'service_account' ||
          !RegExp(
            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.gserviceaccount\.com$',
          ).hasMatch(email) ||
          (data['token_uri'] != null && data['token_uri'] != _tokenEndpoint)) {
        throw const FormatException();
      }
      assertion =
          JWT({
            'iss': email,
            'aud': _tokenEndpoint,
            'target_audience': _host,
          }).sign(
            RSAPrivateKey(data['private_key'] as String),
            algorithm: JWTAlgorithm.RS256,
            expiresIn: const Duration(minutes: 5),
          );
    } catch (_) {
      throw const FormatException(
        'Expected a Base64-encoded Google service account JSON key.',
      );
    }
    final request = http.Request('POST', Uri.parse(_tokenEndpoint))
      ..bodyFields = {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': assertion,
      };
    final response = await _request(request, 'authentication');
    if (response.statusCode != 200) {
      throw HttpException(
        'Google service account authentication failed (HTTP ${response.statusCode}).',
      );
    }
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['id_token'];
      if (token is String &&
          RegExp(
            r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$',
          ).hasMatch(token)) {
        return token;
      }
    } catch (_) {
      // Response bodies may contain credentials; keep diagnostics fixed.
    }
    throw StateError('Google did not return a valid ID token.');
  }

  Future<http.Response> _request(http.Request request, String action) async {
    request.followRedirects = false;
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(requestTimeout);
    } on TimeoutException {
      throw TimeoutException('pub.dev $action timed out.', requestTimeout);
    } catch (_) {
      throw StateError('pub.dev $action request failed.');
    }
  }
}

typedef _Package = ({String name, String version});

Future<_Package> _readPackage(String directory) async {
  final dynamic data;
  try {
    data = loadYaml(
      await File(p.join(directory, 'pubspec.yaml')).readAsString(),
    );
  } catch (_) {
    throw StateError('Could not read the package pubspec.yaml.');
  }
  if (data is! YamlMap) throw const FormatException('Invalid pubspec.yaml.');
  final name = data['name'];
  final version = data['version'];
  if (name is! String || !RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(name)) {
    throw const FormatException(
      'pubspec.yaml must contain a valid package name.',
    );
  }
  try {
    if (version is! String || Version.parse(version).toString() != version) {
      throw const FormatException();
    }
  } catch (_) {
    throw const FormatException(
      'pubspec.yaml must contain a semantic version.',
    );
  }
  final publishTo = data['publish_to'];
  if (publishTo != null && publishTo != _host && publishTo != '$_host/') {
    throw const FormatException(
      'publishToPubDev only accepts packages published to https://pub.dev.',
    );
  }
  return (name: name, version: version);
}

Map<String, String> _environment(String temporaryPath, String token) {
  final parent = Platform.environment;
  final cache =
      parent['PUB_CACHE'] ??
      (Platform.isWindows
          ? p.join(parent['LOCALAPPDATA']!, 'Pub', 'Cache')
          : p.join(parent['HOME']!, '.pub-cache'));
  return {
    // Only these child processes use an isolated home. Preserve the SDK's
    // dependency cache and never modify the user's normal pub credentials.
    'HOME': temporaryPath,
    'APPDATA': temporaryPath,
    'XDG_CONFIG_HOME': temporaryPath,
    'PUB_CACHE': p.absolute(cache),
    'PUB_HOSTED_URL': _host,
    'CI': 'true',
    _tokenVariable: token,
  };
}
