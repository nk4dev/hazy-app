import 'package:flutter/material.dart' show Scaffold, AppBar, ListView, MediaQuery;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/localization/app_strings.dart';
import '../../models/ask.dart';
import '../../widgets/citation_list.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'ask_providers.dart';

// Language names are conventionally shown in their own language regardless
// of the current UI language; only "Default" is localized.
const _languageNames = {'en': 'English', 'ja': '日本語'};

class AskThreadScreen extends ConsumerStatefulWidget {
  const AskThreadScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<AskThreadScreen> createState() => _AskThreadScreenState();
}

class _AskThreadScreenState extends ConsumerState<AskThreadScreen> {
  final _controller = TextEditingController();
  String? _languageOverride;

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    _controller.clear();
    try {
      final realId = await ref
          .read(askThreadProvider(widget.threadId).notifier)
          .ask(question, answerLanguageOverride: _languageOverride);
      ref.invalidate(askThreadListProvider);
      if (realId != widget.threadId && mounted) {
        context.replace('/ask/thread/$realId');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(askThreadProvider(widget.threadId));
    final s = AppStrings.of(context);
    final languageOptions = {null: s.languageDefault, ..._languageNames};

    return Scaffold(
      appBar: AppBar(
        title: Text(state.value?.thread?.title ?? s.newQuestionTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ShadSelect<String?>(
              key: ValueKey(_languageOverride),
              minWidth: 130,
              initialValue: _languageOverride,
              options: languageOptions.entries
                  .map((e) => ShadOption(value: e.key, child: Text(e.value)))
                  .toList(),
              selectedOptionBuilder: (context, value) =>
                  Text(languageOptions[value] ?? s.languageDefault),
              onChanged: (value) => setState(() => _languageOverride = value),
            ),
          ),
        ],
      ),
      body: switch (state) {
        AsyncData(:final value) => Column(
            children: [
              Expanded(
                child: value.messages.isEmpty
                    ? Center(child: Text(s.askAQuestionAboutSavedLinks))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: value.messages.length,
                        itemBuilder: (context, index) =>
                            _MessageBubble(message: value.messages[index]),
                      ),
              ),
              if (value.isSending)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: LoadingView(message: s.thinking),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: ShadTextarea(
                          controller: _controller,
                          placeholder: Text(s.askQuestionPlaceholder),
                          minHeight: 40,
                          maxHeight: 120,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShadIconButton(
                        onPressed: value.isSending ? null : _send,
                        icon: const Icon(LucideIcons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(askThreadProvider(widget.threadId)),
          ),
        _ => const LoadingView(),
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AskMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.muted,
          borderRadius: theme.radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.content, style: theme.textTheme.p),
            if (!message.isUser && message.usedFallback) ...[
              const SizedBox(height: 6),
              Text(s.aiUnavailableFallback, style: theme.textTheme.small),
            ],
            if (!message.isUser && message.citations.isNotEmpty) ...[
              const SizedBox(height: 8),
              CitationList(citations: message.citations),
            ],
          ],
        ),
      ),
    );
  }
}
