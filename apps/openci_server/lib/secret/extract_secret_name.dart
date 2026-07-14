Set<String> extractSecretNames(String content) {
  final secretNames = <String>{};
  final regex = RegExp(
    r'secrets(?:\.([a-zA-Z0-9_-]+)|\[\s*(?:"([^"]+)"|'
    "'"
    '([^'
    "'"
    ']+)'
    "'"
    ')s*])',
    caseSensitive: false,
  );

  for (final match in regex.allMatches(content)) {
    final name = match.group(1) ?? match.group(2) ?? match.group(3);
    if (name != null && name.isNotEmpty) {
      secretNames.add(name);
    }
  }
  return secretNames;
}
