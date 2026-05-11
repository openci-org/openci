abstract final class BuildInfo {
  static const updatedAtIso = String.fromEnvironment(
    'OPENCI_BUILD_UPDATED_AT',
  );
  static const sha = String.fromEnvironment('OPENCI_BUILD_SHA');

  static DateTime? get updatedAt {
    final parsed = DateTime.tryParse(updatedAtIso);
    return parsed?.toLocal();
  }
}
