import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../models/ask.dart';
import '../../widgets/citation_list.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'ask_providers.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(askThreadProvider(widget.threadId));

    return Scaffold(
      appBar: AppBar(
        title: Text(state.value?.thread?.title ?? 'New question'),
        actions: [
          PopupMenuButton<String?>(
            tooltip: 'Answer language',
            icon: const Icon(Icons.translate),
            onSelected: (value) => setState(() => _languageOverride = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: null, child: Text('Default')),
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'ja', child: Text('日本語')),
            ],
          ),
        ],
      ),
      body: switch (state) {
        AsyncData(:final value) => Column(
            children: [
              Expanded(
                child: value.messages.isEmpty
                    ? const Center(child: Text('Ask a question about your saved links.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: value.messages.length,
                        itemBuilder: (context, index) =>
                            _MessageBubble(message: value.messages[index]),
                      ),
              ),
              if (value.isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LoadingView(message: 'Thinking through your saved links…'),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Ask a question…',
                            border: OutlineInputBorder(),
                          ),
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: value.isSending ? null : _send,
                        icon: const Icon(Icons.send),
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
    final theme = Theme.of(context);
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.content),
            if (!message.isUser && message.usedFallback) ...[
              const SizedBox(height: 6),
              Text(
                'AI unavailable — showing a plain keyword match instead.',
                style: theme.textTheme.labelSmall,
              ),
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
