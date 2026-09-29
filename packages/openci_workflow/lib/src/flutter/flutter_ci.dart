class FlutterCI {
  const FlutterCI(this._run);

  final Future<void> Function(String command, {String? workingDirectory}) _run;

  Future<void> staticAnalysis({
    String? dir,
    // See https://github.com/dart-lang/tools/issues/249
    bool suppressAnalytics = true,
    bool fatalInfo = false,
    bool noFatalInfos = false,
    bool noFatalWarnings = false,
  }) => _run(
    [
      'flutter analyze',
      if (suppressAnalytics) '--suppress-analytics',
      if (fatalInfo) '--fatal-infos',
      if (noFatalInfos) '--no-fatal-infos',
      if (noFatalWarnings) '--no-fatal-warnings',
    ].join(' '),
    workingDirectory: dir,
  );

  Future<void> unitTests({String? dir}) =>
      _run('flutter test', workingDirectory: dir);

  Future<void> buildApk({String? dir}) =>
      _run('flutter build apk', workingDirectory: dir);
}
