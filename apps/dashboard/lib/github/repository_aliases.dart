const _repositoryOwnerAliases = {
  'open-ci-io': 'openci-org',
};

String canonicalRepositoryFullName(String repository) {
  final parts = repository.split('/');
  if (parts.length != 2) return repository;
  final owner = _repositoryOwnerAliases[parts[0]] ?? parts[0];
  return '$owner/${parts[1]}';
}

List<String> repositoryFullNameAliases(String repository) {
  final canonical = canonicalRepositoryFullName(repository);
  final aliases = <String>{canonical};
  final parts = canonical.split('/');
  if (parts.length != 2) return aliases.toList(growable: false);

  for (final entry in _repositoryOwnerAliases.entries) {
    if (entry.value == parts[0]) {
      aliases.add('${entry.key}/${parts[1]}');
    }
  }
  return aliases.toList(growable: false);
}
