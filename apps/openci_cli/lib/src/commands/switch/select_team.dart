import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:dart_console/dart_console.dart';
import 'package:meta/meta.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../i18n/i18n.dart';
import '../../terminal/interactive_console.dart';

typedef TeamSelector =
    Future<Team?> Function({
      required List<Team> teams,
      required String currentTeamId,
    });

Future<Team?> selectTeam({
  required List<Team> teams,
  required String currentTeamId,
  @visibleForTesting Console? console,
  @visibleForTesting Stream<Key>? keys,
  @visibleForTesting bool? hasTerminal,
}) async {
  if (teams.isEmpty) return null;
  final interactive = hasTerminal ?? hasInteractiveTerminal;
  if (!interactive) throw const NonInteractiveTerminalException();
  return withInteractiveConsole(
    (terminal, input) async {
      final picker = _TeamPicker(terminal, teams, currentTeamId);
      picker.render();
      await for (final key in input) {
        if (isCancelKey(key)) return null;
        switch (key.controlChar) {
          case ControlCharacter.enter:
          case ControlCharacter.ctrlJ:
            return teams[picker.selected];
          case ControlCharacter.arrowDown:
            picker.selected = (picker.selected + 1) % teams.length;
          case ControlCharacter.arrowUp:
            picker.selected = (picker.selected - 1) % teams.length;
          default:
            continue;
        }
        picker.render();
      }
      return null;
    },
    console: console,
    keys: keys,
    hasTerminal: interactive,
    hideCursor: true,
  );
}

class NonInteractiveTerminalException implements Exception {
  const NonInteractiveTerminalException();
}

class _TeamPicker {
  final Console terminal;
  final List<Team> teams;
  final String currentTeamId;
  int selected;
  int renderedLines = 0;

  _TeamPicker(this.terminal, this.teams, this.currentTeamId)
    : selected = math.max(
        0,
        teams.indexWhere((team) => team.id == currentTeamId),
      );

  void render() {
    final width = math.max(0, terminal.windowWidth - 1);
    final height = math.max(1, terminal.windowHeight);
    final availableRows = math.max(1, height - 1);
    final showPrompt = availableRows >= 3;
    final showControls = availableRows >= 4;
    final showPosition = availableRows >= 3;
    final reserved =
        (showPrompt ? 1 : 0) + (showControls ? 1 : 0) + (showPosition ? 1 : 0);
    final visible = math.max(1, math.min(8, availableRows - reserved));
    final start = (selected ~/ visible) * visible;
    final rows = [
      if (showPrompt)
        '${t.switchCommand.team.prompt} (*: ${t.switchCommand.team.current})',
      if (showControls) t.switchCommand.team.controls,
      for (var i = start; i < math.min(start + visible, teams.length); i++)
        _teamLabel(i, width),
      if (showPosition) '${selected + 1}/${teams.length}',
    ];

    terminal.write('\r');
    final up = math.min(renderedLines - 1, height - 1);
    if (up > 0) terminal.write('\x1b[${up}A');
    terminal.write('\x1b[J');
    terminal.write(rows.map((row) => _takeWidth(row, width)).join('\r\n'));
    renderedLines = rows.length;
  }

  String _teamLabel(int index, int width) {
    final team = teams[index];
    final prefix =
        '${index == selected ? '>' : ' '}'
        '${team.id == currentTeamId ? '*' : ' '} ';
    final name = _escapeControls(team.name);
    final id = _escapeControls(team.id);
    final full = '$prefix$name ($id)';
    if (full.displayWidth <= width) return full;

    // Keep space for both fields, including the suffix of long IDs so teams
    // with the same name remain distinguishable in a narrow terminal.
    final remaining = math.max(0, width - prefix.displayWidth - 3);
    final idWidth = math.min(id.displayWidth, (remaining + 1) ~/ 2);
    final shortId = _ellipsize(id, idWidth, middle: true);
    final shortName = _ellipsize(name, remaining - shortId.displayWidth);
    return '$prefix$shortName ($shortId)';
  }
}

String _escapeControls(String text) => text.replaceAllMapped(
  RegExp(r'[\x00-\x1f\x7f-\x9f]'),
  (match) => '\\x${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}',
);

String _ellipsize(String text, int width, {bool middle = false}) {
  if (width <= 0) return '';
  if (text.displayWidth <= width) return text;
  if (!middle) return '${_takeWidth(text, width - 1)}…';
  final headWidth = (width - 1) ~/ 2;
  final tailWidth = width - 1 - headWidth;
  final tail = _takeWidth(text, tailWidth, fromEnd: true);
  return '${_takeWidth(text, headWidth)}…$tail';
}

String _takeWidth(String text, int width, {bool fromEnd = false}) {
  final chars = text.characters.toList();
  final result = <String>[];
  var used = 0;
  for (final char in fromEnd ? chars.reversed : chars) {
    if (used + char.displayWidth > width) break;
    result.add(char);
    used += char.displayWidth;
  }
  return (fromEnd ? result.reversed : result).join();
}
