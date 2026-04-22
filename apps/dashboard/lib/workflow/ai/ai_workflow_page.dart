import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/theme/app_colors.dart';

import 'package:dashboard/workflow/ai/ai_workflow_provider.dart';

import 'package:dashboard/workflow/list/create_workflow_page.dart';

import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:re_editor/re_editor.dart';

import 'package:re_highlight/languages/yaml.dart';

import 'package:re_highlight/styles/monokai.dart';

import 'package:swipeable_page_route/swipeable_page_route.dart';


class AiWorkflowPage extends HookConsumerWidget {
  const AiWorkflowPage({
    super.key,
    required this.repository,
    required this.branch,
    required this.teamId,
  });

  final String repository;
  final String branch;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiWorkflowProvider);
    final scrollController = useScrollController();
    final textController = useTextEditingController();
    final focusNode = useFocusNode();
    final aiT = t.aiWorkflow;

    useEffect(() {
      Future.microtask(() {
        ref
            .read(aiWorkflowProvider.notifier)
            .initialize(
              repository: repository,
              branch: branch,
            );
      });
      return null;
    }, const []);

    ref.listen(aiWorkflowProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(aiT.title),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount:
                      aiState.messages.length +
                      (aiState.isGenerating ? 1 : 0) +
                      (aiState.generatedYaml != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < aiState.messages.length) {
                      final message = aiState.messages[index];
                      final isLastMessage =
                          index == aiState.messages.length - 1;
                      return _ChatBubble(
                        message: message,
                        showSuggestions: isLastMessage && !aiState.isGenerating,
                        onSuggestionTap: (suggestion) {
                          if (suggestion.value ==
                              t.aiWorkflow.suggestion.startOver) {
                            ref.read(aiWorkflowProvider.notifier).reset();
                          } else {
                            ref
                                .read(aiWorkflowProvider.notifier)
                                .sendMessage(
                                  suggestion.label,
                                  matchKey: suggestion.value,
                                );
                          }
                        },
                      );
                    }

                    final yamlIndex = aiState.messages.length;
                    if (aiState.generatedYaml != null && index == yamlIndex) {
                      return _YamlPreview(
                        yaml: aiState.generatedYaml!,
                        onUse: () {
                          Navigator.of(context).pushReplacement(
                            SwipeablePageRoute(
                              builder: (_) => CreateWorkflowPage(
                                repository: repository,
                                branch: branch,
                                teamId: teamId,
                                initialYaml: aiState.generatedYaml,
                              ),
                            ),
                          );
                        },
                      );
                    }

                    return const _TypingIndicator();
                  },
                ),
              ),
              _InputBar(
                controller: textController,
                focusNode: focusNode,
                isGenerating: aiState.isGenerating,
                onSend: () {
                  final text = textController.text.trim();
                  if (text.isEmpty) return;
                  textController.clear();
                  ref.read(aiWorkflowProvider.notifier).sendMessage(text);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.showSuggestions,
    required this.onSuggestionTap,
  });

  final ChatMessage message;
  final bool showSuggestions;
  final ValueChanged<ChatSuggestion> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          if (showSuggestions && message.suggestions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 8,
                left: isUser ? 0 : 40,
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.suggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(
                      suggestion.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    backgroundColor: colorScheme.surfaceContainerLow,
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    onPressed: () => onSuggestionTap(suggestion),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: SizedBox(
              width: 40,
              child: _DotsAnimation(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsAnimation extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = ((controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (t < 0.5 ? t * 2 : 2 - t * 2).clamp(0.3, 1.0);
            return Opacity(
              opacity: opacity,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _YamlPreview extends StatelessWidget {
  const _YamlPreview({
    required this.yaml,
    required this.onUse,
  });

  final String yaml;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final aiT = t.aiWorkflow;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Icon(Icons.code, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        aiT.generatedWorkflow,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 280,
                  child: CodeEditor(
                    padding: const EdgeInsets.all(12),
                    controller: CodeLineEditingController.fromText(yaml),
                    readOnly: true,
                    wordWrap: true,
                    borderRadius: BorderRadius.zero,
                    style: CodeEditorStyle(
                      fontSize: 13,
                      backgroundColor: AppColors.of(context).surfaceSecondary,
                      textColor: AppColors.of(context).textPrimary,
                      codeTheme: CodeHighlightTheme(
                        languages: {
                          'yaml': CodeHighlightThemeMode(mode: langYaml),
                        },
                        theme: monokaiTheme,
                      ),
                    ),
                    indicatorBuilder:
                        (
                          context,
                          editingController,
                          chunkController,
                          notifier,
                        ) {
                          return Row(
                            children: [
                              DefaultCodeLineNumber(
                                controller: editingController,
                                notifier: notifier,
                              ),
                            ],
                          );
                        },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onUse,
            icon: const Icon(Icons.check, size: 18),
            label: Text(aiT.useThisWorkflow),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isGenerating,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isGenerating;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final aiT = t.aiWorkflow;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !isGenerating,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: aiT.inputHint,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isGenerating ? null : onSend,
              icon: isGenerating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
