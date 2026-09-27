class FlutterCI {
  const FlutterCI(this._run);

  final Future<void> Function(String command, {String? workingDirectory}) _run;

  Future<void> staticAnalysis({
    String? dir,
    bool noFatalInfos = false,
    bool noFatalWarnings = false,
  }) => _run(
    [
      'flutter analyze',
      if (noFatalInfos) '--no-fatal-infos',
      if (noFatalWarnings) '--no-fatal-warnings',
    ].join(' '),
    workingDirectory: dir,
  );

  Future<void> unitTests({String? dir}) =>
      _run('flutter test', workingDirectory: dir);
}
