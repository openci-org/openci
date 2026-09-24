import 'dart:convert';
import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:openci_cli/src/commands/register/file_path_completer.dart';
import 'package:openci_cli/src/commands/register/select_secret_file.dart';
import 'package:openci_cli/src/i18n/i18n.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _Console implements Console {
  final output = StringBuffer();

  @override
  bool rawMode = false;

  @override
  int windowWidth = 64;

  @override
  int windowHeight = 12;

  @override
  void write(Object text) => output.write(text);

  @override
  void writeLine([
    Object? text,
    TextAlignment alignment = TextAlignment.left,
  ]) => output.writeln(text ?? '');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Key> _type(String text) => [
  for (final byte in utf8.encode(text))
    Key.printable(String.fromCharCode(byte)),
];

void main() {
  late Directory root;
  late _Console console;
  late FilePathCompleter completer;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('openci-file-picker-');
    console = _Console();
    completer = FilePathCompleter(
      workingDirectory: root.path,
      homeDirectory: root.path,
    );
    await Directory(p.join(root.path, 'secrets')).create();
    await File(
      p.join(root.path, 'secrets', 'config.json'),
    ).writeAsString('private');
    await File(p.join(root.path, 'config-dev.json')).writeAsString('dev');
    await File(p.join(root.path, 'config-prod.json')).writeAsString('prod');
  });

  tearDown(() => root.delete(recursive: true));

  Future<String?> pick(List<Key> keys, {bool hasTerminal = true}) =>
      selectSecretFile(
        console: console,
        completer: completer,
        keys: Stream.fromIterable(keys),
        hasTerminal: hasTerminal,
      );

  test(
    'completes directories and files without reading their contents',
    () async {
      final result = await pick([
        ..._type('sec'),
        Key.control(ControlCharacter.tab),
        Key.control(ControlCharacter.enter),
        ..._type('con'),
        Key.control(ControlCharacter.tab),
        Key.control(ControlCharacter.enter),
      ]);
      expect(result, p.join(root.path, 'secrets', 'config.json'));
      expect(console.output.toString(), isNot(contains('private')));
      expect(console.rawMode, isFalse);
    },
  );

  test('cycles matching files with Tab and arrow keys', () async {
    expect(
      await pick([
        ..._type('config'),
        Key.control(ControlCharacter.tab),
        Key.control(ControlCharacter.arrowDown),
        Key.control(ControlCharacter.arrowUp),
        Key.control(ControlCharacter.tab),
        Key.control(ControlCharacter.enter),
      ]),
      p.join(root.path, 'config-prod.json'),
    );
  });

  test(
    'decodes UTF-8 input with spaces and supplementary characters',
    () async {
      const name = 'signing 日本語🔑.p12';
      await File(p.join(root.path, name)).writeAsBytes([0, 255]);
      expect(
        await pick([..._type(name), Key.control(ControlCharacter.enter)]),
        p.join(root.path, name),
      );
    },
  );

  test('edits at the cursor and retries a missing path', () async {
    expect(
      await pick([
        ..._type('missing'),
        Key.control(ControlCharacter.enter),
        Key.control(ControlCharacter.ctrlU),
        ..._type('Xconfig-dev.jsonX'),
        Key.control(ControlCharacter.backspace),
        Key.control(ControlCharacter.home),
        Key.control(ControlCharacter.delete),
        Key.control(ControlCharacter.end),
        Key.control(ControlCharacter.enter),
      ]),
      p.join(root.path, 'config-dev.json'),
    );
    // The prompt truncates long messages to fit the terminal width.
    expect(console.output.toString(), contains(t.register.secretFile.notFound));
  });

  test('can navigate to the parent directory', () async {
    completer = FilePathCompleter(
      workingDirectory: p.join(root.path, 'secrets'),
    );
    expect(
      await pick([
        ..._type('..'),
        Key.control(ControlCharacter.enter),
        ..._type('config-p'),
        Key.control(ControlCharacter.tab),
        Key.control(ControlCharacter.enter),
      ]),
      p.join(root.path, 'config-prod.json'),
    );
  });

  test('can enter a quoted directory containing spaces', () async {
    final folder = Directory(p.join(root.path, 'secret files'));
    await folder.create();
    final file = File(p.join(folder.path, 'config.json'));
    await file.writeAsBytes([1]);
    expect(
      await pick([
        ..._type('"secret files"'),
        Key.control(ControlCharacter.enter),
        ..._type('config'),
        Key.control(ControlCharacter.tab),
        Key.control(ControlCharacter.enter),
      ]),
      file.path,
    );
  });

  test(
    'keeps the cursor after a combining character inserted in a path',
    () async {
      const name = 'cafe\u0301X.json';
      await File(p.join(root.path, name)).writeAsBytes([1]);
      expect(
        await pick([
          ..._type('cafe.json'),
          Key.control(ControlCharacter.home),
          for (var i = 0; i < 4; i++) Key.control(ControlCharacter.arrowRight),
          ..._type('\u0301X'),
          Key.control(ControlCharacter.enter),
        ]),
        p.join(root.path, name),
      );
    },
  );

  for (final key in [
    ControlCharacter.escape,
    ControlCharacter.ctrlC,
    ControlCharacter.ctrlD,
  ]) {
    test('cancels on $key and restores terminal mode', () async {
      console.rawMode = true;
      expect(await pick([Key.control(key)]), isNull);
      expect(console.rawMode, isTrue);
    });
  }

  test('returns without prompting when no terminal is available', () async {
    expect(await pick([], hasTerminal: false), isNull);
    expect(console.output.toString(), isEmpty);
  });

  test('restores terminal mode on input failure and EOF', () async {
    console.rawMode = true;
    await expectLater(
      selectSecretFile(
        console: console,
        completer: completer,
        keys: Stream.error(StateError('input failed')),
        hasTerminal: true,
      ),
      throwsStateError,
    );
    expect(console.rawMode, isTrue);
    expect(await pick([]), isNull);
  });

  test('shows completion pages within a narrow terminal', () async {
    console
      ..windowHeight = 7
      ..windowWidth = 24;
    for (var i = 0; i < 10; i++) {
      await File(p.join(root.path, 'candidate-$i.json')).writeAsBytes([1]);
    }
    expect(
      await pick([
        ..._type('candidate'),
        for (var i = 0; i < 8; i++) Key.control(ControlCharacter.tab),
        Key.control(ControlCharacter.enter),
      ]),
      p.join(root.path, 'candidate-7.json'),
    );
    final frames = console.output.toString().split('\x1b[J').skip(1);
    for (final frame in frames) {
      final lines = frame.stripEscapeCharacters().split(RegExp(r'[\r\n]'));
      expect(lines.every((line) => line.displayWidth <= 23), isTrue);
    }
  });

  test(
    'does not emit terminal controls embedded in filenames',
    () async {
      const fileName = 'unsafe\x1b]52;payload.json';
      await File(p.join(root.path, fileName)).writeAsString('private');
      expect(
        await pick([
          ..._type('unsafe'),
          Key.control(ControlCharacter.tab),
          Key.control(ControlCharacter.enter),
        ]),
        p.join(root.path, fileName),
      );
      expect(console.output.toString(), isNot(contains('\x1b]52;')));
    },
    skip: Platform.isWindows,
  );
}
