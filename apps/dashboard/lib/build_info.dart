abstract final class BuildInfo {
  static const updatedAtIso = String.fromEnvironment(
    'OPENCI_BUILD_UPDATED_AT',
  );
  static const sha = String.fromEnvironment('OPENCI_BUILD_SHA');

  static bool get hasBuildIdentity => sha.isNotEmpty || updatedAtIso.isNotEmpty;

  static DateTime? get updatedAtUtc {
    final parsed = DateTime.tryParse(updatedAtIso);
    return parsed?.toUtc();
  }

  static DateTime? get updatedAt {
    return updatedAtUtc?.toLocal();
  }
}
