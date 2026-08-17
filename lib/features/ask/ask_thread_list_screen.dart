import 'package:flutter/material.dart'
    show
        Scaffold,
        AppBar,
        FloatingActionButton,
        RefreshIndicator,
        ListView,
        Dismissible,
        DismissDirection,
        ListTile;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/localization/app_strings.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'ask_providers.dart';

class AskThreadListScreen extends ConsumerWidget {
  const AskThreadListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(askThreadListProvider);
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.askTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ask/thread/$newAskThreadId'),
        icon: const Icon(LucideIcons.plus),
        label: Text(s.newQuestion),
      ),
      body: switch (state) {
        AsyncData(:final value) => value.isEmpty
            ? EmptyState(
                icon: LucideIcons.sparkles,
                title: s.askAnything,
                subtitle: s.askSubtitle,
                action: ShadButton(
                  onPressed: () => context.push('/ask/thread/$newAskThreadId'),
                  leading: const Icon(LucideIcons.plus),
                  child: Text(s.newQuestion),
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
                        color: theme.colorScheme.destructive,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          LucideIcons.trash2,
                          color: theme.colorScheme.destructiveForeground,
                        ),
                      ),
                      onDismissed: (_) =>
                          ref.read(askThreadListProvider.notifier).delete(thread.id),
                      child: ListTile(
                        leading: const Icon(LucideIcons.messageCircle),
                        title: Text(thread.title),
                        subtitle: Text(
                          DateFormat.yMMMd(s.localeCode).add_jm().format(thread.updatedAt),
                        ),
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
