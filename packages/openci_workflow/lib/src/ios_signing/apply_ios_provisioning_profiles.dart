import '../flutter/ios_distribution_method.dart';

Future<String> applyIosProvisioningProfiles({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  required IosDistributionMethod distributionMethod,
  String? dir,
}) async {
  const exportOptionsPlistPath = '/tmp/openci-export-options.plist';

  await run(
    [
      'xcode-project use-profiles',
      "--project 'ios/*.xcodeproj'",
      '--archive-method ${distributionMethod.toArchiveMethod()}',
      '--export-options-plist $exportOptionsPlistPath',
    ].join(' '),
    workingDirectory: dir,
  );

  return exportOptionsPlistPath;
}
