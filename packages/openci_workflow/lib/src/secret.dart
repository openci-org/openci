import 'dart:io';

/// A reference to a secret stored in an environment variable.
final class Secret {
  /// Creates a reference without reading the environment.
  const Secret(this.key);

  /// The original environment variable name, including its casing.
  final String key;

  /// The environment variable's value, read when this getter is accessed.
  ///
  /// Throws a [StateError] if [key] is absent from the environment.
  String get value =>
      Platform.environment[key] ??
      (throw StateError("Secret '$key' is not set in environment."));
}
