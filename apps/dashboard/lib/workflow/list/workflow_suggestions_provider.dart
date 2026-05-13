import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/callable_function_names.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkflowSuggestionRequest {
  const WorkflowSuggestionRequest({
    required this.teamId,
    required this.repository,
    required this.branch,
  });

  final String teamId;
  final String repository;
  final String branch;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkflowSuggestionRequest &&
            other.teamId == teamId &&
            other.repository == repository &&
            other.branch == branch;
  }

  @override
  int get hashCode => Object.hash(teamId, repository, branch);
}

class WorkflowSuggestionResult {
  const WorkflowSuggestionResult({
    required this.detectedProjectType,
    required this.analysisSummary,
    required this.suggestions,
  });

  final String detectedProjectType;
  final String analysisSummary;
  final List<WorkflowSuggestion> suggestions;
}

class WorkflowSuggestion {
  const WorkflowSuggestion({
    required this.title,
    required this.description,
    required this.fileName,
    required this.steps,
    required this.requiredSecrets,
    required this.yaml,
  });

  final String title;
  final String description;
  final String fileName;
  final List<String> steps;
  final List<String> requiredSecrets;
  final String yaml;
}

final workflowSuggestionsProvider = FutureProvider.autoDispose
    .family<WorkflowSuggestionResult, WorkflowSuggestionRequest>((
      ref,
      request,
    ) async {
      final result = await firebaseFunctions
          .httpsCallable(
            suggestWorkflowTemplatesFunction,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
          )
          .call({
            'teamId': request.teamId,
            'repository': request.repository,
            'branch': request.branch,
          });

      final data = Map<String, dynamic>.from(result.data as Map);
      final suggestions = (data['suggestions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((entry) {
            final map = Map<String, dynamic>.from(entry);
            return WorkflowSuggestion(
              title: map['title'] as String? ?? '',
              description: map['description'] as String? ?? '',
              fileName: map['fileName'] as String? ?? 'workflow.yaml',
              steps: (map['steps'] as List<dynamic>? ?? [])
                  .whereType<String>()
                  .toList(),
              requiredSecrets: (map['requiredSecrets'] as List<dynamic>? ?? [])
                  .whereType<String>()
                  .toList(),
              yaml: map['yaml'] as String? ?? '',
            );
          })
          .where((suggestion) {
            return suggestion.title.isNotEmpty && suggestion.yaml.isNotEmpty;
          })
          .toList();

      return WorkflowSuggestionResult(
        detectedProjectType: data['detectedProjectType'] as String? ?? '',
        analysisSummary: data['analysisSummary'] as String? ?? '',
        suggestions: suggestions,
      );
    });
