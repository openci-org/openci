/// Flutter SDK releases used by OpenCI workflows.
enum FlutterVersion {
  /// Used by the repository's Dart format check.
  v3_44_8('3.44.8'),

  /// Included in the `base-macos` image.
  v3_47_8('3.47.8');

  const FlutterVersion(this.value);

  /// The Flutter release number, such as `3.47.8`.
  final String value;
}
