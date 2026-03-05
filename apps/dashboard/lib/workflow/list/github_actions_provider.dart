import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yaml/yaml.dart';

part 'github_actions_provider.g.dart';

class GitHubAction {
  GitHubAction({
    required this.fullName,
    required this.description,
    required this.stars,
    required this.owner,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.defaultBranch,
    this.isOfficial = false,
  });

  final String fullName;
  final String description;
  final int stars;
  final String owner;
  final String avatarUrl;
  final String htmlUrl;
  final String defaultBranch;
  final bool isOfficial;
}

class ActionInput {
  ActionInput({
    required this.key,
    this.description = '',
    this.defaultValue,
    this.required_ = false,
  });

  final String key;
  final String description;
  final String? defaultValue;
  final bool required_;
}

@riverpod
Future<List<GitHubAction>> searchGitHubActions(
  Ref ref, {
  required String query,
}) async {
  final searchQuery = query.trim().isEmpty
      ? 'github+action'
      : Uri.encodeComponent(query.trim());

  final uri = Uri.parse(
    'https://api.github.com/search/repositories'
    '?q=$searchQuery'
    '&sort=stars&order=desc&per_page=100',
  );

  final response = await http.get(
    uri,
    headers: {'Accept': 'application/vnd.github+json'},
  );

  if (response.statusCode != 200) {
    throw Exception('GitHub API error: ${response.statusCode}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final items = data['items'] as List<dynamic>;

  return items.map((item) {
    final map = item as Map<String, dynamic>;
    final ownerMap = map['owner'] as Map<String, dynamic>;
    final ownerLogin = ownerMap['login'] as String;
    return GitHubAction(
      fullName: map['full_name'] as String,
      description: (map['description'] as String?) ?? '',
      stars: map['stargazers_count'] as int,
      owner: ownerLogin,
      avatarUrl: ownerMap['avatar_url'] as String,
      htmlUrl: map['html_url'] as String,
      defaultBranch: (map['default_branch'] as String?) ?? 'main',
      isOfficial: ownerLogin == 'actions',
    );
  }).toList();
}

@riverpod
Future<List<ActionInput>> actionInputs(
  Ref ref, {
  required String actionRef,
}) async {
  final parts = actionRef.split('@');
  final fullName = parts.first;

  for (final fileName in ['action.yml', 'action.yaml']) {
    final url = 'https://raw.githubusercontent.com/$fullName/HEAD/$fileName';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return _parseInputs(response.body);
    }
  }

  return [];
}

List<ActionInput> _parseInputs(String yamlContent) {
  try {
    final doc = loadYaml(yamlContent);
    if (doc is! YamlMap) return [];

    final inputs = doc['inputs'];
    if (inputs is! YamlMap) return [];

    return inputs.keys.map((key) {
      final input = inputs[key];
      final isRequired =
          input is YamlMap && input['required']?.toString() == 'true';
      final desc = input is YamlMap
          ? (input['description']?.toString() ?? '')
          : '';
      final defaultVal = input is YamlMap ? input['default']?.toString() : null;
      return ActionInput(
        key: key.toString(),
        description: desc,
        defaultValue: defaultVal,
        required_: isRequired,
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

@riverpod
Future<List<String>> actionTags(
  Ref ref, {
  required String fullName,
}) async {
  final url = 'https://api.github.com/repos/$fullName/tags?per_page=100';
  final response = await http.get(
    Uri.parse(url),
    headers: {'Accept': 'application/vnd.github+json'},
  );

  if (response.statusCode != 200) return [];

  final tags = jsonDecode(response.body) as List<dynamic>;
  final majorTags = <String>[];
  final allTags = <String>[];

  for (final tag in tags) {
    final name = (tag as Map<String, dynamic>)['name'] as String;
    allTags.add(name);
    if (RegExp(r'^v\d+$').hasMatch(name)) {
      majorTags.add(name);
    }
  }

  if (majorTags.isNotEmpty) return majorTags;
  return allTags;
}

Future<String> fetchLatestTag(String fullName) async {
  final url = 'https://api.github.com/repos/$fullName/tags?per_page=20';
  final response = await http.get(
    Uri.parse(url),
    headers: {'Accept': 'application/vnd.github+json'},
  );

  if (response.statusCode == 200) {
    final tags = jsonDecode(response.body) as List<dynamic>;
    for (final tag in tags) {
      final name = (tag as Map<String, dynamic>)['name'] as String;
      if (RegExp(r'^v\d+$').hasMatch(name)) {
        return name;
      }
    }
    if (tags.isNotEmpty) {
      return (tags.first as Map<String, dynamic>)['name'] as String;
    }
  }

  return 'v1';
}
