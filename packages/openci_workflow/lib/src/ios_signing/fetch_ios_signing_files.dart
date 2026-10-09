import '../flutter/ios_distribution_method.dart';
import '../quote_shell_argument.dart';
import 'ios_signing_credentials.dart';

Future<void> fetchIosSigningFiles({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  required IosSigningCredentials credentials,
  required String bundleId,
  required IosDistributionMethod distributionMethod,
  String? dir,
}) async {
  final profileType = switch (distributionMethod) {
    IosDistributionMethod.adHoc => 'IOS_APP_ADHOC',
  };

  await run(
    [
      'app-store-connect fetch-signing-files',
      quoteShellArgument(bundleId),
      '--issuer-id ${quoteShellArgument(credentials.issuerId)}',
      '--key-id ${quoteShellArgument(credentials.keyId)}',
      '--private-key ${quoteShellArgument('@file:${credentials.ascPrivateKeyPath}')}',
      '--certificate-key ${quoteShellArgument('@file:${credentials.certificatePrivateKeyPath}')}',
      '--type $profileType',
      '--create',
    ].join(' '),
    workingDirectory: dir,
  );
}
