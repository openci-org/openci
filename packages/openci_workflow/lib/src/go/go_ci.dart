/// Go commands using the toolchain already available on the build machine.
class GoCI {
  const GoCI(this._run);

  final Future<void> Function(String command, {String? workingDirectory}) _run;

  Future<void> format({String? dir}) =>
      _run('go fmt ./...', workingDirectory: dir);

  Future<void> vet({String? dir}) =>
      _run('go vet ./...', workingDirectory: dir);

  Future<void> test({String? dir}) =>
      _run('go test -v ./...', workingDirectory: dir);
}
