enum SiteLocale {
  en('English', 'en_US'),
  ja('日本語', 'ja_JP');

  const SiteLocale(this.label, this.ogLocale);

  final String label;
  final String ogLocale;

  static SiteLocale fromPath(String path) =>
      Uri.parse(path).path.split('/').where((s) => s.isNotEmpty).firstOrNull ==
          'ja'
      ? ja
      : en;

  String text(String japanese, String english) =>
      this == ja ? japanese : english;

  /// Maps an internal page to this language, retaining its query and fragment.
  String path(String path) {
    final uri = Uri.parse(path);
    if (uri.hasScheme || uri.hasAuthority) return path;
    return uri.replace(path: '/$name${logicalPath(uri.path)}').toString();
  }
}

/// A locale-independent page path, with a trailing slash.
String logicalPath(String path) {
  final segments = Uri.parse(
    path,
  ).path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isNotEmpty &&
      SiteLocale.values.any((locale) => locale.name == segments.first)) {
    segments.removeAt(0);
  }
  return segments.isEmpty ? '/' : '/${segments.join('/')}/';
}

/// Only advertise translations that actually have a generated page.
Map<SiteLocale, String> availableTranslations(
  String path,
  Iterable<String> pages,
) {
  final available = pages
      .map((path) => SiteLocale.fromPath(path).path(path))
      .toSet();
  return {
    for (final locale in SiteLocale.values)
      if (available.contains(locale.path(path))) locale: locale.path(path),
  };
}
