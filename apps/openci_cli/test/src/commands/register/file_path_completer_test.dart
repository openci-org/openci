import 'dart:io';

import 'package:openci_cli/src/commands/register/file_path_completer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late FilePathCompleter completer;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('openci-file-completion-');
    await Directory(p.join(root.path, 'secrets')).create();
    await File(p.join(root.path, 'config-dev.json')).writeAsString('dev');
    await File(p.join(root.path, 'config-prod.json')).writeAsString('prod');
    await File(p.join(root.path, '.env')).writeAsString('private');
    await File(
      p.join(root.path, 'secrets', 'signing 日本語.p12'),
    ).writeAsBytes([0]);
    completer = FilePathCompleter(
      workingDirectory: root.path,
      homeDirectory: root.path,
    );
  });

  tearDown(() => root.delete(recursive: true));

  test('lists directories first and filters by filename prefix', () {
    expect(completer.complete(''), [
      'secrets${p.separator}',
      'config-dev.json',
      'config-prod.json',
    ]);
    expect(completer.complete('CONFIG-P'), ['config-prod.json']);
    expect(completer.complete('missing'), isEmpty);
  });

  test('shows hidden files when the prefix starts with a dot', () {
    expect(completer.complete('.'), ['.env']);
  });

  test('completes paths with spaces and Unicode without shell escaping', () {
    expect(completer.complete('secrets${p.separator}sig'), [
      p.join('secrets', 'signing 日本語.p12'),
    ]);
    expect(
      completer.resolve(p.join('secrets', 'signing 日本語.p12')),
      p.join(root.path, 'secrets', 'signing 日本語.p12'),
    );
  });

  test('completes absolute paths and home-relative paths', () {
    expect(completer.complete(p.join(root.path, 'config-p')), [
      p.join(root.path, 'config-prod.json'),
    ]);
    expect(completer.complete('~'), ['~${p.separator}']);
    expect(completer.complete('~${p.separator}config-p'), [
      p.join('~', 'config-prod.json'),
    ]);
    expect(completer.resolve('~${p.separator}.env'), p.join(root.path, '.env'));
  });

  test('resolves quoted paths and parent directories', () {
    final path = p.join(root.path, 'secrets', 'signing 日本語.p12');
    expect(completer.resolve('"$path"'), path);
    expect(completer.resolve("'$path'"), path);
    expect(
      completer.resolve(p.join('secrets', '..', '.env')),
      p.join(root.path, '.env'),
    );
  });

  test('follows symlinks to regular files and directories', () async {
    await Link(
      p.join(root.path, 'linked-file'),
    ).create(p.join(root.path, '.env'));
    await Link(
      p.join(root.path, 'linked-dir'),
    ).create(p.join(root.path, 'secrets'));
    expect(completer.complete('linked'), [
      'linked-dir${p.separator}',
      'linked-file',
    ]);
  }, skip: Platform.isWindows);
}
