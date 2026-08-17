import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'ask_providers.dart';

class AskThreadListScreen extends ConsumerWidget {
  const AskThreadListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(askThreadListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ask')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ask/thread/$newAskThreadId'),
        icon: const Icon(Icons.add),
        label: const Text('New question'),
      ),
      body: switch (state) {
        AsyncData(:final value) => value.isEmpty
            ? EmptyState(
                icon: Icons.auto_awesome_outlined,
                title: 'Ask Hazy anything',
                subtitle: 'Answers cite your own saved pages.',
                action: FilledButton.icon(
                  onPressed: () => context.push('/ask/thread/$newAskThreadId'),
                  icon: const Icon(Icons.add),
                  label: const Text('New question'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(askThreadListProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final thread = value[index];
                    return Dismissible(
                      key: ValueKey(thread.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_outline),
                      ),
                      onDismissed: (_) =>
                          ref.read(askThreadListProvider.notifier).delete(thread.id),
                      child: ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(thread.title),
                        subtitle: Text(DateFormat.yMMMd().add_jm().format(thread.updatedAt)),
                        onTap: () => context.push('/ask/thread/${thread.id}'),
                      ),
                    );
                  },
                ),
              ),
        AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.read(askThreadListProvider.notifier).refresh(),
          ),
        _ => const LoadingView(),
      },
    );
  }
}
