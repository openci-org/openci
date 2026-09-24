Set<String> extractSecretNames(String content, {String? secretDefinitions}) {
  final getterNames = <String, String>{};
  if (secretDefinitions != null) {
    final getterPattern = RegExp(
      r'''static\s+String\s+get\s+([a-zA-Z0-9_$]+)\s*=>\s*Platform\s*\.\s*environment\s*\[\s*(?:"([^"]+)"|'([^']+)')\s*\]''',
    );
    for (final match in getterPattern.allMatches(secretDefinitions)) {
      getterNames[match.group(1)!] = (match.group(2) ?? match.group(3))!;
    }
  }

  final secretNames = <String>{};
  final regex = RegExp(
    r'''(?<![$/'"])\b(secrets)(?:\s*\.\s*([a-zA-Z0-9_$-]+)|\s*\[\s*(?:"([^"]+)"|'([^']+)')\s*\])''',
    caseSensitive: false,
  );

  for (final match in regex.allMatches(content)) {
    final name = match.group(2) ?? match.group(3) ?? match.group(4);
    if (name != null && name.isNotEmpty) {
      if (secretDefinitions != null &&
          match.group(1) == 'Secrets' &&
          match.group(2) != null) {
        final environmentName = getterNames[name];
        if (environmentName == null) {
          throw StateError('No environment variable found for Secrets.$name.');
        }
        secretNames.add(environmentName);
      } else {
        secretNames.add(name);
      }
    }
  }
  return secretNames;
}
