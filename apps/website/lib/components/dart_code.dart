import 'dart:convert';

String highlightedDart(String line) {
  final pattern = RegExp(r"(//.*)|('[^']*')|\b(await|for|final|in)\b");
  final parts = StringBuffer();
  var cursor = 0;
  for (final match in pattern.allMatches(line)) {
    if (match.start > cursor) {
      parts.write(htmlEscape.convert(line.substring(cursor, match.start)));
    }
    final kind = match.group(1) != null
        ? 'comment'
        : match.group(2) != null
        ? 'string'
        : 'keyword';
    parts.write(
      '<span class="syntax-$kind">${htmlEscape.convert(match.group(0)!)}</span>',
    );
    cursor = match.end;
  }
  if (cursor < line.length) {
    parts.write(htmlEscape.convert(line.substring(cursor)));
  }
  return parts.toString();
}
