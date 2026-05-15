const _jstOffset = Duration(hours: 9);

DateTime? ascTimestampToJst(String? rawTimestamp) {
  if (rawTimestamp == null) {
    return null;
  }

  final timestamp = rawTimestamp.trim();
  if (timestamp.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(timestamp);
  if (parsed == null) {
    return null;
  }

  return _asUtc(parsed, timestamp).add(_jstOffset);
}

String? formatAscTimestampJst(
  String? rawTimestamp, {
  bool includeYear = false,
}) {
  final jst = ascTimestampToJst(rawTimestamp);
  if (jst == null) {
    return null;
  }

  final date = includeYear
      ? '${jst.year}/${jst.month}/${jst.day}'
      : '${jst.month}/${jst.day}';
  return '$date ${_twoDigits(jst.hour)}:${_twoDigits(jst.minute)} JST';
}

DateTime _asUtc(DateTime parsed, String rawTimestamp) {
  if (_hasExplicitTimeZone(rawTimestamp)) {
    return parsed.toUtc();
  }

  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}

bool _hasExplicitTimeZone(String timestamp) {
  return RegExp(r'(?:z|[+-]\d{2}:?\d{2})$', caseSensitive: false).hasMatch(
    timestamp,
  );
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
