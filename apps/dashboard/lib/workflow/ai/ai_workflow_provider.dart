import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:dashboard/firebase/functions_provider.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChatRole { user, assistant }

class ChatSuggestion {
  const ChatSuggestion(this.label, this.value);
  final String label;
  final String value;
}

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.suggestions = const [],
  });

  final ChatRole role;
  final String content;
  final List<ChatSuggestion> suggestions;
}

class AiWorkflowState {
  const AiWorkflowState({
    this.messages = const [],
    this.isGenerating = false,
    this.generatedYaml,
    this.error,
    this.repoContext,
  });

  final List<ChatMessage> messages;
  final bool isGenerating;
  final String? generatedYaml;
  final String? error;
  final String? repoContext;

  AiWorkflowState copyWith({
    List<ChatMessage>? messages,
    bool? isGenerating,
    String? generatedYaml,
    String? error,
    String? repoContext,
  }) {
    return AiWorkflowState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      generatedYaml: generatedYaml ?? this.generatedYaml,
      error: error,
      repoContext: repoContext ?? this.repoContext,
    );
  }
}

final aiWorkflowProvider =
    NotifierProvider<AiWorkflowNotifier, AiWorkflowState>(
      AiWorkflowNotifier.new,
    );

class AiWorkflowNotifier extends Notifier<AiWorkflowState> {
  String _repository = '';
  String _branch = '';

  @override
  AiWorkflowState build() {
    return const AiWorkflowState();
  }

  Future<void> initialize({
    required String repository,
    required String branch,
  }) async {
    _repository = repository;
    _branch = branch;

    _addAssistantMessage(
      t.aiWorkflow.chat.greeting,
      suggestions: _initialSuggestions(),
    );

    await _fetchRepoContext();
  }

  Future<void> _fetchRepoContext() async {
    try {
      final team = ref.read(teamStateProvider).value;
      if (team == null) return;

      final functions = ref.read(functionsProvider);
      final result = await functions
          .httpsCallableFromUrl(dartFunctionUrl('list-directories'))
          .call({
            'teamId': team.id,
            'repository': _repository,
          });

      final data = result.data as Map<String, dynamic>;
      final directories = (data['directories'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

      final contextString =
          'Repository: $_repository\n'
          'Branch: $_branch\n'
          'Directory structure:\n${directories.join('\n')}';

      state = state.copyWith(repoContext: contextString);
    } catch (e) {
      debugPrint('Failed to fetch repo context: $e');
    }
  }

  Future<void> sendMessage(String displayText, {String? matchKey}) async {
    if (state.isGenerating) return;

    _addUserMessage(displayText);
    state = state.copyWith(isGenerating: true, error: null);

    try {
      final team = ref.read(teamStateProvider).value;
      if (team == null) throw StateError('Team not loaded');

      final functions = ref.read(functionsProvider);

      final messagesPayload = state.messages
          .map(
            (m) => <String, String>{
              'role': m.role == ChatRole.user ? 'user' : 'assistant',
              'content': m.content,
            },
          )
          .toList();

      final result = await functions
          .httpsCallableFromUrl(
            dartFunctionUrl('generate-ai-workflow-response'),
            options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
          )
          .call({
            'teamId': team.id,
            'messages': messagesPayload,
            if (state.repoContext != null) 'repoContext': state.repoContext,
          });

      final data = Map<String, dynamic>.from(result.data as Map);
      final message = data['message'] as String? ?? '';
      final yaml = data['yaml'] as String?;

      if (yaml != null && yaml.isNotEmpty) {
        state = state.copyWith(generatedYaml: yaml);
      }

      final suggestions = _buildSuggestionsForResponse(yaml != null);

      state = state.copyWith(isGenerating: false);
      _addAssistantMessage(message, suggestions: suggestions);
    } catch (e) {
      debugPrint('AI workflow error: $e');
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
      _addAssistantMessage(
        t.aiWorkflow.chat.errorMessage,
        suggestions: [
          ChatSuggestion(t.aiWorkflow.suggestion.startOver, 'start_over'),
        ],
      );
    }
  }

  void reset() {
    state = const AiWorkflowState();
    _addAssistantMessage(
      t.aiWorkflow.chat.greeting,
      suggestions: _initialSuggestions(),
    );
    _fetchRepoContext();
  }

  List<ChatSuggestion> _initialSuggestions() {
    final s = t.aiWorkflow.suggestion;
    return [
      ChatSuggestion(s.flutterCiCd, s.flutterCiCd),
      ChatSuggestion(s.iosBuildTest, s.iosBuildTest),
      ChatSuggestion(s.androidBuild, s.androidBuild),
      ChatSuggestion(s.testOnPr, s.testOnPr),
      ChatSuggestion(s.customWorkflow, s.customWorkflow),
    ];
  }

  List<ChatSuggestion> _buildSuggestionsForResponse(bool hasYaml) {
    final s = t.aiWorkflow.suggestion;
    if (hasYaml) {
      return [
        ChatSuggestion(s.looksGood, s.looksGood),
        ChatSuggestion(s.addSteps, s.addSteps),
        ChatSuggestion(s.changeTrigger, s.changeTrigger),
        ChatSuggestion(s.startOver, s.startOver),
      ];
    }
    return [];
  }

  void _addUserMessage(String content) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatRole.user, content: content),
      ],
    );
  }

  void _addAssistantMessage(
    String content, {
    List<ChatSuggestion> suggestions = const [],
  }) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          role: ChatRole.assistant,
          content: content,
          suggestions: suggestions,
        ),
      ],
    );
  }
}
