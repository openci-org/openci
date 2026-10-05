/// Time zones supported by workflow commands.
enum TimeZone {
  /// Coordinated Universal Time.
  utc('UTC'),

  /// Japan's time zone.
  asiaTokyo('Asia/Tokyo');

  const TimeZone(this.value);

  /// The time zone identifier passed to the `TZ` environment variable.
  final String value;
}
