import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/functions_provider.dart';
import 'package:flutter/foundation.dart';
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
  required String teamId,
}) async {
  try {
    final functions = ref.read(functionsProvider);
    final result = await functions.httpsCallable(searchGitHubActionsFunction).call({
      'teamId': teamId,
      'type': 'search',
      'query': query,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final items = data['actions'] as List<dynamic>;

    return items.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return GitHubAction(
        fullName: map['fullName'] as String,
        description: (map['description'] as String?) ?? '',
        stars: map['stars'] as int,
        owner: map['owner'] as String,
        avatarUrl: map['avatarUrl'] as String,
        htmlUrl: map['htmlUrl'] as String,
        defaultBranch: (map['defaultBranch'] as String?) ?? 'main',
        isOfficial: map['isOfficial'] as bool? ?? false,
      );
    }).toList();
  } catch (e, st) {
    debugPrint('searchGitHubActions error: $e');
    debugPrint('stackTrace: $st');
    rethrow;
  }
}

@riverpod
Future<List<ActionInput>> actionInputs(
  Ref ref, {
  required String actionRef,
}) async {
  try {
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
  } catch (e, st) {
    debugPrint('actionInputs error: $e');
    debugPrint('stackTrace: $st');
    rethrow;
  }
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
  } catch (e, st) {
    debugPrint('_parseInputs error: $e');
    debugPrint('stackTrace: $st');
    return [];
  }
}

@riverpod
Future<List<String>> actionTags(
  Ref ref, {
  required String fullName,
  required String teamId,
}) async {
  try {
    final functions = ref.read(functionsProvider);
    final result = await functions.httpsCallable(searchGitHubActionsFunction).call({
      'teamId': teamId,
      'type': 'tags',
      'fullName': fullName,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final tags = (data['tags'] as List<dynamic>).cast<String>();
    return tags;
  } catch (e, st) {
    debugPrint('actionTags error: $e');
    debugPrint('stackTrace: $st');
    rethrow;
  }
}

Future<String> fetchLatestTag({
  required String fullName,
  required String teamId,
  required FirebaseFunctions functions,
}) async {
  try {
    final result = await functions.httpsCallable(searchGitHubActionsFunction).call({
      'teamId': teamId,
      'type': 'tags',
      'fullName': fullName,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final tags = (data['tags'] as List<dynamic>).cast<String>();
    if (tags.isNotEmpty) return tags.first;
  } catch (e) {
    debugPrint('fetchLatestTag error: $e');
  }
  return 'v1';
}
