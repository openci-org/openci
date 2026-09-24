String escapeXml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String? extractUdid(String body) {
  final regExp = RegExp(
    r'<key>UDID</key>\s*<string>([^<]+)</string>',
    caseSensitive: false,
  );
  return regExp.firstMatch(body)?.group(1)?.trim();
}

String extractProduct(String body) {
  final regExp = RegExp(
    r'<key>PRODUCT</key>\s*<string>([^<]+)</string>',
    caseSensitive: false,
  );
  return regExp.firstMatch(body)?.group(1)?.trim() ?? 'Unknown';
}

String extractOsVersion(String body) {
  final regExp = RegExp(
    r'<key>VERSION</key>\s*<string>([^<]+)</string>',
    caseSensitive: false,
  );
  return regExp.firstMatch(body)?.group(1)?.trim() ?? 'Unknown';
}
