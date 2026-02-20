import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis/secretmanager/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';

const _ascApiBaseUrl = 'https://api.appstoreconnect.apple.com/v1';

// ══════════════════════════════════════════════════════════════
// CLI Parser
// ══════════════════════════════════════════════════════════════

ArgParser iosSignParser() {
  return ArgParser()
    ..addOption(
      'bundle-id',
      help: 'iOS Bundle Identifier (e.g. com.example.app)',
      mandatory: true,
    )
    ..addOption(
      'apple-team-id',
      help: 'Apple Developer Team ID',
      mandatory: true,
    )
    ..addOption('scheme', help: 'Xcode scheme name', mandatory: true)
    ..addOption(
      'workspace',
      help: 'Path to .xcworkspace (relative to working directory)',
      mandatory: true,
    )
    ..addOption(
      'xcodeproj',
      help: 'Path to .xcodeproj (relative to working directory)',
      mandatory: true,
    )
    ..addOption(
      'working-directory',
      help: 'Working directory for the build',
      defaultsTo: '.',
    )
    ..addFlag(
      'upload-to-testflight',
      help: 'Upload the IPA to TestFlight after export',
      defaultsTo: false,
      negatable: false,
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
}

// ══════════════════════════════════════════════════════════════
// Main Command
// ══════════════════════════════════════════════════════════════

Future<void> runIosSign(ArgResults args) async {
  if (args['help'] as bool) {
    print('''
Usage: openci ios-sign [options]

Required environment variables:
  ASC_KEY_ID                          App Store Connect API Key ID
  ASC_ISSUER_ID                       App Store Connect Issuer ID
  ASC_PRIVATE_KEY                     App Store Connect API Private Key (PEM)

Optional environment variables (certificate caching):
  OPENCI_DISTRIBUTION_CERTIFICATE_P12        Base64-encoded .p12 certificate
  OPENCI_DISTRIBUTION_CERTIFICATE_ID         ASC certificate ID
  OPENCI_DISTRIBUTION_CERTIFICATE_PASSWORD   .p12 password (default: openci)

Options:
${iosSignParser().usage}
''');
    return;
  }

  final bundleId = args['bundle-id'] as String;
  final appleTeamId = args['apple-team-id'] as String;
  final scheme = args['scheme'] as String;
  final workspacePath = args['workspace'] as String;
  final xcodeProjectPath = args['xcodeproj'] as String;
  final workingDirectory = args['working-directory'] as String;
  final uploadToTestflight = args['upload-to-testflight'] as bool;

  // Create build log file
  final resolvedDir = workingDirectory == '.'
      ? Directory.current.path
      : workingDirectory;
  final buildDir = Directory('$resolvedDir/build');
  if (!buildDir.existsSync()) {
    buildDir.createSync(recursive: true);
  }
  final logTimestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(RegExp(r'[:.]'), '-')
      .substring(0, 19);
  _logFile = File('${buildDir.path}/openci_ios_sign_$logTimestamp.log');
  _logFile!.writeAsStringSync('');

  _log('🚀 OpenCI iOS Sign & Build');
  _log('   Bundle ID: $bundleId');
  _log('   Apple Team ID: $appleTeamId');
  _log('   Scheme: $scheme');
  _log('   Workspace: $workspacePath');
  _log('   Xcode Project: $xcodeProjectPath');
  _log('   Log file: ${_logFile!.path}');
  _log('');

  // ──────────────────────────────────────────────────────────
  // Read ASC credentials from environment
  // ──────────────────────────────────────────────────────────
  final ascKeyId = _requireEnv('ASC_KEY_ID');
  final ascIssuerId = _requireEnv('ASC_ISSUER_ID');
  final ascPrivateKey = _requireEnv('ASC_PRIVATE_KEY');

  // Optional: cached certificate
  final existingP12Base64 =
      Platform.environment['OPENCI_DISTRIBUTION_CERTIFICATE_P12'];
  final existingCertId =
      Platform.environment['OPENCI_DISTRIBUTION_CERTIFICATE_ID'];
  final existingCertPassword =
      Platform.environment['OPENCI_DISTRIBUTION_CERTIFICATE_PASSWORD'] ??
      'openci';

  // ──────────────────────────────────────────────────────────
  // Step 1: Generate ASC JWT
  // ──────────────────────────────────────────────────────────
  _log('🔑 Step 1: Generating App Store Connect JWT...');
  final jwt = await _generateAscJwt(ascKeyId, ascIssuerId, ascPrivateKey);
  _log('  ✅ JWT generated');

  // ──────────────────────────────────────────────────────────
  // Step 2: Handle distribution certificate
  // ──────────────────────────────────────────────────────────
  _log('');
  _log('📜 Step 2: Setting up distribution certificate...');

  String certP12Base64;
  String certPassword;
  String certificateId;
  bool isNewCertificate = false;

  final hasExistingCert =
      existingP12Base64 != null &&
      existingP12Base64.isNotEmpty &&
      existingCertId != null &&
      existingCertId.isNotEmpty;

  if (hasExistingCert) {
    // Validate existing certificate
    final validation = await _validateCertificate(jwt, existingCertId);
    if (validation.valid) {
      _log('  ✅ Using existing valid certificate (ID: $existingCertId)');
      certP12Base64 = existingP12Base64;
      certPassword = existingCertPassword;
      certificateId = existingCertId;
    } else {
      _log('  ⚠️  Certificate expired/revoked, creating new...');
      // Try to delete old certificate
      try {
        await _ascApiRequest(
          jwt,
          '/certificates/$existingCertId',
          method: 'DELETE',
        );
        _log('  🗑️  Deleted old certificate');
      } catch (_) {
        _log('  ℹ️  Old certificate already removed or inaccessible');
      }
      final result = await _createCertificateWithP12(jwt);
      certP12Base64 = result.p12Base64;
      certPassword = result.password;
      certificateId = result.certificateId;
      isNewCertificate = true;
    }
  } else {
    _log('  No existing certificate found, creating new...');
    if (existingP12Base64 == null || existingP12Base64.isEmpty) {
      _log('  ℹ️  OPENCI_DISTRIBUTION_CERTIFICATE_P12 is not set');
    }
    if (existingCertId == null || existingCertId.isEmpty) {
      _log('  ℹ️  OPENCI_DISTRIBUTION_CERTIFICATE_ID is not set');
    }
    final result = await _createCertificateWithP12(jwt);
    certP12Base64 = result.p12Base64;
    certPassword = result.password;
    certificateId = result.certificateId;
    isNewCertificate = true;
  }

  _log('  ✅ Certificate ready (ID: $certificateId)');

  // ──────────────────────────────────────────────────────────
  // Step 3: Create provisioning profile
  // ──────────────────────────────────────────────────────────
  _log('');
  _log('📱 Step 3: Creating provisioning profile...');

  final profile = await _createProvisioningProfile(
    jwt,
    certificateId,
    bundleId,
  );
  final profileBase64 = profile.profileContent;
  final profileUuid = profile.uuid;
  final profileName = profile.name;

  _log('  ✅ Profile created');
  _log('     Name: $profileName');
  _log('     UUID: $profileUuid');

  // ──────────────────────────────────────────────────────────
  // Step 4: Setup temporary keychain
  // ──────────────────────────────────────────────────────────
  _log('');
  _log('🔐 Step 4: Setting up temporary keychain...');

  const keychainName = 'openci-build.keychain';
  const keychainPassword = 'openci_temp_password';

  await _run('security', ['delete-keychain', keychainName], ignoreError: true);
  await _run('security', [
    'create-keychain',
    '-p',
    keychainPassword,
    keychainName,
  ]);
  await _run('security', [
    'unlock-keychain',
    '-p',
    keychainPassword,
    keychainName,
  ]);
  await _run('security', [
    'set-keychain-settings',
    '-t',
    '3600',
    '-u',
    keychainName,
  ]);
  await _run('security', [
    'list-keychains',
    '-d',
    'user',
    '-s',
    keychainName,
    'login.keychain-db',
  ]);

  _log('  ✅ Keychain created');

  // ──────────────────────────────────────────────────────────
  // Step 5: Import .p12 certificate
  // ──────────────────────────────────────────────────────────
  _log('');
  _log('📦 Step 5: Importing certificate...');

  final certFile = File('/tmp/openci_distribution.p12');
  certFile.writeAsBytesSync(base64Decode(certP12Base64));

  await _run('security', [
    'import',
    certFile.path,
    '-k',
    keychainName,
    '-P',
    certPassword,
    '-T',
    '/usr/bin/codesign',
    '-T',
    '/usr/bin/security',
  ]);
  await _run('security', [
    'set-key-partition-list',
    '-S',
    'apple-tool:,apple:,codesign:',
    '-k',
    keychainPassword,
    keychainName,
  ]);

  certFile.deleteSync();
  _log('  ✅ Certificate imported');

  // ──────────────────────────────────────────────────────────
  // Step 6: Install provisioning profile
  // ──────────────────────────────────────────────────────────
  _log('');
  _log('📱 Step 6: Installing provisioning profile...');

  final profileFile = File('/tmp/openci_profile.mobileprovision');
  profileFile.writeAsBytesSync(base64Decode(profileBase64));

  final profileDir = Directory(
    '${Platform.environment['HOME']}/Library/MobileDevice/Provisioning Profiles',
  );
  if (!profileDir.existsSync()) {
    profileDir.createSync(recursive: true);
  }

  // Remove old profiles to prevent Xcode from using stale ones
  for (final file in profileDir.listSync()) {
    if (file is File && file.path.endsWith('.mobileprovision')) {
      try {
        // Read profile and check if it's an OpenCI profile for this bundle ID
        final content = file.readAsStringSync();
        if (content.contains('OpenCI') && content.contains(bundleId)) {
          _log(
            '  🗑️  Removing old local profile: ${file.path.split('/').last}',
          );
          file.deleteSync();
        }
      } catch (_) {}
    }
  }

  final destProfile = File('${profileDir.path}/$profileUuid.mobileprovision');
  profileFile.copySync(destProfile.path);
  profileFile.deleteSync();

  _log('  ✅ Profile installed (UUID: $profileUuid)');

  // ──────────────────────────────────────────────────────────
  // Step 7: Edit xcodeproj for manual signing
  // ──────────────────────────────────────────────────────────
  _log('');
  _log('✏️  Step 7: Configuring Xcode project for manual signing...');

  final resolvedWorkingDir = workingDirectory == '.'
      ? Directory.current.path
      : workingDirectory;
  final pbxprojPath = '$resolvedWorkingDir/$xcodeProjectPath/project.pbxproj';
  final pbxprojFile = File(pbxprojPath);

  if (!pbxprojFile.existsSync()) {
    _error('project.pbxproj not found at $pbxprojPath');
    exit(1);
  }

  var pbxprojContent = pbxprojFile.readAsStringSync();

  // CODE_SIGN_STYLE = Automatic → Manual
  pbxprojContent = pbxprojContent.replaceAll(
    'CODE_SIGN_STYLE = Automatic;',
    'CODE_SIGN_STYLE = Manual;',
  );

  // Set DEVELOPMENT_TEAM
  pbxprojContent = pbxprojContent.replaceAll(
    RegExp(r'DEVELOPMENT_TEAM = [^;]*;'),
    'DEVELOPMENT_TEAM = $appleTeamId;',
  );

  // Set CODE_SIGN_IDENTITY to Apple Distribution
  pbxprojContent = pbxprojContent
      .replaceAll(
        'CODE_SIGN_IDENTITY = "Apple Development";',
        'CODE_SIGN_IDENTITY = "Apple Distribution";',
      )
      .replaceAll(
        'CODE_SIGN_IDENTITY = "iPhone Developer";',
        'CODE_SIGN_IDENTITY = "Apple Distribution";',
      )
      .replaceAll(
        '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";',
        '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";',
      );

  // Add PROVISIONING_PROFILE_SPECIFIER (name) and PROVISIONING_PROFILE (UUID)
  pbxprojContent = pbxprojContent.replaceAll(
    'PRODUCT_BUNDLE_IDENTIFIER = $bundleId;',
    'PRODUCT_BUNDLE_IDENTIFIER = $bundleId;\n'
        '\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "$profileName";\n'
        '\t\t\t\tPROVISIONING_PROFILE = "$profileUuid";',
  );

  pbxprojFile.writeAsStringSync(pbxprojContent);
  _log('  ✅ Xcode project updated for manual signing');

  // ──────────────────────────────────────────────────────────
  // Step 8: Generate ExportOptions.plist
  // ──────────────────────────────────────────────────────────
  _log('');
  _log('📄 Step 8: Generating ExportOptions.plist...');

  final exportOptionsPath = '$resolvedWorkingDir/ExportOptions.plist';
  final destination = uploadToTestflight ? 'upload' : 'export';
  final exportOptionsContent =
      '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>$appleTeamId</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$bundleId</key>
        <string>$profileUuid</string>
    </dict>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>destination</key>
    <string>$destination</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
''';

  File(exportOptionsPath).writeAsStringSync(exportOptionsContent);
  _log('  ✅ ExportOptions.plist generated');

  // ──────────────────────────────────────────────────────────
  // Step 9: Build Archive
  // ──────────────────────────────────────────────────────────
  _log('');
  _log('🔨 Step 9: Building archive...');
  _log('  ⏳ This may take several minutes...');

  final archivePath = '$resolvedWorkingDir/build/$scheme.xcarchive';

  await _run(
    'xcodebuild',
    [
      'archive',
      '-quiet',
      '-workspace',
      '$resolvedWorkingDir/$workspacePath',
      '-scheme',
      scheme,
      '-archivePath',
      archivePath,
      '-destination',
      'generic/platform=iOS',
      'DEVELOPMENT_TEAM=$appleTeamId',
      'CODE_SIGN_STYLE=Manual',
      'CODE_SIGN_IDENTITY=Apple Distribution',
      'PROVISIONING_PROFILE_SPECIFIER=$profileName',
      'PROVISIONING_PROFILE=$profileUuid',
      'SENTRY_DISABLE_AUTO_UPLOAD=true',
    ],
    workingDirectory: resolvedWorkingDir,
    quiet: true,
  );

  _log('  ✅ Archive created: $archivePath');

  // ──────────────────────────────────────────────────────────
  // Step 10: Export IPA (with ASC API key authentication)
  // ──────────────────────────────────────────────────────────
  _log('');
  _log('📤 Step 10: Exporting IPA...');

  // Locate or create ASC API key file for xcodebuild authentication
  // Check working directory first (user may have decoded it in a prior step)
  final existingKeyFile = File('$resolvedWorkingDir/AuthKey_$ascKeyId.p8');
  final File apiKeyFile;
  bool createdApiKeyFile = false;

  if (existingKeyFile.existsSync()) {
    apiKeyFile = existingKeyFile;
    _log('  📝 Using existing AuthKey_$ascKeyId.p8 from working directory');
  } else {
    // Write API key to ~/private_keys/ for xcodebuild
    final apiKeyDir = Directory('${Platform.environment['HOME']}/private_keys');
    if (!apiKeyDir.existsSync()) {
      apiKeyDir.createSync(recursive: true);
    }
    apiKeyFile = File('${apiKeyDir.path}/AuthKey_$ascKeyId.p8');

    // Detect if the key is base64-encoded or raw PEM
    if (ascPrivateKey.contains('-----BEGIN')) {
      apiKeyFile.writeAsStringSync(ascPrivateKey);
    } else {
      // Assume base64-encoded
      apiKeyFile.writeAsBytesSync(base64Decode(ascPrivateKey.trim()));
    }
    createdApiKeyFile = true;
    _log('  📝 ASC API key written for xcodebuild authentication');
  }

  final exportPath = '$resolvedWorkingDir/build';

  await _run(
    'xcodebuild',
    [
      '-exportArchive',
      '-quiet',
      '-archivePath',
      archivePath,
      '-exportPath',
      exportPath,
      '-exportOptionsPlist',
      exportOptionsPath,
      '-allowProvisioningUpdates',
      '-authenticationKeyPath',
      apiKeyFile.path,
      '-authenticationKeyID',
      ascKeyId,
      '-authenticationKeyIssuerID',
      ascIssuerId,
    ],
    workingDirectory: resolvedWorkingDir,
    quiet: true,
  );

  _log('  ✅ IPA exported to: $exportPath');

  // ──────────────────────────────────────────────────────────
  // Cleanup
  // ──────────────────────────────────────────────────────────
  _log('');
  _log('🧹 Cleaning up...');

  await _run('security', [
    'default-keychain',
    '-s',
    'login.keychain-db',
  ], ignoreError: true);
  await _run('security', [
    'list-keychains',
    '-d',
    'user',
    '-s',
    'login.keychain-db',
  ], ignoreError: true);
  await _run('security', ['delete-keychain', keychainName], ignoreError: true);

  // Clean up ASC API key file (only if we created it)
  if (createdApiKeyFile && apiKeyFile.existsSync()) {
    apiKeyFile.deleteSync();
  }

  _log('  ✅ Temporary keychain and API key removed');

  // ──────────────────────────────────────────────────────────
  // Output new certificate info for caching
  // ──────────────────────────────────────────────────────────
  if (isNewCertificate) {
    _log('');
    _log('💾 New certificate created. Saving to Secret Manager...');

    final gcpSaJson = Platform.environment['OPENCI_GCP_SA_JSON'];
    final projectId = Platform.environment['OPENCI_PROJECT_ID'];

    if (gcpSaJson != null &&
        gcpSaJson.isNotEmpty &&
        projectId != null &&
        projectId.isNotEmpty) {
      try {
        await _saveDistributionCertToSecretManager(
          gcpSaJson: gcpSaJson,
          projectId: projectId,
          bundleId: bundleId,
          certP12Base64: certP12Base64,
          certPassword: certPassword,
          certificateId: certificateId,
        );
        _log('  ✅ Certificate saved to Secret Manager automatically');
        _log(
          '     Next run will reuse this certificate via OPENCI_DISTRIBUTION_CERTIFICATE_P12',
        );
      } catch (e) {
        _log('  ⚠️  Failed to save to Secret Manager: $e');
        _log('  📋 Manual fallback - save these as secrets:');
        _log('     OPENCI_DISTRIBUTION_CERTIFICATE_ID=$certificateId');
        _log(
          '     OPENCI_DISTRIBUTION_CERTIFICATE_P12=<base64, ${certP12Base64.length} chars>',
        );
        _log('     OPENCI_DISTRIBUTION_CERTIFICATE_PASSWORD=$certPassword');
      }
    } else {
      _log('  📋 OPENCI_GCP_SA_JSON / OPENCI_PROJECT_ID not set.');
      _log('     Save these manually as secrets:');
      _log('     OPENCI_DISTRIBUTION_CERTIFICATE_ID=$certificateId');
      _log(
        '     OPENCI_DISTRIBUTION_CERTIFICATE_P12=<base64, ${certP12Base64.length} chars>',
      );
      _log('     OPENCI_DISTRIBUTION_CERTIFICATE_PASSWORD=$certPassword');
    }
  }

  _log('');
  _log('🎉 iOS Code Signing & Build complete!');
  _log('   IPA: $exportPath/$scheme.ipa');
}

// ══════════════════════════════════════════════════════════════
// Secret Manager: Save Distribution Certificate
// ══════════════════════════════════════════════════════════════

Future<void> _saveDistributionCertToSecretManager({
  required String gcpSaJson,
  required String projectId,
  required String bundleId,
  required String certP12Base64,
  required String certPassword,
  required String certificateId,
}) async {
  final credentials = ServiceAccountCredentials.fromJson(gcpSaJson);
  final scopes = [SecretManagerApi.cloudPlatformScope];
  final authClient = await clientViaServiceAccount(credentials, scopes);

  try {
    final secretApi = SecretManagerApi(authClient);
    final parent = 'projects/$projectId';

    final sanitized = bundleId.replaceAll('.', '-').replaceAll('_', '-');

    final secretEntries = [
      (
        existingPath: Platform
            .environment['OPENCI_DISTRIBUTION_CERTIFICATE_P12_SECRET_PATH'],
        fallbackId: 'dist-cert-p12-$sanitized',
        value: certP12Base64,
        label: 'OPENCI_DISTRIBUTION_CERTIFICATE_P12',
      ),
      (
        existingPath: Platform
            .environment['OPENCI_DISTRIBUTION_CERTIFICATE_PASSWORD_SECRET_PATH'],
        fallbackId: 'dist-cert-password-$sanitized',
        value: certPassword,
        label: 'OPENCI_DISTRIBUTION_CERTIFICATE_PASSWORD',
      ),
      (
        existingPath: Platform
            .environment['OPENCI_DISTRIBUTION_CERTIFICATE_ID_SECRET_PATH'],
        fallbackId: 'dist-cert-id-$sanitized',
        value: certificateId,
        label: 'OPENCI_DISTRIBUTION_CERTIFICATE_ID',
      ),
    ];

    for (final entry in secretEntries) {
      final String secretName;

      if (entry.existingPath != null && entry.existingPath!.isNotEmpty) {
        secretName = entry.existingPath!;
        _log('  🔄 Updating existing Secret: ${entry.label}');
      } else {
        final secretId = entry.fallbackId;
        secretName = '$parent/secrets/$secretId';

        bool exists = false;
        try {
          await secretApi.projects.secrets.get(secretName);
          exists = true;
        } catch (_) {}

        if (!exists) {
          await secretApi.projects.secrets.create(
            Secret(replication: Replication(automatic: Automatic())),
            parent,
            secretId: secretId,
          );
          _log('  📦 Created new Secret: $secretId');
        } else {
          _log('  🔄 Updating Secret: $secretId');
        }
      }

      await secretApi.projects.secrets.addVersion(
        AddSecretVersionRequest(
          payload: SecretPayload(data: base64Encode(utf8.encode(entry.value))),
        ),
        secretName,
      );
    }

    _log('  ✅ Certificate data saved to Secret Manager');
    _log('     Next run: these values will be injected automatically');
  } finally {
    authClient.close();
  }
}

// ══════════════════════════════════════════════════════════════
// ASC JWT Generation
// ══════════════════════════════════════════════════════════════

Future<String> _generateAscJwt(
  String keyId,
  String issuerId,
  String privateKeyPem,
) async {
  final key = JsonWebKey.fromPem(privateKeyPem, keyId: keyId);

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final claims = {
    'iss': issuerId,
    'iat': now,
    'exp': now + 20 * 60,
    'aud': 'appstoreconnect-v1',
  };

  final builder = JsonWebSignatureBuilder()
    ..jsonContent = claims
    ..addRecipient(key, algorithm: 'ES256');
  final jws = builder.build();
  return jws.toCompactSerialization();
}

// ══════════════════════════════════════════════════════════════
// ASC API Helpers
// ══════════════════════════════════════════════════════════════

Future<Map<String, dynamic>?> _ascApiRequest(
  String jwt,
  String endpoint, {
  String method = 'GET',
  Map<String, dynamic>? body,
}) async {
  final url = Uri.parse('$_ascApiBaseUrl$endpoint');
  final headers = {
    'Authorization': 'Bearer $jwt',
    'Content-Type': 'application/json',
  };

  http.Response response;
  switch (method) {
    case 'GET':
      response = await http.get(url, headers: headers);
    case 'POST':
      response = await http.post(url, headers: headers, body: jsonEncode(body));
    case 'DELETE':
      response = await http.delete(url, headers: headers);
    default:
      throw Exception('Unsupported HTTP method: $method');
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('ASC API error (${response.statusCode}): ${response.body}');
  }

  if (response.body.isEmpty) return null;
  return jsonDecode(response.body) as Map<String, dynamic>;
}

// ══════════════════════════════════════════════════════════════
// Certificate Operations
// ══════════════════════════════════════════════════════════════

class _CertValidation {
  final bool valid;
  final bool expired;
  _CertValidation({required this.valid, required this.expired});
}

Future<_CertValidation> _validateCertificate(String jwt, String certId) async {
  try {
    final response = await _ascApiRequest(jwt, '/certificates/$certId');
    final expirationDate =
        response!['data']['attributes']['expirationDate'] as String;
    final expDate = DateTime.parse(expirationDate);
    if (expDate.isBefore(DateTime.now())) {
      return _CertValidation(valid: false, expired: true);
    }
    return _CertValidation(valid: true, expired: false);
  } catch (_) {
    return _CertValidation(valid: false, expired: false);
  }
}

Future<List<Map<String, dynamic>>> _listDistributionCertificates(
  String jwt,
) async {
  final response = await _ascApiRequest(
    jwt,
    '/certificates?filter[certificateType]=DISTRIBUTION',
  );
  final data = response?['data'] as List? ?? [];
  return data.cast<Map<String, dynamic>>();
}

class _CertificateResult {
  final String certificateId;
  final String p12Base64;
  final String password;
  _CertificateResult(this.certificateId, this.p12Base64, this.password);
}

Future<_CertificateResult> _createCertificateWithP12(String jwt) async {
  final tmpDir = Directory.systemTemp.createTempSync('openci_cert_');
  try {
    final keyPath = '${tmpDir.path}/key.pem';
    final csrPemPath = '${tmpDir.path}/csr.pem';
    final csrDerPath = '${tmpDir.path}/csr.der';
    final certDerPath = '${tmpDir.path}/cert.der';
    final certPemPath = '${tmpDir.path}/cert.pem';
    final p12Path = '${tmpDir.path}/cert.p12';
    const password = 'openci';

    // Generate RSA key and CSR
    _log('  🔧 Generating key pair and CSR...');
    await _run('openssl', [
      'req',
      '-new',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-keyout',
      keyPath,
      '-out',
      csrPemPath,
      '-subj',
      '/CN=OpenCI Distribution/C=JP/O=OpenCI',
    ]);

    // Convert CSR PEM → DER for ASC API
    await _run('openssl', [
      'req',
      '-in',
      csrPemPath,
      '-outform',
      'DER',
      '-out',
      csrDerPath,
    ]);
    final csrDerBytes = File(csrDerPath).readAsBytesSync();
    final csrBase64 = base64Encode(csrDerBytes);

    // Check existing certificate count
    final existingCerts = await _listDistributionCertificates(jwt);
    if (existingCerts.length >= 3) {
      _error(
        'Maximum number of Distribution certificates reached (3). '
        'Revoke an unused certificate from Apple Developer Portal.',
      );
      exit(1);
    }

    // Create certificate via ASC API
    _log('  📤 Creating distribution certificate via ASC API...');
    Map<String, dynamic>? certResponse;
    try {
      certResponse = await _ascApiRequest(
        jwt,
        '/certificates',
        method: 'POST',
        body: {
          'data': {
            'type': 'certificates',
            'attributes': {
              'certificateType': 'DISTRIBUTION',
              'csrContent': csrBase64,
            },
          },
        },
      );
    } catch (e) {
      if (e.toString().contains('409')) {
        _log('  ⚠️  409 Conflict: Distribution certificate limit reached.');
        _log('  🔄 Deleting oldest distribution certificate and retrying...');
        final certs = await _listDistributionCertificates(jwt);
        if (certs.isNotEmpty) {
          final oldest = certs.last;
          final oldestId = oldest['id'] as String;
          final oldestName =
              oldest['attributes']?['name'] as String? ?? oldestId;
          _log('  🗑️  Deleting: $oldestName ($oldestId)');
          await _ascApiRequest(
            jwt,
            '/certificates/$oldestId',
            method: 'DELETE',
          );
          _log('  📤 Retrying certificate creation...');
          certResponse = await _ascApiRequest(
            jwt,
            '/certificates',
            method: 'POST',
            body: {
              'data': {
                'type': 'certificates',
                'attributes': {
                  'certificateType': 'DISTRIBUTION',
                  'csrContent': csrBase64,
                },
              },
            },
          );
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    final certId = certResponse!['data']['id'] as String;
    final certContent =
        certResponse['data']['attributes']['certificateContent'] as String;

    _log('  ✅ Certificate created (ID: $certId)');

    // Write DER certificate to file
    File(certDerPath).writeAsBytesSync(base64Decode(certContent));

    // Convert DER → PEM
    await _run('openssl', [
      'x509',
      '-inform',
      'DER',
      '-in',
      certDerPath,
      '-out',
      certPemPath,
    ]);

    // Create .p12 (private key + certificate)
    // Create .p12 file
    // LibreSSL (macOS default) doesn't support -legacy flag,
    // while OpenSSL 3.x needs it for macOS keychain compatibility.
    // Try without -legacy first (LibreSSL), fall back to with -legacy (OpenSSL 3.x).
    _log('  🔧 Creating .p12 file...');
    try {
      await _run('openssl', [
        'pkcs12',
        '-export',
        '-out',
        p12Path,
        '-inkey',
        keyPath,
        '-in',
        certPemPath,
        '-password',
        'pass:$password',
        '-certpbe',
        'PBE-SHA1-3DES',
        '-keypbe',
        'PBE-SHA1-3DES',
        '-macalg',
        'SHA1',
      ]);
    } catch (_) {
      _log('  ⚠️  Retrying with -legacy flag (OpenSSL 3.x)...');
      await _run('openssl', [
        'pkcs12',
        '-export',
        '-out',
        p12Path,
        '-inkey',
        keyPath,
        '-in',
        certPemPath,
        '-password',
        'pass:$password',
        '-legacy',
        '-certpbe',
        'PBE-SHA1-3DES',
        '-keypbe',
        'PBE-SHA1-3DES',
        '-macalg',
        'SHA1',
      ]);
    }

    final p12Bytes = File(p12Path).readAsBytesSync();
    final p12Base64 = base64Encode(p12Bytes);

    return _CertificateResult(certId, p12Base64, password);
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}

// ══════════════════════════════════════════════════════════════
// Provisioning Profile Operations
// ══════════════════════════════════════════════════════════════

class _ProfileInfo {
  final String id;
  final String name;
  final String profileContent;
  final String uuid;
  _ProfileInfo(this.id, this.name, this.profileContent, this.uuid);
}

Future<String> _getBundleIdResourceId(
  String jwt,
  String bundleIdentifier,
) async {
  final response = await _ascApiRequest(
    jwt,
    '/bundleIds?filter[identifier]=$bundleIdentifier',
  );
  final bundleIds = response?['data'] as List? ?? [];
  if (bundleIds.isEmpty) {
    _error(
      'Bundle ID not found: $bundleIdentifier. '
      'Register it in Apple Developer Portal first.',
    );
    exit(1);
  }
  return bundleIds[0]['id'] as String;
}

Future<void> _deleteStaleProfiles(String jwt, String bundleIdentifier) async {
  final response = await _ascApiRequest(jwt, '/profiles?limit=200');
  final profiles = response?['data'] as List? ?? [];

  for (final profile in profiles) {
    final name = profile['attributes']['name'] as String? ?? '';
    if (name.startsWith('OpenCI ') && name.contains(bundleIdentifier)) {
      _log('  🗑️  Deleting stale profile: $name');
      try {
        await _ascApiRequest(
          jwt,
          '/profiles/${profile['id']}',
          method: 'DELETE',
        );
      } catch (_) {}
    }
  }
}

Future<_ProfileInfo> _createProvisioningProfile(
  String jwt,
  String certificateId,
  String bundleIdentifier,
) async {
  final bundleIdResourceId = await _getBundleIdResourceId(
    jwt,
    bundleIdentifier,
  );

  await _deleteStaleProfiles(jwt, bundleIdentifier);

  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(RegExp(r'[:.]'), '-')
      .substring(0, 19);
  final profileName = 'OpenCI AppStore $bundleIdentifier $timestamp';

  final response = await _ascApiRequest(
    jwt,
    '/profiles',
    method: 'POST',
    body: {
      'data': {
        'type': 'profiles',
        'attributes': {'name': profileName, 'profileType': 'IOS_APP_STORE'},
        'relationships': {
          'bundleId': {
            'data': {'type': 'bundleIds', 'id': bundleIdResourceId},
          },
          'certificates': {
            'data': [
              {'type': 'certificates', 'id': certificateId},
            ],
          },
        },
      },
    },
  );

  return _ProfileInfo(
    response!['data']['id'] as String,
    response['data']['attributes']['name'] as String,
    response['data']['attributes']['profileContent'] as String,
    response['data']['attributes']['uuid'] as String,
  );
}

// ══════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════

File? _logFile;

void _writeToLog(String text) {
  _logFile?.writeAsStringSync(text, mode: FileMode.append);
}

String _requireEnv(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    _error('Required environment variable $name is not set');
    exit(1);
  }
  return value;
}

void _log(String message) {
  stdout.writeln(message);
  _writeToLog('$message\n');
}

void _error(String message) {
  stderr.writeln('❌ $message');
  _writeToLog('❌ $message\n');
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool ignoreError = false,
  bool quiet = false,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: {'LANG': 'en_US.UTF-8'},
  );

  final stdoutStr = result.stdout.toString();
  final stderrStr = result.stderr.toString();

  if (stdoutStr.isNotEmpty) {
    if (quiet) {
      // In quiet mode, only write to log file (don't print to stdout)
      // to avoid flooding the worker CLI -> Firestore pipeline.
      _writeToLog(stdoutStr);
    } else {
      stdout.write(stdoutStr);
      _writeToLog(stdoutStr);
    }
  }

  if (result.exitCode != 0 && !ignoreError) {
    if (stderrStr.isNotEmpty) {
      stderr.write(stderrStr);
      _writeToLog(stderrStr);
    }
    _error('Command failed: $executable ${arguments.join(' ')}');
    exit(result.exitCode);
  } else if (stderrStr.isNotEmpty) {
    // Also capture stderr even on success (warnings etc.)
    _writeToLog('[stderr] $stderrStr');
  }
}
