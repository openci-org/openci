import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:openci_cli/src/commands/switch/select_team.dart';
import 'package:openci_cli/src/i18n/i18n.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

class _Console implements Console {
  final output = StringBuffer();
  final frames = <String>[];
  bool _nextIsFrame = false;
  bool failRendering = false;
  void Function()? onFrame;

  @override
  bool rawMode = false;

  @override
  int windowWidth = 100;

  @override
  int windowHeight = 24;

  @override
  void write(Object text) {
    if (_nextIsFrame) {
      _nextIsFrame = false;
      if (failRendering) throw StateError('render failed');
      frames.add(text.toString());
      onFrame?.call();
    }
    output.write(text);
    if (text == '\x1b[J') _nextIsFrame = true;
  }

  @override
  void writeLine([
    Object? text,
    TextAlignment alignment = TextAlignment.left,
  ]) => output.writeln(text ?? '');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Team _team(String id, String name) => Team(
  id: id,
  name: name,
  members: const [],
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  final teams = [
    _team('team-a', 'Alpha'),
    _team('team-b', '日本語のチーム'),
    _team('team-c', 'Alpha'),
  ];
  late _Console console;
  late AppLocale originalLocale;

  setUp(() {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    console = _Console();
  });

  tearDown(() => LocaleSettings.setLocaleSync(originalLocale));

  Future<Team?> pick(
    List<Key> keys, {
    List<Team>? candidates,
    String currentTeamId = 'team-b',
    bool hasTerminal = true,
  }) => selectTeam(
    teams: candidates ?? teams,
    currentTeamId: currentTeamId,
    console: console,
    keys: Stream.fromIterable(keys),
    hasTerminal: hasTerminal,
  );

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    test(
      'shows names, IDs and the highlighted current team: $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);

        expect(
          await pick([Key.control(ControlCharacter.enter)]),
          same(teams[1]),
        );

        final frame = console.frames.single;
        expect(frame, contains(t.switchCommand.team.prompt));
        expect(frame, contains(t.switchCommand.team.current));
        expect(frame, contains(t.switchCommand.team.controls));
        expect(frame, contains('>* 日本語のチーム (team-b)'));
        expect(frame, contains('   Alpha (team-a)'));
        expect(frame, contains('   Alpha (team-c)'));
        expect(frame, contains('2/3'));
        expect(console.output.toString(), endsWith('\x1b[?25h\n'));
        expect(console.rawMode, isFalse);
      },
    );
  }

  for (final currentId in ['', 'missing-team']) {
    test('highlights the first team when "$currentId" is absent', () async {
      expect(
        await pick([
          Key.control(ControlCharacter.enter),
        ], currentTeamId: currentId),
        same(teams.first),
      );
      expect(console.frames.single, contains('>  Alpha (team-a)'));
      expect(console.frames.single, isNot(contains('>*')));
    });
  }

  test('moves with arrows and wraps in both directions', () async {
    expect(
      await pick([
        Key.control(ControlCharacter.arrowUp),
        Key.control(ControlCharacter.arrowUp),
        Key.control(ControlCharacter.arrowDown),
        Key.control(ControlCharacter.arrowDown),
        Key.control(ControlCharacter.enter),
      ], currentTeamId: 'team-a'),
      same(teams.first),
    );
    final highlighted = console.frames.map(
      (frame) =>
          frame.split('\r\n').singleWhere((line) => line.startsWith('>')),
    );
    expect(highlighted, [
      '>* Alpha (team-a)',
      '>  Alpha (team-c)',
      '>  日本語のチーム (team-b)',
      '>  Alpha (team-c)',
      '>* Alpha (team-a)',
    ]);
  });

  test('ignores other keys and accepts line-feed Enter', () async {
    expect(
      await pick([
        Key.printable('x'),
        Key.control(ControlCharacter.tab),
        Key.control(ControlCharacter.arrowDown),
        Key.control(ControlCharacter.ctrlJ),
      ]),
      same(teams.last),
    );
    expect(console.frames, hasLength(2));
  });

  test('waits for confirmation even with one team', () async {
    final input = StreamController<Key>();
    var completed = false;
    final result = selectTeam(
      teams: [teams.first],
      currentTeamId: teams.first.id,
      console: console,
      keys: input.stream,
      hasTerminal: true,
    )..then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    input.add(Key.control(ControlCharacter.arrowDown));
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    expect(console.frames.last, contains('>* Alpha (team-a)'));

    input.add(Key.control(ControlCharacter.enter));
    expect(await result, same(teams.first));
    await input.close();
  });

  for (final cancel in [
    ControlCharacter.escape,
    ControlCharacter.ctrlC,
    ControlCharacter.ctrlD,
  ]) {
    for (final wasRaw in [false, true]) {
      test('cancels with $cancel and restores raw=$wasRaw', () async {
        console.rawMode = wasRaw;

        expect(
          await pick([
            Key.control(ControlCharacter.arrowDown),
            Key.control(cancel),
            Key.control(ControlCharacter.enter),
          ]),
          isNull,
        );
        expect(console.rawMode, wasRaw);
        expect(console.output.toString(), endsWith('\x1b[?25h\n'));
      });
    }
  }

  test(
    'end of input cancels instead of confirming the highlighted team',
    () async {
      expect(await pick([Key.control(ControlCharacter.arrowDown)]), isNull);
      expect(console.rawMode, isFalse);
      expect(console.output.toString(), endsWith('\x1b[?25h\n'));
    },
  );

  test(
    'non-interactive and empty inputs do not touch the console or keys',
    () async {
      var subscribed = false;
      final input = StreamController<Key>.broadcast(
        onListen: () => subscribed = true,
      );
      for (final (candidates, hasTerminal) in [
        (teams, false),
        (<Team>[], true),
      ]) {
        expect(
          await selectTeam(
            teams: candidates,
            currentTeamId: teams.first.id,
            console: console,
            keys: input.stream,
            hasTerminal: hasTerminal,
          ),
          isNull,
        );
      }
      expect(subscribed, isFalse);
      expect(console.output.toString(), isEmpty);
      await input.close();
    },
  );

  test(
    'escapes API control characters without changing the selected ID',
    () async {
      final team = _team('id\x1b[2J\n\t\x7f\x9b', 'Name\r\x00\x1b[?25l');
      console.windowWidth = 160;

      expect(
        await pick(
          [Key.control(ControlCharacter.enter)],
          candidates: [team],
          currentTeamId: team.id,
        ),
        same(team),
      );
      final frame = console.frames.single;
      expect(frame, contains(r'Name\x0d\x00\x1b[?25l'));
      expect(frame, contains(r'(id\x1b[2J\x0a\x09\x7f\x9b)'));
      expect(
        frame,
        isNot(matches(RegExp(r'[\x00-\x09\x0b\x0c\x0e-\x1f\x7f-\x9f]'))),
      );
    },
  );

  test(
    'truncates long duplicate labels while retaining distinct ID suffixes',
    () async {
      console.windowWidth = 31;
      final candidates = [
        _team('shared-long-id-1111', '同じ長いチーム名が続くチーム'),
        _team('shared-long-id-2222', '同じ長いチーム名が続くチーム'),
      ];

      expect(
        await pick(
          [Key.control(ControlCharacter.enter)],
          candidates: candidates,
          currentTeamId: '',
        ),
        same(candidates.first),
      );
      final rows = console.frames.single.split('\r\n');
      expect(rows.any((row) => row.contains('1111)')), isTrue);
      expect(rows.any((row) => row.contains('2222)')), isTrue);
      expect(
        rows.where((row) => row.contains('…')).length,
        greaterThanOrEqualTo(2),
      );
      expect(rows.every((row) => row.displayWidth <= 30), isTrue);
    },
  );

  test(
    'paginates many teams and keeps the highlighted current team visible',
    () async {
      final candidates = List.generate(40, (i) => _team('id-$i', 'Team $i'));
      console.windowHeight = 7;

      expect(
        await pick(
          [
            Key.control(ControlCharacter.arrowDown),
            Key.control(ControlCharacter.arrowDown),
            Key.control(ControlCharacter.enter),
          ],
          candidates: candidates,
          currentTeamId: 'id-29',
        ),
        same(candidates[31]),
      );
      expect(console.frames.first, contains('>* Team 29 (id-29)'));
      expect(console.frames.first, contains('30/40'));
      expect(console.frames.last, contains('>  Team 31 (id-31)'));
      expect(console.frames.last, contains('32/40'));
      for (final frame in console.frames) {
        expect(frame.split('\r\n'), hasLength(6));
      }
    },
  );

  for (final (width, height) in [
    (80, 24),
    (24, 7),
    (8, 3),
    (4, 2),
    (1, 1),
    (0, 0),
  ]) {
    test('fits Unicode labels within a $width x $height terminal', () async {
      console.windowWidth = width;
      console.windowHeight = height;
      final candidates = List.generate(
        20,
        (i) => _team('同じID-prefix-$i', '日本語 e\u0301 👨‍👩‍👧‍👦 🔑 チーム $i'),
      );

      expect(
        await pick(
          [
            Key.control(ControlCharacter.arrowDown),
            Key.control(ControlCharacter.enter),
          ],
          candidates: candidates,
          currentTeamId: candidates[15].id,
        ),
        same(candidates[16]),
      );
      for (final frame in console.frames) {
        final rows = frame.split('\r\n');
        expect(rows.length, lessThanOrEqualTo(height > 1 ? height - 1 : 1));
        for (final row in rows) {
          expect(
            row.displayWidth,
            lessThanOrEqualTo(width > 0 ? width - 1 : 0),
          );
          expect(row, isNot(endsWith('\u200d')));
        }
      }
    });
  }

  test(
    'adapts after terminal resize without moving above the viewport',
    () async {
      final candidates = List.generate(20, (i) => _team('id-$i', 'Team $i'));
      console.onFrame = () {
        console.windowWidth = 20;
        console.windowHeight = 3;
      };

      expect(
        await pick(
          [
            Key.control(ControlCharacter.arrowDown),
            Key.control(ControlCharacter.enter),
          ],
          candidates: candidates,
          currentTeamId: 'id-10',
        ),
        same(candidates[11]),
      );
      final rows = console.frames.last.split('\r\n');
      expect(rows, hasLength(2));
      expect(rows.last, contains('>  Team 11 (id-11)'));
      expect(rows.every((row) => row.displayWidth <= 19), isTrue);
      expect(console.output.toString(), contains('\x1b[2A'));
      expect(console.output.toString(), isNot(contains('\x1b[10A')));
    },
  );

  test('restores modes and cursor when the input stream fails', () async {
    var cancelled = false;
    final input = StreamController<Key>(
      onListen: () => console.rawMode = true,
      onCancel: () {
        cancelled = true;
        console.rawMode = false;
      },
    );
    console.rawMode = true;
    final result = selectTeam(
      teams: teams,
      currentTeamId: teams.first.id,
      console: console,
      keys: input.stream,
      hasTerminal: true,
    );
    final assertion = expectLater(result, throwsStateError);
    input.addError(StateError('input failed'));

    await assertion;
    expect(cancelled, isTrue);
    expect(console.rawMode, isTrue);
    expect(console.output.toString(), endsWith('\x1b[?25h\n'));
    await input.close();
  });

  test(
    'cancels input and restores the cursor if the first render fails',
    () async {
      var cancelled = false;
      final input = StreamController<Key>(onCancel: () => cancelled = true);
      console.failRendering = true;

      await expectLater(
        selectTeam(
          teams: teams,
          currentTeamId: teams.first.id,
          console: console,
          keys: input.stream,
          hasTerminal: true,
        ),
        throwsStateError,
      );
      expect(cancelled, isTrue);
      expect(console.rawMode, isFalse);
      expect(console.output.toString(), endsWith('\x1b[?25h\n'));
      await input.close();
    },
  );
}
