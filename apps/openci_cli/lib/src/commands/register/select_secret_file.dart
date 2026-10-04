import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../../i18n/i18n.dart';
import '../../terminal/console.dart';
import '../../terminal/interactive_console.dart';
import 'file_path_completer.dart';

Future<String?> selectSecretFile({
  @visibleForTesting Console? console,
  @visibleForTesting FilePathCompleter? completer,
  @visibleForTesting Stream<Key>? keys,
  @visibleForTesting bool? hasTerminal,
}) => withInteractiveConsole(
  (terminal, input) async {
    final picker = _FilePicker(terminal, completer ?? FilePathCompleter());
    picker.render();
    await for (final key in input) {
      if (isCancelKey(key)) return null;
      final selected = picker.handle(key);
      if (selected != null) return selected;
      picker.render();
    }
    return null;
  },
  console: console,
  keys: keys,
  hasTerminal: hasTerminal,
);

class _FilePicker {
  final Console terminal;
  final FilePathCompleter completer;
  String text = '';
  int cursor = 0;
  List<String> candidates = [];
  int selected = -1;
  int renderedLines = 0;
  String? error;
  final _utf8Bytes = <int>[];

  _FilePicker(this.terminal, this.completer) {
    _refresh();
  }

  String? handle(Key key) {
    final chars = text.characters.toList();
    switch (key.controlChar) {
      case ControlCharacter.tab:
      case ControlCharacter.arrowDown:
      case ControlCharacter.arrowUp:
        if (candidates.isNotEmpty) {
          final direction = key.controlChar == ControlCharacter.arrowUp
              ? -1
              : 1;
          selected = selected < 0
              ? (direction > 0 ? 0 : candidates.length - 1)
              : (selected + direction) % candidates.length;
          text = candidates[selected];
          cursor = text.characters.length;
          error = null;
        }
      case ControlCharacter.enter:
      case ControlCharacter.ctrlJ:
        if (text.isEmpty) return null;
        final path = completer.resolve(text);
        final type = FileSystemEntity.typeSync(path);
        if (type == FileSystemEntityType.file) return path;
        if (type == FileSystemEntityType.directory) {
          text = path.endsWith(p.separator) ? path : '$path${p.separator}';
          cursor = text.characters.length;
          _refresh();
        } else {
          error = t.register.secretFile.notFound;
        }
      case ControlCharacter.arrowLeft:
      case ControlCharacter.ctrlB:
        cursor = math.max(0, cursor - 1);
      case ControlCharacter.arrowRight:
      case ControlCharacter.ctrlF:
        cursor = math.min(chars.length, cursor + 1);
      case ControlCharacter.home:
      case ControlCharacter.ctrlA:
        cursor = 0;
      case ControlCharacter.end:
      case ControlCharacter.ctrlE:
        cursor = chars.length;
      case ControlCharacter.backspace:
      case ControlCharacter.ctrlH:
        if (cursor > 0) {
          chars.removeAt(--cursor);
          text = chars.join();
          _refresh();
        }
      case ControlCharacter.delete:
        if (cursor < chars.length) {
          chars.removeAt(cursor);
          text = chars.join();
          _refresh();
        }
      case ControlCharacter.ctrlU:
        text = '';
        cursor = 0;
        _refresh();
      case ControlCharacter.none:
        _utf8Bytes.addAll(key.char.codeUnits);
        String input;
        try {
          input = utf8.decode(_utf8Bytes);
        } on FormatException {
          if (_utf8Bytes.length >= 4) _utf8Bytes.clear();
          return null;
        }
        _utf8Bytes.clear();
        final before = '${chars.take(cursor).join()}$input';
        text = '$before${chars.skip(cursor).join()}';
        cursor = before.characters.length;
        _refresh();
      default:
        break;
    }
    return null;
  }

  void _refresh() {
    selected = -1;
    error = null;
    try {
      candidates = completer.complete(text);
    } on FileSystemException {
      candidates = [];
    }
  }

  void render() {
    final width = math.max(4, terminal.windowWidth - 1);
    final visible = math.max(1, math.min(6, terminal.windowHeight - 4));
    final start = selected < 0 ? 0 : (selected ~/ visible) * visible;
    final rows = [
      t.register.secretFile.filePrompt,
      t.register.secretFile.controls,
      if (error != null)
        error!
      else if (candidates.isEmpty)
        t.register.secretFile.noMatches
      else
        for (
          var i = start;
          i < math.min(start + visible, candidates.length);
          i++
        )
          '${i == selected ? '>' : ' '} ${candidates[i]}',
    ];
    terminal.write('\r');
    if (renderedLines > 0) terminal.write('\x1b[${renderedLines}A');
    terminal.write('\x1b[J');
    for (final row in rows) {
      terminal.write('${_clip(row, width)}\r\n');
    }
    renderedLines = rows.length;

    var before = _sanitize(text.characters.take(cursor).toString());
    while (before.displayWidth > width - 3) {
      before = before.characters.skip(1).toString();
    }
    final after = _clip(
      text.characters.skip(cursor).toString(),
      width - 2 - before.displayWidth,
    );
    terminal.write('> $before$after');
    if (after.displayWidth > 0) terminal.write('\x1b[${after.displayWidth}D');
  }

  String _clip(String text, int width) {
    final clean = _sanitize(text);
    final result = StringBuffer();
    var used = 0;
    for (final char in clean.characters) {
      if (used + char.displayWidth > width) break;
      result.write(char);
      used += char.displayWidth;
    }
    return result.toString();
  }

  String _sanitize(String text) =>
      text.replaceAll(RegExp(r'[\x00-\x1f\x7f-\x9f]'), '?');
}
