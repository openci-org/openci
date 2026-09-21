class FlutterCi {
  const FlutterCi(this._run);

  final Future<void> Function(String command, {String? workingDirectory}) _run;

  Future<void> staticAnalysis({String? dir}) =>
      _run('flutter analyze', workingDirectory: dir);

  Future<void> unitTests({String? dir}) =>
      _run('flutter test', workingDirectory: dir);
}
